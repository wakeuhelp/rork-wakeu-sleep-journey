//
//  ToneGenerator.swift
//  WakeU
//

import AVFoundation
import SwiftUI
import Observation

/// Plays a single pure sine tone at a given frequency — used by the hearing
/// frequency test and high-frequency alert preview.
@MainActor
@Observable
final class ToneGenerator {
    private(set) var isPlaying = false
    var frequency: Double = 1000 { didSet { freqAtomic = Float(frequency) } }
    var amplitude: Float = 0.3

    private let engine = AVAudioEngine()
    private var sourceNode: AVAudioSourceNode?
    private var phase: Float = 0
    private var freqAtomic: Float = 1000
    private var configured = false

    func play() {
        guard !isPlaying else { return }
        configureSession()
        let format = engine.mainMixerNode.outputFormat(forBus: 0)
        let sr = Float(format.sampleRate > 0 ? format.sampleRate : 44100)
        freqAtomic = Float(frequency)

        let node = AVAudioSourceNode { [weak self] _, _, frameCount, abl -> OSStatus in
            guard let self else { return noErr }
            let buffers = UnsafeMutableAudioBufferListPointer(abl)
            let increment = 2 * Float.pi * self.freqAtomic / sr
            let amp = self.amplitude
            for frame in 0..<Int(frameCount) {
                let value = sinf(self.phase) * amp
                self.phase += increment
                if self.phase > 2 * .pi { self.phase -= 2 * .pi }
                for buffer in buffers {
                    if let ptr = buffer.mData?.assumingMemoryBound(to: Float.self) {
                        ptr[frame] = value
                    }
                }
            }
            return noErr
        }
        sourceNode = node
        engine.attach(node)
        engine.connect(node, to: engine.mainMixerNode, format: format)
        do {
            engine.prepare()
            try engine.start()
            isPlaying = true
        } catch {
            print("[ToneGenerator] start error: \(error.localizedDescription)")
        }
    }

    func stop() {
        guard isPlaying else { return }
        if let node = sourceNode {
            engine.detach(node)
            sourceNode = nil
        }
        engine.stop()
        isPlaying = false
    }

    private func configureSession() {
        guard !configured else { return }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
            configured = true
        } catch {
            print("[ToneGenerator] session error: \(error.localizedDescription)")
        }
    }
}
