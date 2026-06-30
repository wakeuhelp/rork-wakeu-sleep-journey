//
//  ComposeDreamView.swift
//  WakeU
//

import SwiftUI

struct ComposeDreamView: View {
    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    @State private var mood: DreamEntry.Mood = .neutral
    @FocusState private var focused: Bool

    private let palette = WakePalette.palette(for: .night)

    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedBackground(palette: palette)
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("What did you dream about?")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(palette.primaryText)

                        ZStack(alignment: .topLeading) {
                            if text.isEmpty {
                                Text("Describe your dream… tap the mic on the keyboard to speak it aloud.")
                                    .foregroundStyle(palette.secondaryText)
                                    .padding(16)
                            }
                            TextEditor(text: $text)
                                .focused($focused)
                                .scrollContentBackground(.hidden)
                                .foregroundStyle(palette.primaryText)
                                .frame(minHeight: 180)
                                .padding(8)
                        }
                        .wakeGlass(cornerRadius: 20)

                        SectionLabel(text: "How did it feel?")
                            .environment(\.palette, palette)
                        HStack(spacing: 10) {
                            ForEach(DreamEntry.Mood.allCases) { m in
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { mood = m }
                                } label: {
                                    VStack(spacing: 6) {
                                        Image(systemName: m.symbol).font(.title3)
                                        Text(m.label).font(.caption2)
                                    }
                                    .foregroundStyle(mood == m ? .white : palette.primaryText)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(RoundedRectangle(cornerRadius: 16).fill(mood == m ? m.color.opacity(0.85) : .clear))
                                    .wakeGlass(cornerRadius: 16)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        PrimaryActionButton(title: "Save & Interpret", icon: "sparkles", fill: palette.accent) {
                            save()
                        }
                        .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)
                        .opacity(text.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)
                    }
                    .padding(20)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("New Dream")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundStyle(palette.accent)
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
        .onAppear { focused = true }
    }

    private func save() {
        let analysis = DreamAnalyzer.analyze(text)
        let entry = DreamEntry(
            date: Date(),
            text: text.trimmingCharacters(in: .whitespacesAndNewlines),
            mood: mood,
            themes: analysis.themes,
            symbols: analysis.symbols,
            interpretation: analysis.interpretation
        )
        app.addDream(entry)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        dismiss()
    }
}

/// Lightweight on-device dream analysis: extracts themes/symbols by keyword and
/// composes a friendly, clearly-speculative interpretation.
enum DreamAnalyzer {
    struct Result { let themes: [String]; let symbols: [String]; let interpretation: String }

    private static let map: [(keys: [String], theme: String, symbol: String)] = [
        (["fly", "flew", "floating", "float"], "Flying", "Wings"),
        (["fall", "falling", "fell"], "Falling", "Edge"),
        (["water", "ocean", "sea", "river", "rain", "swim"], "Water", "Water"),
        (["chase", "chased", "run", "running", "escape"], "Being Chased", "Path"),
        (["lost", "searching", "search", "find", "looking"], "Searching", "Maze"),
        (["house", "home", "room", "door"], "Home", "Door"),
        (["family", "friend", "mother", "father", "partner"], "Relationships", "Faces"),
        (["test", "exam", "late", "work"], "Pressure", "Clock"),
        (["dark", "night", "shadow"], "The Unknown", "Shadow"),
        (["light", "sun", "glow", "bright"], "Hope", "Light"),
        (["forest", "tree", "mountain", "nature"], "Nature", "Forest"),
        (["fly", "space", "star", "moon", "sky"], "The Cosmos", "Stars"),
    ]

    static func analyze(_ text: String) -> Result {
        let lower = text.lowercased()
        var themes: [String] = []
        var symbols: [String] = []
        for entry in map where entry.keys.contains(where: { lower.contains($0) }) {
            if !themes.contains(entry.theme) { themes.append(entry.theme) }
            if !symbols.contains(entry.symbol) { symbols.append(entry.symbol) }
        }
        if themes.isEmpty { themes = ["Reflection"]; symbols = ["Memory"] }

        let lead = themes.prefix(2).joined(separator: " and ")
        let interpretation = "Your dream touches on \(lead.lowercased()). Dreams like this often surface when the mind is gently sorting through recent feelings and experiences. For a bit of fun: your dream-self seems to be exploring something meaningful to you right now. Remember, dream interpretations are playful and speculative — not facts."
        return Result(themes: Array(themes.prefix(4)), symbols: Array(symbols.prefix(4)), interpretation: interpretation)
    }
}
