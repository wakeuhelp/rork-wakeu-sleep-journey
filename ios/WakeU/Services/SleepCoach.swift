//
//  SleepCoach.swift
//  WakeU
//

import Foundation

/// Generates friendly, encouraging sleep coaching copy from a session.
/// Rule-based and fully on-device — never guilt-inducing.
enum SleepCoach {
    struct Insight: Identifiable {
        let id = UUID()
        let symbol: String
        let text: String
    }

    static func summary(for session: SleepSession, averageScore: Int) -> String {
        let h = session.durationMinutes / 60
        let m = session.durationMinutes % 60
        var lines: [String] = []
        lines.append("You slept \(h) hours \(m) minutes — sleep quality \(session.quality)%.")

        if session.score >= averageScore {
            lines.append("That's right in line with your recent average. Lovely consistency. ✨")
        } else {
            lines.append("A little below your usual rhythm — completely normal, tonight is a fresh start.")
        }

        if session.snoringMinutes > 0 {
            lines.append("You snored for about \(session.snoringMinutes) minutes, mostly in the early hours.")
        }

        if session.interruptions <= 1 {
            lines.append("Barely any interruptions — your body rested deeply.")
        } else {
            lines.append("There were \(session.interruptions) brief stirs overnight.")
        }

        return lines.joined(separator: " ")
    }

    static func recommendation(for session: SleepSession) -> String {
        if session.score >= 85 {
            return "Keep doing what you're doing — try to be in bed around 10:45 PM tonight to protect this streak."
        } else if session.durationMinutes < 420 {
            return "Aim to wind down 30 minutes earlier tonight. A target bedtime before 10:45 PM should help you feel more refreshed."
        } else {
            return "Try a calmer pre-sleep routine tonight — dim sounds and screens. Bed by 10:45 PM is a good goal."
        }
    }

    static func insights(for session: SleepSession) -> [Insight] {
        [
            Insight(symbol: "bed.double.fill", text: "Bedtime was 42 min later than usual"),
            Insight(symbol: "wind", text: session.snoringMinutes > 0 ? "Snored \(session.snoringMinutes) min — try side sleeping" : "No snoring detected"),
            Insight(symbol: "drop.fill", text: "Hydration looked good before bed"),
            Insight(symbol: "cup.and.saucer.fill", text: "Caffeine cutoff: aim for 2 PM"),
        ]
    }
}
