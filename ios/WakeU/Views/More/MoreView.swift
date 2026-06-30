//
//  MoreView.swift
//  WakeU
//

import SwiftUI

struct MoreView: View {
    @Environment(AppState.self) private var app
    @State private var showPaywall = false

    private var palette: WakePalette { app.palette }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header

                if !app.isPremium {
                    premiumCard
                } else {
                    activePremiumCard
                }

                SectionLabel(text: "Tools")
                NavigationLink {
                    HearingTestView().environment(app)
                } label: {
                    settingRow("ear.fill", "Hearing Test", "Find your hearing range")
                }
                .buttonStyle(.plain)

                SectionLabel(text: "Apple Ecosystem")
                VStack(spacing: 0) {
                    ecoRow("applewatch", "Apple Watch", true)
                    eDivider
                    ecoRow("heart.fill", "HealthKit Sync", true)
                    eDivider
                    ecoRow("moon.fill", "Sleep Focus", true)
                    eDivider
                    ecoRow("mic.fill", "Siri & Shortcuts", true)
                    eDivider
                    ecoRow("rectangle.3.group.fill", "Widgets & Live Activities", true)
                }
                .padding(16)
                .wakeGlass(cornerRadius: 22)

                SectionLabel(text: "Preferences")
                VStack(spacing: 0) {
                    toggleRow("bell.badge.fill", "Supportive Notifications")
                    eDivider
                    toggleRow("waveform.path.ecg", "Sleep Tracking")
                    eDivider
                    toggleRow("hand.raised.fill", "Reduce Motion")
                    eDivider
                    toggleRow("textformat.size", "Larger Text")
                }
                .padding(16)
                .wakeGlass(cornerRadius: 22)

                Text("wakeU • Your complete sleep journey\nPrivacy-first · On-device by design")
                    .font(.caption2)
                    .foregroundStyle(palette.secondaryText)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)

                Color.clear.frame(height: 90)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
        .scrollIndicators(.hidden)
        .environment(\.palette, palette)
        .sheet(isPresented: $showPaywall) { PaywallView().environment(app) }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("More")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(palette.primaryText)
        }
        .padding(.top, 4)
    }

    private var premiumCard: some View {
        Button { showPaywall = true } label: {
            GlassCard {
                HStack(spacing: 14) {
                    Image(systemName: "moon.stars.circle.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(LinearGradient(colors: [.yellow, palette.accent], startPoint: .top, endPoint: .bottom))
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Upgrade to Premium")
                            .font(.headline).foregroundStyle(palette.primaryText)
                        Text("AI coach, unlimited sounds, stories & more")
                            .font(.caption).foregroundStyle(palette.secondaryText)
                    }
                    Spacer()
                    Image(systemName: "chevron.right").foregroundStyle(palette.secondaryText)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var activePremiumCard: some View {
        GlassCard {
            HStack(spacing: 14) {
                Image(systemName: "checkmark.seal.fill").font(.title).foregroundStyle(.green)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Premium active").font(.headline).foregroundStyle(palette.primaryText)
                    Text("Thanks for supporting wakeU ✨").font(.caption).foregroundStyle(palette.secondaryText)
                }
                Spacer()
            }
        }
    }

    private var eDivider: some View { Divider().background(palette.primaryText.opacity(0.1)).padding(.vertical, 4) }

    private func settingRow(_ icon: String, _ title: String, _ subtitle: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon).font(.title3).foregroundStyle(palette.accent).frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(palette.primaryText)
                Text(subtitle).font(.caption).foregroundStyle(palette.secondaryText)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.caption).foregroundStyle(palette.secondaryText)
        }
        .padding(16)
        .wakeGlass(cornerRadius: 18)
    }

    private func ecoRow(_ icon: String, _ title: String, _ connected: Bool) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon).foregroundStyle(palette.accent).frame(width: 26)
            Text(title).font(.subheadline).foregroundStyle(palette.primaryText)
            Spacer()
            Text(connected ? "Ready" : "Off")
                .font(.caption.weight(.medium))
                .foregroundStyle(connected ? .green : palette.secondaryText)
        }
        .padding(.vertical, 6)
    }

    private func toggleRow(_ icon: String, _ title: String) -> some View {
        ToggleRowView(icon: icon, title: title).environment(\.palette, palette)
    }
}

private struct ToggleRowView: View {
    let icon: String
    let title: String
    @State private var on = true
    @Environment(\.palette) private var palette

    var body: some View {
        Toggle(isOn: $on) {
            Label {
                Text(title).font(.subheadline).foregroundStyle(palette.primaryText)
            } icon: {
                Image(systemName: icon).foregroundStyle(palette.accent)
            }
        }
        .tint(palette.accent)
        .padding(.vertical, 4)
    }
}
