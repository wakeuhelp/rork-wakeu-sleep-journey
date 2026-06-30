//
//  SoundsView.swift
//  WakeU
//

import SwiftUI

struct SoundsView: View {
    @Environment(AppState.self) private var app
    @Environment(SoundEngine.self) private var sound
    @State private var showStories = false
    @State private var showPaywall = false

    private var palette: WakePalette { app.palette }
    private let columns = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header

                if !sound.layers.isEmpty {
                    nowPlayingCard
                }

                if !app.favoriteSoundIDs.isEmpty {
                    SectionLabel(text: "Favourites")
                    grid(SleepSound.all.filter { app.favoriteSoundIDs.contains($0.id) })
                }

                SectionLabel(text: "All sounds")
                grid(SleepSound.all)

                bedtimeStoriesCard

                Color.clear.frame(height: 90)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
        .scrollIndicators(.hidden)
        .environment(\.palette, palette)
        .sheet(isPresented: $showStories) {
            BedtimeStoriesView().environment(app)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView().environment(app)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Sounds")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(palette.primaryText)
            Text("Mix up to two sounds to drift off")
                .font(.subheadline).foregroundStyle(palette.secondaryText)
        }
        .padding(.top, 4)
    }

    private func grid(_ sounds: [SleepSound]) -> some View {
        LazyVGrid(columns: columns, spacing: 14) {
            ForEach(sounds) { item in
                SoundTile(
                    sound: item,
                    isActive: sound.isActive(item.id),
                    isFavorite: app.favoriteSoundIDs.contains(item.id),
                    locked: item.isPremium && !app.isPremium
                ) {
                    if item.isPremium && !app.isPremium { showPaywall = true; return }
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        sound.toggle(item)
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } onFavorite: {
                    withAnimation { app.toggleFavorite(item.id) }
                }
                .environment(\.palette, palette)
            }
        }
    }

    private var nowPlayingCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Label("Now Playing", systemImage: "waveform")
                        .font(.headline).foregroundStyle(palette.primaryText)
                    Spacer()
                    Button {
                        withAnimation { sound.stopAll() }
                    } label: {
                        Image(systemName: "stop.fill").foregroundStyle(palette.accent)
                    }
                }
                ForEach(sound.layers) { layer in
                    if let s = SleepSound.find(layer.id) {
                        VStack(spacing: 6) {
                            HStack {
                                Image(systemName: s.symbol).foregroundStyle(s.tint)
                                Text(s.name).font(.subheadline.weight(.medium)).foregroundStyle(palette.primaryText)
                                Spacer()
                            }
                            Slider(value: Binding(
                                get: { Double(sound.volume(for: layer.id)) },
                                set: { sound.setVolume(Float($0), for: layer.id) }
                            ), in: 0...1)
                            .tint(s.tint)
                        }
                    }
                }
                Divider().background(palette.primaryText.opacity(0.1))
                TimerControl()
                    .environment(\.palette, palette)
            }
        }
    }

    private var bedtimeStoriesCard: some View {
        Button {
            if app.isPremium { showStories = true } else { showPaywall = true }
        } label: {
            GlassCard {
                HStack(spacing: 14) {
                    Image(systemName: "books.vertical.fill")
                        .font(.title)
                        .foregroundStyle(palette.accent)
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text("AI Bedtime Stories")
                                .font(.headline).foregroundStyle(palette.primaryText)
                            if !app.isPremium { PremiumBadge() }
                        }
                        Text("Personalised, calming tales with narration")
                            .font(.caption).foregroundStyle(palette.secondaryText)
                    }
                    Spacer()
                    Image(systemName: "chevron.right").foregroundStyle(palette.secondaryText)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

struct SoundTile: View {
    let sound: SleepSound
    let isActive: Bool
    let isFavorite: Bool
    let locked: Bool
    let onTap: () -> Void
    let onFavorite: () -> Void
    @Environment(\.palette) private var palette

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Image(systemName: locked ? "lock.fill" : sound.symbol)
                        .font(.title2)
                        .foregroundStyle(isActive ? .white : sound.tint)
                    Spacer()
                    Button(action: onFavorite) {
                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                            .font(.subheadline)
                            .foregroundStyle(isFavorite ? .pink : palette.secondaryText)
                    }
                    .buttonStyle(.plain)
                }
                Spacer(minLength: 18)
                Text(sound.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(isActive ? .white : palette.primaryText)
                if isActive {
                    Text("Playing")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
            .padding(16)
            .frame(height: 120, alignment: .topLeading)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(isActive ? sound.tint.opacity(0.85) : Color.clear)
            )
            .wakeGlass(cornerRadius: 22)
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .stroke(isActive ? sound.tint : .clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}

struct TimerControl: View {
    @Environment(SoundEngine.self) private var sound
    @Environment(\.palette) private var palette
    private let options = [15, 30, 45, 60]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Sleep timer", systemImage: "timer").font(.subheadline.weight(.medium))
                    .foregroundStyle(palette.primaryText)
                Spacer()
                if sound.isTimerRunning {
                    Text(sound.timerText)
                        .font(.subheadline.monospacedDigit().weight(.semibold))
                        .foregroundStyle(palette.accent)
                }
            }
            if sound.isTimerRunning {
                Button("Cancel timer") { sound.cancelTimer() }
                    .font(.caption).foregroundStyle(palette.secondaryText)
            } else {
                HStack(spacing: 8) {
                    ForEach(options, id: \.self) { minutes in
                        Button {
                            sound.timerMinutes = minutes
                            sound.startTimer()
                        } label: {
                            Text("\(minutes)m")
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 14).padding(.vertical, 8)
                                .background(Capsule().fill(palette.accent.opacity(0.18)))
                                .foregroundStyle(palette.primaryText)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

struct PremiumBadge: View {
    var body: some View {
        Text("PRO")
            .font(.system(size: 9, weight: .heavy))
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(Capsule().fill(LinearGradient(colors: [.yellow, .orange], startPoint: .leading, endPoint: .trailing)))
            .foregroundStyle(.black)
    }
}
