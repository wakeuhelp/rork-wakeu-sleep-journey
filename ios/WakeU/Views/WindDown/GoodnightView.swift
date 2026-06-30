//
//  GoodnightView.swift
//  WakeU
//

import SwiftUI

/// The full-screen "Goodnight" experience. Runs through the wind-down steps,
/// then fades into a dark, minimalist sleep screen with the active sound,
/// timer, tracking status and flashlight.
struct GoodnightView: View {
    @Environment(AppState.self) private var app
    @Environment(SoundEngine.self) private var sound
    @Environment(\.dismiss) private var dismiss

    @State private var phase: Phase = .preparing
    @State private var completedSteps: Set<Int> = []
    @State private var torchOn = false
    @State private var showStillAwake = false

    private let nightPalette = WakePalette.palette(for: .night)

    enum Phase { case preparing, asleep }

    private let steps: [(String, String)] = [
        ("moon.fill", "Enabling Sleep Focus"),
        ("sun.min.fill", "Dimming the screen"),
        ("waveform", "Starting your sleep sound"),
        ("timer", "Setting a 30-minute timer"),
        ("waveform.path.ecg", "Preparing sleep tracking"),
        ("alarm.fill", "Arming tomorrow's alarm"),
    ]

    var body: some View {
        ZStack {
            AnimatedBackground(palette: nightPalette, dimmed: phase == .asleep ? 0.5 : 0)

            switch phase {
            case .preparing: preparingView
            case .asleep: sleepView
            }
        }
        .environment(\.palette, nightPalette)
        .onChange(of: sound.timerDidExpire) { _, expired in
            if expired { showStillAwake = true }
        }
        .alert("Still awake?", isPresented: $showStillAwake) {
            Button("Play 30 more minutes") {
                sound.extendTimer()
                if let fav = app.favoriteSoundIDs.first, let s = SleepSound.find(fav) {
                    if !sound.isPlaying { sound.toggle(s) }
                }
            }
            Button("Stop", role: .cancel) {
                sound.timerDidExpire = false
            }
        } message: {
            Text("Your sleep timer ended. Would you like to keep the sounds playing?")
        }
    }

    // MARK: - Preparing

    private var preparingView: some View {
        VStack(spacing: 28) {
            Spacer()
            Image(systemName: "moon.zzz.fill")
                .font(.system(size: 56))
                .foregroundStyle(nightPalette.accent)
                .symbolEffect(.pulse)
            Text("Preparing for sleep")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(nightPalette.primaryText)

            VStack(alignment: .leading, spacing: 16) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(completedSteps.contains(index) ? nightPalette.accent : nightPalette.primaryText.opacity(0.12))
                                .frame(width: 30, height: 30)
                            Image(systemName: completedSteps.contains(index) ? "checkmark" : step.0)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(completedSteps.contains(index) ? .white : nightPalette.secondaryText)
                        }
                        Text(step.1)
                            .font(.subheadline)
                            .foregroundStyle(completedSteps.contains(index) ? nightPalette.primaryText : nightPalette.secondaryText)
                        Spacer()
                    }
                    .opacity(completedSteps.contains(index) ? 1 : 0.5)
                }
            }
            .padding(22)
            .wakeGlass(cornerRadius: 24)
            .padding(.horizontal, 28)

            Spacer()
            Button("Cancel") { cancel() }
                .font(.subheadline)
                .foregroundStyle(nightPalette.secondaryText)
            Spacer().frame(height: 20)
        }
        .onAppear(perform: runSequence)
    }

    // MARK: - Sleep screen

    private var sleepView: some View {
        VStack(spacing: 30) {
            Spacer()
            VStack(spacing: 6) {
                Text(nowText)
                    .font(.system(size: 64, weight: .thin, design: .rounded))
                    .foregroundStyle(nightPalette.primaryText)
                Text("Sleep well")
                    .font(.title3)
                    .foregroundStyle(nightPalette.secondaryText)
            }

            if sound.isPlaying {
                VStack(spacing: 8) {
                    Image(systemName: "waveform")
                        .font(.title2)
                        .foregroundStyle(nightPalette.accent)
                        .symbolEffect(.variableColor.iterative, options: .repeating)
                    Text(currentSoundName)
                        .font(.subheadline).foregroundStyle(nightPalette.primaryText)
                    if sound.isTimerRunning {
                        Text(sound.timerText)
                            .font(.system(.headline, design: .rounded).monospacedDigit())
                            .foregroundStyle(nightPalette.secondaryText)
                    }
                }
                .padding(20)
                .wakeGlass(cornerRadius: 22)
            }

            HStack(spacing: 8) {
                Circle().fill(.green).frame(width: 8, height: 8)
                Text("Listening for sleep • microphone active")
                    .font(.caption).foregroundStyle(nightPalette.secondaryText)
            }

            Spacer()

            HStack(spacing: 16) {
                circleControl(torchOn ? "flashlight.on.fill" : "flashlight.off.fill", tint: torchOn ? .yellow : nightPalette.primaryText) {
                    torchOn.toggle()
                    Flashlight.toggle(on: torchOn)
                }
                circleControl(sound.isPlaying ? "pause.fill" : "play.fill", tint: nightPalette.primaryText) {
                    toggleSound()
                }
                circleControl("sunrise.fill", tint: nightPalette.accent) {
                    wakeUp()
                }
            }

            Button("I'm awake — end sleep") { wakeUp() }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(nightPalette.secondaryText)
                .padding(.top, 4)
            Spacer().frame(height: 24)
        }
        .padding(.horizontal, 28)
    }

    private func circleControl(_ icon: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(tint)
                .frame(width: 62, height: 62)
                .wakeGlass(cornerRadius: 31)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Logic

    private func runSequence() {
        for index in steps.indices {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.7 + 0.4) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    _ = completedSteps.insert(index)
                }
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                if index == 2 { startSound() }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(steps.count) * 0.7 + 0.8) {
            withAnimation(.easeInOut(duration: 1.4)) { phase = .asleep }
            sound.startTimer()
        }
    }

    private func startSound() {
        if !sound.isPlaying {
            let favID = app.favoriteSoundIDs.first ?? "rain"
            if let s = SleepSound.find(favID) { sound.toggle(s) }
        }
    }

    private func toggleSound() {
        if sound.isPlaying { sound.stopAll() }
        else { startSound(); sound.startTimer() }
    }

    private var currentSoundName: String {
        sound.layers.compactMap { SleepSound.find($0.id)?.name }.joined(separator: " + ")
    }

    private var nowText: String {
        let f = DateFormatter(); f.dateFormat = "h:mm"
        return f.string(from: Date())
    }

    private func cancel() {
        if torchOn { Flashlight.toggle(on: false) }
        dismiss()
    }

    private func wakeUp() {
        if torchOn { Flashlight.toggle(on: false) }
        sound.stopAll()
        dismiss()
    }
}
