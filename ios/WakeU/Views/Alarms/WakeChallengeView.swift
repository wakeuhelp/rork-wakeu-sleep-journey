//
//  WakeChallengeView.swift
//  WakeU
//

import SwiftUI
import CoreMotion

/// Full-screen challenge the user must complete to dismiss an alarm.
/// Also reused in "test" mode so users can try a challenge before choosing it.
struct WakeChallengeView: View {
    let challenge: WakeChallenge
    var isTest: Bool = false
    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss
    @State private var completed = false

    private var palette: WakePalette { app.palette }

    var body: some View {
        ZStack {
            AnimatedBackground(palette: palette)
            VStack(spacing: 24) {
                header
                Spacer()
                if completed {
                    successView
                } else {
                    challengeBody
                }
                Spacer()
                if isTest && !completed {
                    Button("Close test") { dismiss() }
                        .font(.subheadline).foregroundStyle(palette.secondaryText)
                        .padding(.bottom, 20)
                }
            }
            .padding(24)
        }
        .environment(\.palette, palette)
    }

    private var header: some View {
        VStack(spacing: 8) {
            if isTest {
                Text("TEST MODE").font(.caption.weight(.bold)).tracking(2)
                    .foregroundStyle(palette.accent)
            } else {
                Text(timeText).font(.system(size: 40, weight: .thin, design: .rounded))
                    .foregroundStyle(palette.primaryText)
            }
            Label(challenge.name, systemImage: challenge.symbol)
                .font(.title3.weight(.semibold))
                .foregroundStyle(palette.primaryText)
        }
        .padding(.top, 30)
    }

    @ViewBuilder
    private var challengeBody: some View {
        switch challenge.kind {
        case .math: MathChallenge(onSolve: solve).environment(\.palette, palette)
        case .memory, .pattern: MemoryChallenge(onSolve: solve).environment(\.palette, palette)
        case .color: ColorSequenceChallenge(onSolve: solve).environment(\.palette, palette)
        case .shake: ShakeChallenge(onSolve: solve).environment(\.palette, palette)
        case .phrase: PhraseChallenge(onSolve: solve).environment(\.palette, palette)
        default: GenericTapChallenge(challenge: challenge, onSolve: solve).environment(\.palette, palette)
        }
    }

    private var successView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 72)).foregroundStyle(.green)
                .symbolEffect(.bounce)
            Text(isTest ? "Nicely done!" : "Good Morning!")
                .font(.title.weight(.bold)).foregroundStyle(palette.primaryText)
            Text(isTest ? "This challenge works great." : "You're awake. Have a wonderful day.")
                .font(.subheadline).foregroundStyle(palette.secondaryText)
            Button {
                dismiss()
            } label: {
                Text(isTest ? "Done" : "Start my day")
                    .font(.headline).foregroundStyle(.white)
                    .padding(.horizontal, 40).padding(.vertical, 14)
                    .background(Capsule().fill(palette.accent))
            }
            .buttonStyle(.plain)
            .padding(.top, 8)
        }
    }

    private func solve() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) { completed = true }
    }

    private var timeText: String {
        let f = DateFormatter(); f.dateFormat = "h:mm"
        return f.string(from: Date())
    }
}

// MARK: - Math

struct MathChallenge: View {
    let onSolve: () -> Void
    @Environment(\.palette) private var palette
    @State private var a = Int.random(in: 12...39)
    @State private var b = Int.random(in: 11...29)
    @State private var answer = ""
    @State private var wrong = false

    var body: some View {
        VStack(spacing: 24) {
            Text("\(a) + \(b)")
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .foregroundStyle(palette.primaryText)
            Text(answer.isEmpty ? "?" : answer)
                .font(.system(size: 40, weight: .semibold, design: .rounded))
                .foregroundStyle(wrong ? .red : palette.accent)
                .frame(height: 50)
            NumberPad(value: $answer, maxLength: 3) { check() }
        }
    }

    private func check() {
        if Int(answer) == a + b { onSolve() }
        else {
            withAnimation { wrong = true }
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                answer = ""; wrong = false
            }
        }
    }
}

