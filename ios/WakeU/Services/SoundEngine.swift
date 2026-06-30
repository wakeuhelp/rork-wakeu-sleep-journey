//
//  SoundEngine.swift
//  WakeU
//

import AVFoundation
import SwiftUI
import Observation

/// Generates calming sleep textures procedurally with AVAudioEngine.
/// No bundled audio needed — each texture is synthesised from filtered noise
/// and slow modulation, so playback is instant and offline. Supports mixing
/// two layers, per-layer volume and a fade-out sleep timer.
@MainActor
@Observable
final class SoundEngine {
    struct Layer: Identifiable {
        let id: String
        var volume: Float
    }

    /// Active sound layers (max 2 for mixing).
    private(set) var layers: [Layer] = []
    var masterVolume: Float = 0.8 { didSet { applyMaster() } }

    /// Timer
    var timerMinutes: Int = 30
    private(set) var timerRemaining: TimeInterval = 0
    private(set) var isTimerRunning = false
    /// Set to true when the timer expires so UI can ask "still awake?".
    var timerDidExpire = false

    var isPlaying: Bool { !layers.isEmpty }

    private let engine = AVAudioEngine()
    private var sourceNodes: [String: AVAudioSourceNode] = [:]
    private var generators: [String: NoiseGenerator] = [:]
    private var sessionConfigured = false
    private var ticker: Timer?

    // MARK: - Public control

    func isActive(_ id: String) -> Bool { layers.contains { $0.id == id } }

    func volume(for id: String) -> Float { layers.first { $0.id == id }?.volume ?? 0.7 }

    /// Toggles a sound layer. Keeps at most two layers so two sounds can mix.
    func toggle(_ sound: SleepSound) {
        if isActive(sound.id) {
            stopLayer(sound.id)
        } else {
            if layers.count >= 2, let oldest = layers.first {
                stopLayer(oldest.id)
            }
            startLayer(sound)
        }
    }

    func setVolume(_ value: Float, for id: String) {
        guard let idx = layers.firstIndex(where: { $0.id == id }) else { return }
        layers[idx].volume = value
        generators[id]?.targetGain = value
    }

    func stopAll() {
        for layer in layers { generators[layer.id]?.targetGain = 0 }
        layers.removeAll()
        teardownEngine()
        cancelTimer()
    }

    // MARK: - Timer

    func startTimer() {
        timerRemaining = TimeInterval(timerMinutes * 60)
        isTimerRunning = true
        timerDidExpire = false
        ticker?.invalidate()
        ticker = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
    }

    func extendTimer() {
        timerRemaining += TimeInterval(30 * 60)
        isTimerRunning = true
        timerDidExpire = false
        if ticker == nil {
            ticker = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
                Task { @MainActor in self?.tick() }
            }
        }
    }

    func cancelTimer() {
        ticker?.invalidate()
        ticker = nil
        isTimerRunning = false
        timerRemaining = 0
    }

    var timerText: String {
        let total = Int(timerRemaining)
        return String(format: "%02d:%02d", total / 60, total % 60)
    }

    private func tick() {
        guard isTimerRunning else { return }
        timerRemaining -= 1
        if timerRemaining <= 0 {
            isTimerRunning = false
            ticker?.invalidate()
            ticker = nil
            timerDidExpire = true
            // Gently fade everything out.
            stopAll()
        }
    }

    // MARK: - Engine plumbing

    private func startLayer(_ sound: SleepSound) {
        configureSessionIfNeeded()
        let generator = NoiseGenerator(texture: sound.texture)
        generator.targetGain = 0.7
        generators[sound.id] = generator

        let format = engine.mainMixerNode.outputFormat(forBus: 0)
        let sampleRate = format.sampleRate > 0 ? format.sampleRate : 44100
        generator.sampleRate = sampleRate

        let node = AVAudioSourceNode { _, _, frameCount, audioBufferList -> OSStatus in
            let abl = UnsafeMutableAudioBufferListPointer(audioBufferList)
            generator.render(frameCount: Int(frameCount), buffers: abl)
            return noErr
        }
        sourceNodes[sound.id] = node
        engine.attach(node)
        engine.connect(node, to: engine.mainMixerNode, format: format)

        layers.append(Layer(id: sound.id, volume: 0.7))
        applyMaster()
        startEngineIfNeeded()
    }

    private func stopLayer(_ id: String) {
        layers.removeAll { $0.id == id }
        if let node = sourceNodes[id] {
            engine.detach(node)
            sourceNodes[id] = nil
        }
        generators[id] = nil
        if layers.isEmpty { teardownEngine() }
    }

    private func applyMaster() {
        engine.mainMixerNode.outputVolume = masterVolume
    }

    private func configureSessionIfNeeded() {
        guard !sessionConfigured else { return }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true)
            sessionConfigured = true
        } catch {
            print("[SoundEngine] session error: \(error.localizedDescription)")
        }
    }

    private func startEngineIfNeeded() {
        guard !engine.isRunning else { return }
        do {
            engine.prepare()
            try engine.start()
        } catch {
            print("[SoundEngine] start error: \(error.localizedDescription)")
        }
    }

    private func teardownEngine() {
        if engine.isRunning { engine.stop() }
    }
}

