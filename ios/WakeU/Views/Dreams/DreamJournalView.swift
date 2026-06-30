//
//  DreamJournalView.swift
//  WakeU
//

import SwiftUI

struct DreamJournalView: View {
    @Environment(AppState.self) private var app
    @State private var searchText = ""
    @State private var showCompose = false

    private var palette: WakePalette { app.palette }

    private var filtered: [DreamEntry] {
        guard !searchText.isEmpty else { return app.dreams }
        let q = searchText.lowercased()
        return app.dreams.filter {
            $0.text.lowercased().contains(q) ||
            $0.themes.joined(separator: " ").lowercased().contains(q) ||
            $0.symbols.joined(separator: " ").lowercased().contains(q)
        }
    }

    private var allThemes: [String] {
        Array(Set(app.dreams.flatMap { $0.themes })).sorted()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                searchField

                if !allThemes.isEmpty && searchText.isEmpty {
                    SectionLabel(text: "Recurring themes")
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(allThemes, id: \.self) { theme in
                                Button { searchText = theme } label: {
                                    Text(theme)
                                        .font(.caption.weight(.medium))
                                        .padding(.horizontal, 14).padding(.vertical, 8)
                                        .background(Capsule().fill(palette.accent.opacity(0.18)))
                                        .foregroundStyle(palette.primaryText)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .scrollClipDisabled()
                }

                if filtered.isEmpty {
                    emptyState
                } else {
                    ForEach(filtered) { dream in
                        DreamCard(dream: dream).environment(\.palette, palette)
                    }
                }
                Color.clear.frame(height: 90)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
        .scrollIndicators(.hidden)
        .environment(\.palette, palette)
        .overlay(alignment: .bottomTrailing) {
            Button { showCompose = true } label: {
                Image(systemName: "plus")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 60, height: 60)
                    .background(Circle().fill(palette.accent).shadow(color: palette.accent.opacity(0.5), radius: 12, y: 4))
            }
            .padding(.trailing, 24).padding(.bottom, 100)
        }
        .sheet(isPresented: $showCompose) {
            ComposeDreamView().environment(app)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Dream Journal")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(palette.primaryText)
            Text("\(app.dreams.count) dreams recorded")
                .font(.subheadline).foregroundStyle(palette.secondaryText)
        }
        .padding(.top, 4)
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass").foregroundStyle(palette.secondaryText)
            TextField("Search dreams", text: $searchText)
                .foregroundStyle(palette.primaryText)
            if !searchText.isEmpty {
                Button { searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(palette.secondaryText)
                }
            }
        }
        .padding(14)
        .wakeGlass(cornerRadius: 16)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "cloud.moon.fill")
                .font(.system(size: 44)).foregroundStyle(palette.accent)
            Text(searchText.isEmpty ? "No dreams yet" : "No matches")
                .font(.headline).foregroundStyle(palette.primaryText)
            Text(searchText.isEmpty ? "Tap + to capture your first dream." : "Try a different search.")
                .font(.subheadline).foregroundStyle(palette.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

struct DreamCard: View {
    let dream: DreamEntry
    @Environment(\.palette) private var palette
    @State private var expanded = false

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label {
                        Text(dream.mood.label).font(.caption.weight(.semibold))
                    } icon: {
                        Image(systemName: dream.mood.symbol)
                    }
                    .foregroundStyle(dream.mood.color)
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(Capsule().fill(dream.mood.color.opacity(0.18)))
                    Spacer()
                    Text(dateText).font(.caption).foregroundStyle(palette.secondaryText)
                }
                Text(dream.text)
                    .font(.subheadline)
                    .foregroundStyle(palette.primaryText)
                    .lineLimit(expanded ? nil : 3)

                if !dream.themes.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(dream.themes, id: \.self) { theme in
                            Text(theme).font(.caption2.weight(.medium))
                                .padding(.horizontal, 8).padding(.vertical, 4)
                                .background(Capsule().fill(palette.accent.opacity(0.16)))
                                .foregroundStyle(palette.primaryText)
                        }
                    }
                }

                if expanded && !dream.interpretation.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Label("Interpretation", systemImage: "sparkles")
                            .font(.caption.weight(.semibold)).foregroundStyle(palette.accent)
                        Text(dream.interpretation)
                            .font(.caption).foregroundStyle(palette.secondaryText)
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 14).fill(palette.accent.opacity(0.1)))
                }

                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { expanded.toggle() }
                } label: {
                    Text(expanded ? "Show less" : "Read interpretation")
                        .font(.caption.weight(.semibold)).foregroundStyle(palette.accent)
                }
            }
        }
    }

    private var dateText: String {
        let f = DateFormatter(); f.dateFormat = "MMM d"
        return f.string(from: dream.date)
    }
}