struct NumberPad: View {
    @Binding var value: String
    let maxLength: Int
    let onSubmit: () -> Void
    @Environment(\.palette) private var palette

    private let keys = ["1","2","3","4","5","6","7","8","9","⌫","0","✓"]

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: 3), spacing: 14) {
            ForEach(keys, id: \.self) { key in
                Button {
                    tap(key)
                } label: {
                    Text(key)
                        .font(.title2.weight(.medium))
                        .foregroundStyle(key == "✓" ? .white : palette.primaryText)
                        .frame(maxWidth: .infinity, minHeight: 64)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(key == "✓" ? palette.accent : Color.clear)
                        )
                        .wakeGlass(cornerRadius: 18)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: 320)
    }

    private func tap(_ key: String) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        switch key {
        case "⌫": if !value.isEmpty { value.removeLast() }
        case "✓": onSubmit()
        default: if value.count < maxLength { value += key }
        }
    }
}

// MARK: - Memory / Pattern

struct MemoryChallenge: View {
    let onSolve: () -> Void
    @Environment(\.palette) private var palette
    @State private var sequence: [Int] = []
    @State private var input: [Int] = []
    @State private var highlight: Int? = nil
    @State private var showing = true
    private let tiles = 4

    var body: some View {
        VStack(spacing: 20) {
            Text(showing ? "Watch the sequence" : "Repeat it")
                .font(.headline).foregroundStyle(palette.primaryText)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: 2), spacing: 14) {
                ForEach(0..<tiles, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 20)
                        .fill(tileColor(i))
                        .frame(height: 90)
                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(.white.opacity(0.2)))
                        .scaleEffect(highlight == i ? 1.06 : 1)
                        .onTapGesture { if !showing { tap(i) } }
                }
            }
            .frame(maxWidth: 280)
        }
        .onAppear(perform: start)
    }

    private func tileColor(_ i: Int) -> Color {
        let colors: [Color] = [.pink, .blue, .green, .orange]
        return highlight == i ? colors[i] : colors[i].opacity(0.35)
    }

    private func start() {
        sequence = (0..<4).map { _ in Int.random(in: 0..<tiles) }
        playSequence()
    }

    private func playSequence() {
        showing = true
        for (idx, tile) in sequence.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(idx) * 0.6 + 0.4) {
                withAnimation(.easeInOut(duration: 0.2)) { highlight = tile }
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation { highlight = nil }
                }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(sequence.count) * 0.6 + 0.6) {
            showing = false
        }
    }

    private func tap(_ i: Int) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(.easeInOut(duration: 0.15)) { highlight = i }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { highlight = nil }
        input.append(i)
        if input[input.count - 1] != sequence[input.count - 1] {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            input = []
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { playSequence() }
            return
        }
        if input.count == sequence.count { onSolve() }
    }
}

// MARK: - Color sequence

struct ColorSequenceChallenge: View {
    let onSolve: () -> Void
    @Environment(\.palette) private var palette
    private let colors: [(String, Color)] = [("Red", .red), ("Blue", .blue), ("Green", .green), ("Yellow", .yellow)]
    @State private var target: [Int] = []
    @State private var idx = 0

    var body: some View {
        VStack(spacing: 22) {
            Text("Tap the colours in order")
                .font(.headline).foregroundStyle(palette.primaryText)
            HStack(spacing: 8) {
                ForEach(Array(target.enumerated()), id: \.offset) { i, c in
                    Text(colors[c].0)
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(Capsule().fill(colors[c].1.opacity(i < idx ? 1 : 0.3)))
                        .foregroundStyle(.white)
                }
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: 2), spacing: 14) {
                ForEach(0..<colors.count, id: \.self) { i in
                    Button { tap(i) } label: {
                        RoundedRectangle(cornerRadius: 20).fill(colors[i].1)
                            .frame(height: 80)
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: 280)
        }
        .onAppear { target = (0..<4).map { _ in Int.random(in: 0..<colors.count) } }
    }

    private func tap(_ i: Int) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        if i == target[idx] {
            idx += 1
            if idx == target.count { onSolve() }
        } else {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            idx = 0
        }
    }
}

// MARK: - Shake

