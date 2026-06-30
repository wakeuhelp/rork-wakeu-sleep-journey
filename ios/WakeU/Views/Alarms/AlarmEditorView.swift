//
//  AlarmEditorView.swift
//  WakeU
//

import SwiftUI

struct AlarmEditorView: View {
    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss

    let alarm: WakeAlarm?
    @State private var time: Date
    @State private var label: String
    @State private var repeatDays: Set<Int>
    @State private var soundID: String
    @State private var sunrise: Bool
    @State private var smartVolume: Bool
    @State private var challengeID: String
    @State private var showChallengePicker = false

    private let palette = WakePalette.palette(for: .night)
    private let dayNames = ["S", "M", "T", "W", "T", "F", "S"]

    init(alarm: WakeAlarm?) {
        self.alarm = alarm
        var c = DateComponents()
        c.hour = alarm?.hour ?? 7
        c.minute = alarm?.minute ?? 0
        _time = State(initialValue: Calendar.current.date(from: c) ?? Date())
        _label = State(initialValue: alarm?.label ?? "Wake Up")
        _repeatDays = State(initialValue: alarm?.repeatDays ?? [])
        _soundID = State(initialValue: alarm?.soundID ?? "rain")
        _sunrise = State(initialValue: alarm?.sunriseEnabled ?? true)
        _smartVolume = State(initialValue: alarm?.smartVolume ?? true)
        _challengeID = State(initialValue: alarm?.challengeID ?? "math")
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedBackground(palette: palette)
                ScrollView {
                    VStack(spacing: 18) {
                        DatePicker("", selection: $time, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                            .colorScheme(.dark)
                            .padding(.vertical, 4)

                        GlassCard {
                            VStack(alignment: .leading, spacing: 14) {
                                HStack {
                                    Text("Label").foregroundStyle(palette.secondaryText)
                                    Spacer()
                                    TextField("Label", text: $label)
                                        .multilineTextAlignment(.trailing)
                                        .foregroundStyle(palette.primaryText)
                                }
                                Divider().background(palette.primaryText.opacity(0.12))
                                Text("Repeat").foregroundStyle(palette.secondaryText)
                                HStack(spacing: 8) {
                                    ForEach(1...7, id: \.self) { day in
                                        Button {
                                            if repeatDays.contains(day) { repeatDays.remove(day) }
                                            else { repeatDays.insert(day) }
                                        } label: {
                                            Text(dayNames[day - 1])
                                                .font(.subheadline.weight(.semibold))
                                                .frame(width: 38, height: 38)
                                                .background(Circle().fill(repeatDays.contains(day) ? palette.accent : palette.primaryText.opacity(0.1)))
                                                .foregroundStyle(repeatDays.contains(day) ? .white : palette.primaryText)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                        .environment(\.palette, palette)

                        GlassCard {
                            VStack(spacing: 4) {
                                Toggle(isOn: $sunrise) {
                                    Label("Sunrise alarm", systemImage: "sunrise.fill").foregroundStyle(palette.primaryText)
                                }.tint(palette.accent)
                                Divider().background(palette.primaryText.opacity(0.12))
                                Toggle(isOn: $smartVolume) {
                                    Label("Smart volume increase", systemImage: "speaker.wave.3.fill").foregroundStyle(palette.primaryText)
                                }.tint(palette.accent)
                            }
                        }

                        Button { showChallengePicker = true } label: {
                            GlassCard {
                                HStack {
                                    Label("Wake Challenge", systemImage: "puzzlepiece.fill")
                                        .foregroundStyle(palette.primaryText)
                                    Spacer()
                                    Text(WakeChallenge.find(challengeID)?.name ?? "None")
                                        .foregroundStyle(palette.accent)
                                    Image(systemName: "chevron.right").font(.caption).foregroundStyle(palette.secondaryText)
                                }
                            }
                        }
                        .buttonStyle(.plain)

                        if alarm != nil {
                            Button(role: .destructive) {
                                if let alarm { app.deleteAlarm(alarm) }
                                dismiss()
                            } label: {
                                Text("Delete Alarm").frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(.red)
                            .padding(.vertical, 14)
                            .wakeGlass(cornerRadius: 18)
                        }
                        Color.clear.frame(height: 20)
                    }
                    .padding(20)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle(alarm == nil ? "New Alarm" : "Edit Alarm")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundStyle(palette.accent)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }.foregroundStyle(palette.accent).fontWeight(.semibold)
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showChallengePicker) {
                ChallengePickerView(selected: $challengeID).environment(app)
            }
        }
        .preferredColorScheme(.dark)
    }

    private func save() {
        let c = Calendar.current.dateComponents([.hour, .minute], from: time)
        var updated = alarm ?? WakeAlarm(hour: 7, minute: 0, label: "Wake Up", isEnabled: true)
        updated.hour = c.hour ?? 7
        updated.minute = c.minute ?? 0
        updated.label = label
        updated.repeatDays = repeatDays
        updated.soundID = soundID
        updated.sunriseEnabled = sunrise
        updated.smartVolume = smartVolume
        updated.challengeID = challengeID
        updated.isEnabled = true
        if alarm == nil { app.addAlarm(updated) } else { app.updateAlarm(updated) }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        dismiss()
    }
}

struct ChallengePickerView: View {
    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss
    @Binding var selected: String
    @State private var testing: WakeChallenge?

    private let palette = WakePalette.palette(for: .night)

    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedBackground(palette: palette)
                ScrollView {
                    VStack(spacing: 12) {
                        Text("Tap a challenge to select it, or test it first.")
                            .font(.subheadline).foregroundStyle(palette.secondaryText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        ForEach(WakeChallenge.all) { challenge in
                            let locked = challenge.isPremium && !app.isPremium
                            HStack(spacing: 14) {
                                Image(systemName: locked ? "lock.fill" : challenge.symbol)
                                    .font(.title3).foregroundStyle(palette.accent).frame(width: 32)
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 6) {
                                        Text(challenge.name).font(.subheadline.weight(.semibold)).foregroundStyle(palette.primaryText)
                                        if locked { PremiumBadge() }
                                    }
                                    Text(challenge.detail).font(.caption).foregroundStyle(palette.secondaryText)
                                }
                                Spacer()
                                Button("Test") { testing = challenge }
                                    .font(.caption.weight(.semibold))
                                    .padding(.horizontal, 12).padding(.vertical, 6)
                                    .background(Capsule().fill(palette.accent.opacity(0.18)))
                                    .foregroundStyle(palette.accent)
                                    .buttonStyle(.plain)
                                if selected == challenge.id {
                                    Image(systemName: "checkmark.circle.fill").foregroundStyle(palette.accent)
                                }
                            }
                            .padding(16)
                            .wakeGlass(cornerRadius: 18)
                            .opacity(locked ? 0.6 : 1)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if !locked { selected = challenge.id; dismiss() }
                            }
                        }
                    }
                    .padding(20)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Wake Challenge")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.foregroundStyle(palette.accent)
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
            .fullScreenCover(item: $testing) { challenge in
                WakeChallengeView(challenge: challenge, isTest: true)
            }
        }
        .preferredColorScheme(.dark)
    }
}