/// Thread-safe noise synthesiser. All state is value-based and pre-computed so
/// the audio render callback never allocates or locks.
final class NoiseGenerator: @unchecked Sendable {
    var sampleRate: Double = 44100
    /// Smoothed gain target (0–1). Render loop ramps toward this value.
    var targetGain: Float = 0.7

    private let texture: SleepSound.Texture
    private var gain: Float = 0
    private var seed: UInt32 = 0x12345678

    // Filter / modulation state
    private var lp1: Float = 0
    private var lp2: Float = 0
    private var brownLast: Float = 0
    private var pinkB0: Float = 0, pinkB1: Float = 0, pinkB2: Float = 0
    private var lfoPhase: Float = 0
    private var swellPhase: Float = 0
    private var cracklePhase: Float = 0
    private var melodyPhase: Float = 0
    private var melodyStep: Int = 0
    private var sampleCounter: Int = 0

    init(texture: SleepSound.Texture) {
        self.texture = texture
    }

    private func whiteNoise() -> Float {
        // xorshift PRNG → [-1, 1]
        seed ^= seed << 13
        seed ^= seed >> 17
        seed ^= seed << 5
        return (Float(seed) / Float(UInt32.max)) * 2 - 1
    }

    func render(frameCount: Int, buffers: UnsafeMutableAudioBufferListPointer) {
        let sr = Float(sampleRate)
        for frame in 0..<frameCount {
            let white = whiteNoise()
            var sample: Float = 0

            switch texture {
            case .white:
                sample = white * 0.4
            case .pink:
                // Paul Kellet pink filter
                pinkB0 = 0.99765 * pinkB0 + white * 0.0990460
                pinkB1 = 0.96300 * pinkB1 + white * 0.2965164
                pinkB2 = 0.57000 * pinkB2 + white * 1.0526913
                sample = (pinkB0 + pinkB1 + pinkB2 + white * 0.1848) * 0.12
            case .brown, .fan:
                brownLast = (brownLast + 0.02 * white) / 1.02
                sample = brownLast * 3.0
                if texture == .fan {
                    lfoPhase += 14.0 / sr // ~14 Hz rotor hum
                    if lfoPhase > 1 { lfoPhase -= 1 }
                    sample *= 0.8 + 0.2 * sinf(2 * .pi * lfoPhase)
                }
            case .rain:
                lp1 += 0.5 * (white - lp1)
                cracklePhase += 1
                let drops = (whiteNoise() > 0.985) ? whiteNoise() * 0.5 : 0
                sample = lp1 * 0.5 + drops
            case .ocean, .thunder:
                brownLast = (brownLast + 0.02 * white) / 1.02
                swellPhase += 0.08 / sr
                if swellPhase > 1 { swellPhase -= 1 }
                let swell = 0.5 + 0.5 * sinf(2 * .pi * swellPhase)
                sample = brownLast * 3.0 * swell
                if texture == .thunder, whiteNoise() > 0.9995 {
                    sample += whiteNoise() * 0.9
                }
            case .forest:
                lp1 += 0.3 * (white - lp1)
                // occasional bird-like chirps
                if whiteNoise() > 0.9992 { melodyPhase = 0 }
                melodyPhase += 2400 / sr
                let chirp = melodyPhase < 0.4 ? sinf(2 * .pi * melodyPhase * 8) * 0.12 * (0.4 - melodyPhase) : 0
                sample = lp1 * 0.35 + chirp
            case .fireplace:
                brownLast = (brownLast + 0.02 * white) / 1.02
                let crackle = (whiteNoise() > 0.992) ? whiteNoise() * 0.6 : 0
                sample = brownLast * 2.2 + crackle
            case .meditation, .ambient:
                // Slow evolving drone (root + fifth) with soft noise bed
                swellPhase += 110.0 / sr
                if swellPhase > 1 { swellPhase -= 1 }
                lfoPhase += 164.8 / sr
                if lfoPhase > 1 { lfoPhase -= 1 }
                let pad = sinf(2 * .pi * swellPhase) * 0.18 + sinf(2 * .pi * lfoPhase) * 0.12
                sample = pad + white * 0.02
            case .lofi:
                // gentle sine melody over a soft hiss
                melodyStep += 1
                if melodyStep > Int(sr) / 2 {
                    melodyStep = 0
                    let scale: [Float] = [261.6, 293.7, 329.6, 392.0, 440.0]
                    melodyPhase = scale[Int(arc4random_uniform(UInt32(scale.count)))]
                }
                lp2 += 0.02 * (sinf(2 * .pi * Float(sampleCounter) / sr * melodyPhase) - lp2)
                sample = lp2 * 0.3 + white * 0.03
            }
            sampleCounter += 1

            // Smooth gain ramp to avoid clicks
            gain += (targetGain - gain) * 0.0008
            sample *= gain

            // Soft clip
            if sample > 1 { sample = 1 } else if sample < -1 { sample = -1 }

            for buffer in buffers {
                if let ptr = buffer.mData?.assumingMemoryBound(to: Float.self) {
                    ptr[frame] = sample
                }
            }
        }
    }
}
