//
//  HearingTestView.swift
//  WakeU
//

import SwiftUI

struct HearingTestView: View {
    @Environment(AppState.self) private var app
    @State private var tone = ToneGenerator()
    @State private var frequency: Double = 8000
    @State private var phase: Phase = .intro
    @State private var profileName = "You"
    @State private var savedMax: Double = 8000

    private var palette: WakePalette { app.palette }

    enum Phase { case intro, testing, result }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                disclaimer

                switch phase {
                case .intro: introCard
                case .testing: testingCard
                case .result: resultCard
                }

                if !app.hearingProfiles.isEmpty {
                    SectionLabel(text: "Saved profiles").environment(\.palette, palette)
                    ForEach(app.hearingProfiles) { profile in
                        profileRow(profile)
                    }
                }

                alertToneCard
                Color.clear.frame(height: 90)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
        .scrollIndicators(.hidden)
        .environment(\.palette, palette)
        .onDisappear { tone.stop() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Hearing Test")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(palette.primaryText)
            Text("Find your personal hearing range")
                .font(.subheadline).foregroundStyle(palette.secondaryText)
        }
        .padding(.top, 4)
    }

    private var disclaimer: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "info.circle.fill").foregroundStyle(palette.accent)
            Text("Results vary with age, hearing ability and your speakers or headphones. This is for fun and is not a medical test. We can't guarantee a partner won't hear a tone.")
                .font(.caption).foregroundStyle(palette.secondaryText)
        }
        .padding(14)
        .wakeGlass(cornerRadius: 16)
    }

    private var introCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("How it works")
                    .font(.headline).foregroundStyle(palette.primaryText)
                Text("Use headphones in a quiet room. A tone will rise in pitch. Tap “I can't hear it” the moment it disappears — that's roughly the top of your range.")
                    .font(.subheadline).foregroundStyle(palette.secondaryText)
                PrimaryActionButton(title: "Start Test", icon: "ear.fill", fill: palette.accent) {
                    frequency = 8000
                    tone.frequency = frequency
                    tone.play()
                    withAnimation { phase = .testing }
                }
            }
        }
        .environment(\.palette, palette)
    }

    private var testingCard: some View {
        GlassCard {
            VStack(spacing: 18) {
                Text("\(Int(frequency)) Hz")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(palette.accent)
                    .contentTransition(.numericText())
                Image(systemName: "waveform")
                    .font(.system(size: 40)).foregroundStyle(palette.primaryText)
                    .symbolEffect(.variableColor.iterative, options: .repeating)
                Text("Slide up slowly until you can no longer hear it.")
                    .font(.subheadline).foregroundStyle(palette.secondaryText)
                    .multilineTextAlignment(.center)
                Slider(value: $frequency, in: 2000...20000, step: 100)
                    .tint(palette.accent)
                    .onChange(of: frequency) { _, newValue in tone.frequency = newValue }
                HStack(spacing: 12) {
                    Button("I can't hear it") {
                        savedMax = frequency
                        tone.stop()
                        withAnimation { phase = .result }
                    }
                    .font(.headline).foregroundStyle(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 14)
                    .background(Capsule().fill(palette.accent))
                    .buttonStyle(.plain)
                }
                Button("Cancel") { tone.stop(); withAnimation { phase = .intro } }
                    .font(.subheadline).foregroundStyle(palette.secondaryText)
            }
        }
        .environment(\.palette, palette)
    }

    private var resultCard: some View {
        GlassCard {
            VStack(spacing: 14) {
                Text("Your hearing range")
                    .font(.headline).foregroundStyle(palette.primaryText)
                Text("up to \(Int(savedMax)) Hz")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(palette.accent)
                // Simple range visualisation
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(palette.primaryText.opacity(0.12))
                        Capsule()
                            .fill(LinearGradient(colors: [palette.accentSoft, palette.accent], startPoint: .leading, endPoint: .trailing))
                            .frame(width: geo.size.width * CGFloat((savedMax - 2000) / 18000))
                    }
                }
                .frame(height: 12)
                Text("Typical for: \(HearingProfile(name: "", maxFrequency: savedMax).approxAge)")
                    .font(.subheadline).foregroundStyle(palette.secondaryText)

                HStack {
                    TextField("Profile name", text: $profileName)
                        .foregroundStyle(palette.primaryText)
                        .padding(12).wakeGlass(cornerRadius: 12)
                    Button("Save") {
                        app.saveHearingProfile(HearingProfile(name: profileName.isEmpty ? "Profile" : profileName, maxFrequency: savedMax))
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                        withAnimation { phase = .intro }
                    }
                    .font(.headline).foregroundStyle(.white)
                    .padding(.horizontal, 20).padding(.vertical, 12)
                    .background(Capsule().fill(palette.accent))
                    .buttonStyle(.plain)
                }
            }
        }
        .environment(\.palette, palette)
    }

    private func profileRow(_ profile: HearingProfile) -> some View {
        HStack(spacing: 14) {
            Image(systemName: "person.crop.circle.fill").font(.title2).foregroundStyle(palette.accent)
            VStack(alignment: .leading, spacing: 2) {
                Text(profile.name).font(.subheadline.weight(.semibold)).foregroundStyle(palette.primaryText)
                Text("Up to \(Int(profile.maxFrequency)) Hz • \(profile.approxAge)")
                    .font(.caption).foregroundStyle(palette.secondaryText)
            }
            Spacer()
            Button {
                tone.frequency = profile.maxFrequency - 500
                tone.play()
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { tone.stop() }
            } label: {
                Image(systemName: "play.circle.fill").font(.title2).foregroundStyle(palette.accent)
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .wakeGlass(cornerRadius: 18)
    }

    private var alertToneCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                Label("High-Frequency Alert", systemImage: "bell.badge.waveform.fill")
                    .font(.headline).foregroundStyle(palette.primaryText)
                Text("Generate a high tone that may be audible to one person but not another. Effectiveness depends on hearing and hardware.")
                    .font(.caption).foregroundStyle(palette.secondaryText)
                HStack(spacing: 12) {
                    ForEach([15000, 17000, 19000], id: \.self) { hz in
                        Button {
                            tone.frequency = Double(hz)
                            tone.play()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { tone.stop() }
                        } label: {
                            Text("\(hz / 1000)k")
                                .font(.subheadline.weight(.semibold))
                                .padding(.horizontal, 16).padding(.vertical, 10)
                                .background(Capsule().fill(palette.accent.opacity(0.2)))
                                .foregroundStyle(palette.primaryText)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .environment(\.palette, palette)
    }
}
