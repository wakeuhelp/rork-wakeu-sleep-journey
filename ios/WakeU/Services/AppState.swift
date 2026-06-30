//
//  AppState.swift
//  WakeU
//

import SwiftUI
import Observation

/// Central, observable source of truth for wakeU. Holds the user's sleep history,
/// dreams, alarms, sound prefs and subscription state, plus the live time-of-day.
@MainActor
@Observable
final class AppState {
    // Time of day drives the entire palette + home layout.
    var timeOfDay: TimeOfDay = TimeOfDay.current()

    // Subscription
    var isPremium: Bool = false

    // Sleep data
    var lastNight: SleepSession
    var history: [SleepTrendPoint]
    var sleepDebtHours: Double = 1.4

    // Dreams
    var dreams: [DreamEntry]

    // Alarms
    var alarms: [WakeAlarm]

    // Sounds
    var favoriteSoundIDs: Set<String> = ["rain", "ocean"]
    var selectedChallengeID: String = "math"

    // Hearing
    var hearingProfiles: [HearingProfile]

    // Smart bedtime
    var desiredWakeHour: Int = 7
    var desiredWakeMinute: Int = 0
    var desiredSleepHours: Double = 8.0

    var palette: WakePalette { .palette(for: timeOfDay) }

    init() {
        let cal = Calendar.current
        let now = Date()

        // --- Last night ---
        lastNight = SleepSession(
            date: cal.date(byAdding: .day, value: -1, to: now) ?? now,
            durationMinutes: 466,
            bedtime: "10:46 PM",
            wakeTime: "7:00 AM",
            score: 88,
            quality: 88,
            snoringMinutes: 8,
            interruptions: 2,
            events: [
                SleepEvent(time: "10:46 PM", kind: .lightsOut),
                SleepEvent(time: "11:02 PM", kind: .asleep),
                SleepEvent(time: "12:20 AM", kind: .deepSleep),
                SleepEvent(time: "1:11 AM", kind: .talking),
                SleepEvent(time: "2:30 AM", kind: .lightSleep),
                SleepEvent(time: "3:44 AM", kind: .snoring),
                SleepEvent(time: "5:10 AM", kind: .movement),
                SleepEvent(time: "6:52 AM", kind: .lightSleep),
                SleepEvent(time: "7:00 AM", kind: .alarm),
            ]
        )

        // --- 7 day history ---
        let scores = [74, 81, 69, 88, 92, 79, 88]
        let durations = [6.8, 7.4, 6.1, 7.8, 8.2, 7.0, 7.8]
        let bedtimes = [23.1, 22.8, 23.6, 22.7, 22.4, 23.2, 22.8]
        let weekdayLabels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        history = (0..<7).map { i in
            SleepTrendPoint(
                label: weekdayLabels[i],
                date: cal.date(byAdding: .day, value: i - 6, to: now) ?? now,
                score: scores[i],
                durationHours: durations[i],
                bedtimeHour: bedtimes[i]
            )
        }

        // --- Dreams ---
        dreams = [
            DreamEntry(
                date: cal.date(byAdding: .day, value: -1, to: now) ?? now,
                text: "I was floating above a quiet city at night. The streets were made of water and I could breathe underwater. I kept searching for a door that glowed softly.",
                mood: .strange,
                themes: ["Flying", "Searching", "Water"],
                symbols: ["Door", "City", "Light"],
                interpretation: "Floating and water often appear when the mind is processing change. The glowing door may reflect a choice you're weighing. Just for fun — your dream-self seems curious and ready to explore something new. (Interpretations are playful, not factual.)"
            ),
            DreamEntry(
                date: cal.date(byAdding: .day, value: -3, to: now) ?? now,
                text: "Walking through a forest with someone I trust. Sunlight everywhere, very calm.",
                mood: .peaceful,
                themes: ["Nature", "Companionship"],
                symbols: ["Forest", "Sunlight"],
                interpretation: "Forests and warm light tend to show up on restful nights. A lovely, grounded dream. (For entertainment only.)"
            ),
        ]

        // --- Alarms ---
        alarms = [
            WakeAlarm(hour: 7, minute: 0, label: "Wake Up", isEnabled: true, repeatDays: [2, 3, 4, 5, 6], soundID: "rain", challengeID: "math"),
            WakeAlarm(hour: 8, minute: 30, label: "Weekend", isEnabled: false, repeatDays: [1, 7], soundID: "ocean", challengeID: "shake"),
        ]

        // --- Hearing ---
        hearingProfiles = [
            HearingProfile(name: "You", maxFrequency: 16500),
        ]
    }

    // MARK: - Derived helpers

    var nextAlarm: WakeAlarm? {
        alarms.filter { $0.isEnabled }.min { ($0.hour * 60 + $0.minute) < ($1.hour * 60 + $1.minute) }
    }

    var averageScore: Int {
        guard !history.isEmpty else { return 0 }
        return history.map(\.score).reduce(0, +) / history.count
    }

    /// Smart bedtime recommendation derived from desired wake time + sleep need
    /// plus an estimated 14 minutes to fall asleep.
    var recommendedBedtime: String {
        let fallAsleep = 14
        let totalMinutes = Int(desiredSleepHours * 60) + fallAsleep
        var comps = DateComponents()
        comps.hour = desiredWakeHour
        comps.minute = desiredWakeMinute
        let cal = Calendar.current
        let wake = cal.date(from: comps) ?? Date()
        let bed = cal.date(byAdding: .minute, value: -totalMinutes, to: wake) ?? wake
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f.string(from: bed)
    }

    var windDownTime: String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        var comps = DateComponents()
        comps.hour = desiredWakeHour
        comps.minute = desiredWakeMinute
        let cal = Calendar.current
        let wake = cal.date(from: comps) ?? Date()
        let totalMinutes = Int(desiredSleepHours * 60) + 14 + 30
        let wd = cal.date(byAdding: .minute, value: -totalMinutes, to: wake) ?? wake
        return f.string(from: wd)
    }

    // MARK: - Mutations

    func toggleFavorite(_ id: String) {
        if favoriteSoundIDs.contains(id) { favoriteSoundIDs.remove(id) }
        else { favoriteSoundIDs.insert(id) }
    }

    func addDream(_ entry: DreamEntry) {
        dreams.insert(entry, at: 0)
    }

    func addAlarm(_ alarm: WakeAlarm) {
        alarms.append(alarm)
    }

    func updateAlarm(_ alarm: WakeAlarm) {
        if let idx = alarms.firstIndex(where: { $0.id == alarm.id }) {
            alarms[idx] = alarm
        }
    }

    func deleteAlarm(_ alarm: WakeAlarm) {
        alarms.removeAll { $0.id == alarm.id }
    }

    func saveHearingProfile(_ profile: HearingProfile) {
        if let idx = hearingProfiles.firstIndex(where: { $0.id == profile.id }) {
            hearingProfiles[idx] = profile
        } else {
            hearingProfiles.append(profile)
        }
    }

    func refreshTimeOfDay() {
        let resolved = TimeOfDay.current()
        if resolved != timeOfDay {
            withAnimation(.easeInOut(duration: 1.4)) { timeOfDay = resolved }
        }
    }
}
