//
//  BedtimeStoriesView.swift
//  WakeU
//

import SwiftUI
import AVFoundation

struct BedtimeStoriesView: View {
    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTheme: StoryTheme = StoryTheme.all[0]
    @State private var useFemaleVoice = true
    @State private var story: String = ""
    @State private var isNarrating = false

    private let synthesizer = AVSpeechSynthesizer()
    private let palette = WakePalette.palette(for: .night)

    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedBackground(palette: palette)
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        SectionLabel(text: "Choose a theme")
                            .environment(\.palette, palette)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(StoryTheme.all) { theme in
                                    themeChip(theme)
                                }
                            }
                        }
                        .scrollClipDisabled()

                        Toggle(isOn: $useFemaleVoice) {
                            Label(useFemaleVoice ? "Female narration" : "Male narration", systemImage: "person.wave.2.fill")
                                .foregroundStyle(palette.primaryText)
                        }
                        .tint(palette.accent)
                        .padding(16)
                        .wakeGlass(cornerRadius: 18)

                        PrimaryActionButton(title: story.isEmpty ? "Create Story" : "New Story", icon: "sparkles", fill: palette.accent) {
                            generate()
                        }

                        if !story.isEmpty {
                            GlassCard {
                                VStack(alignment: .leading, spacing: 14) {
                                    Text(story)
                                        .font(.system(.body, design: .serif))
                                        .foregroundStyle(palette.primaryText)
                                        .lineSpacing(6)
                                    Button {
                                        narrate()
                                    } label: {
                                        Label(isNarrating ? "Stop narration" : "Narrate", systemImage: isNarrating ? "stop.circle.fill" : "play.circle.fill")
                                            .font(.headline)
                                            .foregroundStyle(palette.accent)
                                    }
                                }
                            }
                            .environment(\.palette, palette)
                        }
                        Color.clear.frame(height: 40)
                    }
                    .padding(20)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Bedtime Story")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { synthesizer.stopSpeaking(at: .immediate); dismiss() }
                        .foregroundStyle(palette.accent)
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
    }

    private func themeChip(_ theme: StoryTheme) -> some View {
        Button {
            selectedTheme = theme
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            VStack(spacing: 8) {
                Image(systemName: theme.symbol)
                    .font(.title2)
                    .foregroundStyle(selectedTheme.id == theme.id ? .white : theme.tint)
                Text(theme.name).font(.caption.weight(.medium))
                    .foregroundStyle(selectedTheme.id == theme.id ? .white : palette.primaryText)
            }
            .frame(width: 84, height: 84)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(selectedTheme.id == theme.id ? theme.tint.opacity(0.8) : .clear)
            )
            .wakeGlass(cornerRadius: 20)
        }
        .buttonStyle(.plain)
    }

    private func generate() {
        story = BedtimeStoryWriter.story(for: selectedTheme)
    }

    private func narrate() {
        if isNarrating {
            synthesizer.stopSpeaking(at: .immediate)
            isNarrating = false
            return
        }
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch { print("[Stories] audio error \(error.localizedDescription)") }
        let utterance = AVSpeechUtterance(string: story)
        utterance.rate = 0.42
        utterance.pitchMultiplier = useFemaleVoice ? 1.05 : 0.85
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        synthesizer.speak(utterance)
        isNarrating = true
    }
}

/// On-device calming story generator templated by theme.
enum BedtimeStoryWriter {
    static func story(for theme: StoryTheme) -> String {
        switch theme.id {
        case "space":
            return "Far beyond the quiet edge of the sky, a small silver ship drifted between sleeping stars. There was nowhere to be and nothing to do but float. Each star hummed a soft, low note, and together they made a lullaby older than time. You leaned back, weightless, and let the slow tide of the galaxy carry you gently onward, deeper and deeper into the calm dark."
        case "ocean":
            return "The tide came in slowly under a wide, soft moon. Each wave arrived like a breath — rising, folding, smoothing the sand, then sliding away again. Warm water curled around your feet and then let go. There was nothing to hold, nothing to chase. Just the long, even rhythm of the sea, breathing in and breathing out, until your own breathing matched it, slow and deep and easy."
        case "fantasy":
            return "In a valley where lanterns grew like flowers, a sleepy dragon curled around a hill of moss. Its breath was warm and smelled of cinnamon. Tiny glowing moths settled on its wings, one by one, until the whole hillside shimmered. The dragon yawned, the lanterns dimmed, and the valley settled into a hush so gentle it felt like being tucked beneath a soft, enormous wing."
        case "nature":
            return "A meadow lay still beneath the last gold light of evening. Tall grass swayed, brushing softly against itself, and somewhere a stream whispered over smooth stones. The air smelled of warm earth and clover. You lay back in the grass and watched the sky deepen from amber to indigo, while fireflies rose like slow, drifting sparks, and the whole world breathed quietly around you."
        case "rain":
            return "Rain tapped softly on the roof, steady and kind. Inside, you were wrapped in the warmest blanket, watching little rivers race down the windowpane. The world outside blurred into soft grey, and every drop seemed to whisper the same thing: rest now, rest now. The sound wrapped around the room like a hush, and slowly, gently, your thoughts grew quiet and far away."
        case "cabin":
            return "Deep in snowy woods stood a little cabin with a glowing window. Inside, a fire crackled low and orange, and the smell of woodsmoke filled the warm air. Outside, snow fell without a sound, settling on the pines. You sank into a deep chair beneath a heavy quilt, and the fire's soft pop and the silent snow held you in a calm so complete it felt like the whole forest was sleeping with you."
        default:
            return "High on a quiet mountain, the last light slipped behind distant peaks. The air was cool and clean, and far below, a sea of soft clouds rolled slowly past. The mountain held you steady and certain, ancient and calm. Stars began to appear, one by one, and the silence was so vast and gentle that every worry felt small and far away, until at last there was only the slow, peaceful dark."
        }
    }
}
