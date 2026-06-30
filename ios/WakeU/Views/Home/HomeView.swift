//
//  HomeView.swift
//  WakeU
//

import SwiftUI

struct HomeView: View {
    @Environment(AppState.self) private var app
    @Environment(SoundEngine.self) private var sound
    @Binding var selectedTab: RootTab
    @Binding var showGoodnight: Bool

    private var palette: WakePalette { app.palette }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header
                switch app.timeOfDay {
                case .morning: morningContent
                case .afternoon: afternoonContent
                case .evening: eveningContent
                case .night: nightContent
                }
                Color.clear.frame(height: 90)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
        .scrollIndicators(.hidden)
        .environment(\.palette, palette)
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(app.timeOfDay.greeting)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(palette.primaryText)
                Text(app.timeOfDay.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(palette.secondaryText)
            }
            Spacer()
            Image(systemName: app.timeOfDay.symbol)
                .font(.system(size: 30))
                .foregroundStyle(palette.accent)
                .padding(12)
                .wakeGlass(cornerRadius: 18)
        }
        .padding(.top, 4)
    }

    // MARK: - Morning

    private var morningContent: some View {
        VStack(spacing: 18) {
            GlassCard {
                VStack(spacing: 18) {
                    ScoreRing(score: app.lastNight.score)
                        .padding(.top, 4)
                    HStack(spacing: 0) {
                        miniStat("Slept", app.lastNight.durationText, "bed.double.fill")
                        divider
                        miniStat("Quality", "\(app.lastNight.quality)%", "sparkles")
                        divider
                        miniStat("Snore", "\(app.lastNight.snoringMinutes)m", "wind")
                    }
                }
            }

            coachCard
            dreamSummaryCard
            recommendationCard
        }
    }

    private var coachCard: some View {
        Button { selectedTab = .sleep } label: {
            GlassCard {
                VStack(alignment: .leading, spacing: 10) {
                    Label("AI Sleep Coach", systemImage: "brain.head.profile")
                        .font(.headline)
                        .foregroundStyle(palette.primaryText)
                    Text(SleepCoach.summary(for: app.lastNight, averageScore: app.averageScore))
                        .font(.subheadline)
                        .foregroundStyle(palette.secondaryText)
                        .multilineTextAlignment(.leading)
                    HStack {
                        Spacer()
                        Text("See full report")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(palette.accent)
                        Image(systemName: "chevron.right").font(.caption2).foregroundStyle(palette.accent)
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var dreamSummaryCard: some View {
        Button { selectedTab = .dreams } label: {
            GlassCard {
                VStack(alignment: .leading, spacing: 10) {
                    Label("Last Dream", systemImage: "cloud.moon.fill")
                        .font(.headline)
                        .foregroundStyle(palette.primaryText)
                    if let dream = app.dreams.first {
                        Text(dream.text)
                            .font(.subheadline)
                            .foregroundStyle(palette.secondaryText)
                            .lineLimit(2)
                        HStack(spacing: 8) {
                            ForEach(dream.themes.prefix(3), id: \.self) { theme in
                                Text(theme)
                                    .font(.caption2.weight(.medium))
                                    .padding(.horizontal, 10).padding(.vertical, 5)
                                    .background(Capsule().fill(palette.accent.opacity(0.18)))
                                    .foregroundStyle(palette.primaryText)
                            }
                        }
                    } else {
                        Text("No dream recorded yet.")
                            .font(.subheadline).foregroundStyle(palette.secondaryText)
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var recommendationCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                Label("Today's Focus", systemImage: "target")
                    .font(.headline).foregroundStyle(palette.primaryText)
                Text(SleepCoach.recommendation(for: app.lastNight))
                    .font(.subheadline).foregroundStyle(palette.secondaryText)
            }
        }
    }

    // MARK: - Afternoon

    private var afternoonContent: some View {
        VStack(spacing: 18) {
            GlassCard {
                VStack(alignment: .leading, spacing: 14) {
                    SectionLabel(text: "Tonight's bedtime")
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(app.recommendedBedtime)
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundStyle(palette.primaryText)
                        Image(systemName: "bed.double.fill").foregroundStyle(palette.accent)
                    }
                    Text("For \(Int(app.desiredSleepHours))h of sleep before your \(wakeTimeText) alarm.")
                        .font(.subheadline).foregroundStyle(palette.secondaryText)
                }
            }
            HStack(spacing: 14) {
                infoTile("Sleep Debt", String(format: "%.1fh", app.sleepDebtHours), "moon.zzz.fill")
                infoTile("Next Alarm", app.nextAlarm?.timeText ?? "—", "alarm.fill")
            }
            GlassCard {
                VStack(spacing: 14) {
                    reminderRow("drop.fill", "Hydration", "Aim for 2 more glasses of water")
                    Divider().background(palette.primaryText.opacity(0.1))
                    reminderRow("cup.and.saucer.fill", "Caffeine cutoff", "Last coffee by 2:00 PM")
                }
            }
        }
    }

    // MARK: - Evening

    private var eveningContent: some View {
        VStack(spacing: 18) {
            PrimaryActionButton(title: "Begin Wind Down", icon: "moon.fill", fill: palette.accent) {
                showGoodnight = true
            }
            HStack(spacing: 14) {
                actionTile("Meditation", "figure.mind.and.body") { selectedTab = .sounds }
                actionTile("Sleep Sounds", "waveform") { selectedTab = .sounds }
            }
            GlassCard {
                VStack(alignment: .leading, spacing: 12) {
                    SectionLabel(text: "Tonight's schedule")
                    scheduleRow("Wind down", app.windDownTime, "moon.haze.fill")
                    scheduleRow("Bedtime", app.recommendedBedtime, "bed.double.fill")
                    scheduleRow("Wake", app.nextAlarm?.timeText ?? wakeTimeText, "alarm.fill")
                }
            }
            GlassCard {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Relaxation tip", systemImage: "lightbulb.fill")
                        .font(.headline).foregroundStyle(palette.primaryText)
                    Text("Try the 4-7-8 breath: inhale for 4, hold for 7, exhale for 8. Three rounds quiets a busy mind.")
                        .font(.subheadline).foregroundStyle(palette.secondaryText)
                }
            }
        }
    }

    // MARK: - Night

    private var nightContent: some View {
        VStack(spacing: 20) {
            GlassCard {
                VStack(spacing: 14) {
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(palette.accent)
                    Text(sound.isPlaying ? currentSoundName : "Ready when you are")
                        .font(.headline).foregroundStyle(palette.primaryText)
                    if sound.isTimerRunning {
                        Text("Timer • \(sound.timerText)")
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(palette.secondaryText)
                    }
                    HStack(spacing: 8) {
                        Circle().fill(Color.green).frame(width: 8, height: 8)
                        Text("Sleep tracking armed")
                            .font(.caption).foregroundStyle(palette.secondaryText)
                    }
                }
                .frame(maxWidth: .infinity)
            }

            FlashlightButton()

            PrimaryActionButton(title: "Goodnight", icon: "moon.zzz.fill", fill: palette.accent) {
                showGoodnight = true
            }
        }
    }

    private var currentSoundName: String {
        sound.layers.compactMap { SleepSound.find($0.id)?.name }.joined(separator: " + ")
    }

    // MARK: - Reusable bits

    private var divider: some View {
        Rectangle().fill(palette.primaryText.opacity(0.12)).frame(width: 1, height: 36)
    }

    private func miniStat(_ title: String, _ value: String, _ icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon).font(.subheadline).foregroundStyle(palette.accent)
            Text(value).font(.headline).foregroundStyle(palette.primaryText)
            Text(title).font(.caption2).foregroundStyle(palette.secondaryText)
        }
        .frame(maxWidth: .infinity)
    }

    private func infoTile(_ title: String, _ value: String, _ icon: String) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: icon).foregroundStyle(palette.accent)
                Text(value).font(.title2.weight(.bold)).foregroundStyle(palette.primaryText)
                Text(title).font(.caption).foregroundStyle(palette.secondaryText)
            }
        }
    }

    private func actionTile(_ title: String, _ icon: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            GlassCard {
                VStack(alignment: .leading, spacing: 10) {
                    Image(systemName: icon).font(.title2).foregroundStyle(palette.accent)
                    Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(palette.primaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .buttonStyle(.plain)
    }

    private func reminderRow(_ icon: String, _ title: String, _ detail: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon).font(.title3).foregroundStyle(palette.accent).frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(palette.primaryText)
                Text(detail).font(.caption).foregroundStyle(palette.secondaryText)
            }
            Spacer()
        }
    }

    private func scheduleRow(_ title: String, _ time: String, _ icon: String) -> some View {
        HStack {
            Label(title, systemImage: icon)
                .font(.subheadline).foregroundStyle(palette.primaryText)
            Spacer()
            Text(time).font(.subheadline.weight(.semibold)).foregroundStyle(palette.accent)
        }
    }

    private var wakeTimeText: String {
        let f = DateFormatter(); f.dateFormat = "h:mm a"
        var c = DateComponents(); c.hour = app.desiredWakeHour; c.minute = app.desiredWakeMinute
        return f.string(from: Calendar.current.date(from: c) ?? Date())
    }
}

/// Toggleable torch button for the night home screen.
struct FlashlightButton: View {
    @State private var on = false
    @Environment(\.palette) private var palette

    var body: some View {
        Button {
            on.toggle()
            Flashlight.toggle(on: on)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: on ? "flashlight.on.fill" : "flashlight.off.fill")
                Text(on ? "Flashlight On" : "Emergency Flashlight")
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(on ? .yellow : palette.primaryText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .wakeGlass(cornerRadius: 18)
        }
        .buttonStyle(.plain)
    }
}