struct ShakeChallenge: View {
    let onSolve: () -> Void
    @Environment(\.palette) private var palette
    @State private var progress = 0.0
    @State private var motion = CMMotionManager()

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "iphone.gen3.radiowaves.left.and.right")
                .font(.system(size: 64)).foregroundStyle(palette.accent)
                .rotationEffect(.degrees(progress * 6 - 3))
            Text("Shake your phone!")
                .font(.title2.weight(.bold)).foregroundStyle(palette.primaryText)
            ProgressView(value: progress, total: 1)
                .tint(palette.accent).frame(maxWidth: 240)
            Text("\(Int(progress * 100))%").foregroundStyle(palette.secondaryText)
        }
        .onAppear(perform: startMotion)
        .onDisappear { motion.stopAccelerometerUpdates() }
    }

    private func startMotion() {
        guard motion.isAccelerometerAvailable else {
            // Simulator fallback: tap-to-progress.
            return
        }
        motion.accelerometerUpdateInterval = 0.05
        motion.startAccelerometerUpdates(to: .main) { data, _ in
            guard let data else { return }
            let magnitude = abs(data.acceleration.x) + abs(data.acceleration.y) + abs(data.acceleration.z)
            if magnitude > 2.2 {
                progress = min(1, progress + 0.04)
                if progress >= 1 { motion.stopAccelerometerUpdates(); onSolve() }
            }
        }
    }
}

// MARK: - Phrase (read aloud)

struct PhraseChallenge: View {
    let onSolve: () -> Void
    @Environment(\.palette) private var palette
    private let phrases = ["The morning sun feels wonderful today", "I am awake and ready to begin", "A new day full of possibility"]
    @State private var phrase = ""

    var body: some View {
        VStack(spacing: 22) {
            Image(systemName: "text.bubble.fill").font(.system(size: 48)).foregroundStyle(palette.accent)
            Text("Read this aloud").font(.headline).foregroundStyle(palette.secondaryText)
            Text("“\(phrase)”")
                .font(.title2.weight(.semibold))
                .multilineTextAlignment(.center)
                .foregroundStyle(palette.primaryText)
            Button {
                onSolve()
            } label: {
                Text("I read it")
                    .font(.headline).foregroundStyle(.white)
                    .padding(.horizontal, 36).padding(.vertical, 14)
                    .background(Capsule().fill(palette.accent))
            }
            .buttonStyle(.plain)
        }
        .onAppear { phrase = phrases.randomElement() ?? phrases[0] }
    }
}

// MARK: - Generic tap (steps / qr / photo / smile)

struct GenericTapChallenge: View {
    let challenge: WakeChallenge
    let onSolve: () -> Void
    @Environment(\.palette) private var palette
    @State private var progress = 0.0

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: challenge.symbol)
                .font(.system(size: 60)).foregroundStyle(palette.accent)
            Text(challenge.detail).font(.title3.weight(.semibold))
                .multilineTextAlignment(.center).foregroundStyle(palette.primaryText)
            Text(hint).font(.subheadline).foregroundStyle(palette.secondaryText)
                .multilineTextAlignment(.center)
            if progress > 0 {
                ProgressView(value: progress, total: 1).tint(palette.accent).frame(maxWidth: 240)
            }
            Button {
                withAnimation { progress = min(1, progress + 0.34) }
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                if progress >= 1 { onSolve() }
            } label: {
                Text(buttonTitle)
                    .font(.headline).foregroundStyle(.white)
                    .padding(.horizontal, 36).padding(.vertical, 14)
                    .background(Capsule().fill(palette.accent))
            }
            .buttonStyle(.plain)
        }
    }

    private var hint: String {
        switch challenge.kind {
        case .steps: return "Get out of bed — each tap counts a few steps."
        case .qr: return "On device, point your camera at the saved QR code."
        case .photo: return "On device, snap a photo of your bathroom sink."
        case .smile: return "On device, smile into the front camera to dismiss."
        default: return "Complete the action to wake up."
        }
    }

    private var buttonTitle: String {
        switch challenge.kind {
        case .steps: return "I took some steps"
        case .qr: return "Scan code"
        case .photo: return "Take photo"
        case .smile: return "Smile detected"
        default: return "Continue"
        }
    }
}
