//
//  AlarmsView.swift
//  WakeU
//

import SwiftUI

struct AlarmsView: View {
    @Environment(AppState.self) private var app
    @State private var editing: WakeAlarm?
    @State private var showEditor = false

    private var palette: WakePalette { app.palette }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                smartBedtimeCard

                SectionLabel(text: "Alarms")
                ForEach(app.alarms) { alarm in
                    AlarmRow(alarm: alarm) {
                        editing = alarm; showEditor = true
                    } onToggle: { enabled in
                        var copy = alarm; copy.isEnabled = enabled
                        app.updateAlarm(copy)
                    }
                    .environment(\.palette, palette)
                }

                Color.clear.frame(height: 90)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
        .scrollIndicators(.hidden)
        .environment(\.palette, palette)
        .overlay(alignment: .bottomTrailing) {
            Button {
                editing = nil; showEditor = true
            } label: {
                Image(systemName: "plus")
                    .font(.title2.weight(.semibold)).foregroundStyle(.white)
                    .frame(width: 60, height: 60)
                    .background(Circle().fill(palette.accent).shadow(color: palette.accent.opacity(0.5), radius: 12, y: 4))
            }
            .padding(.trailing, 24).padding(.bottom, 100)
        }
        .sheet(isPresented: $showEditor) {
            AlarmEditorView(alarm: editing).environment(app)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Alarms")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(palette.primaryText)
            Text("Wake gently, on your terms")
                .font(.subheadline).foregroundStyle(palette.secondaryText)
        }
        .padding(.top, 4)
    }

    private var smartBedtimeCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                Label("Smart Bedtime", systemImage: "wand.and.stars")
                    .font(.headline).foregroundStyle(palette.primaryText)

                HStack {
                    Text("Wake at")
                        .foregroundStyle(palette.secondaryText)
                    Spacer()
                    DatePicker("", selection: wakeBinding, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .colorScheme(.dark)
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Hours of sleep").foregroundStyle(palette.secondaryText)
                        Spacer()
                        Text(String(format: "%.1f h", app.desiredSleepHours))
                            .foregroundStyle(palette.primaryText).fontWeight(.semibold)
                    }
                    Slider(value: bindingSleepHours, in: 5...10, step: 0.5).tint(palette.accent)
                }

                Divider().background(palette.primaryText.opacity(0.12))
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Ideal bedtime").font(.caption).foregroundStyle(palette.secondaryText)
                        Text(app.recommendedBedtime).font(.title3.weight(.bold)).foregroundStyle(palette.accent)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Wind down at").font(.caption).foregroundStyle(palette.secondaryText)
                        Text(app.windDownTime).font(.title3.weight(.bold)).foregroundStyle(palette.primaryText)
                    }
                }
            }
        }
    }

    private var wakeBinding: Binding<Date> {
        Binding(
            get: {
                var c = DateComponents(); c.hour = app.desiredWakeHour; c.minute = app.desiredWakeMinute
                return Calendar.current.date(from: c) ?? Date()
            },
            set: { newValue in
                let c = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                app.desiredWakeHour = c.hour ?? 7
                app.desiredWakeMinute = c.minute ?? 0
            }
        )
    }

    private var bindingSleepHours: Binding<Double> {
        Binding(get: { app.desiredSleepHours }, set: { app.desiredSleepHours = $0 })
    }
}

struct AlarmRow: View {
    let alarm: WakeAlarm
    let onTap: () -> Void
    let onToggle: (Bool) -> Void
    @Environment(\.palette) private var palette

    var body: some View {
        Button(action: onTap) {
            GlassCard {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(alarm.timeText)
                            .font(.system(size: 30, weight: .semibold, design: .rounded))
                            .foregroundStyle(alarm.isEnabled ? palette.primaryText : palette.secondaryText)
                        HStack(spacing: 8) {
                            Text(alarm.label).font(.caption).foregroundStyle(palette.secondaryText)
                            Text("• \(alarm.repeatText)").font(.caption).foregroundStyle(palette.secondaryText)
                        }
                        HStack(spacing: 8) {
                            if alarm.sunriseEnabled {
                                tag("sunrise.fill", "Sunrise")
                            }
                            if let c = WakeChallenge.find(alarm.challengeID) {
                                tag(c.symbol, c.name)
                            }
                        }
                    }
                    Spacer()
                    Toggle("", isOn: Binding(get: { alarm.isEnabled }, set: { onToggle($0) }))
                        .labelsHidden()
                        .tint(palette.accent)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func tag(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 9))
            Text(text).font(.system(size: 10, weight: .medium))
        }
        .padding(.horizontal, 8).padding(.vertical, 4)
        .background(Capsule().fill(palette.accent.opacity(0.16)))
        .foregroundStyle(palette.primaryText)
    }
}
