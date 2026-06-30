//
//  SleepModels.swift
//  WakeU
//

import Foundation
import SwiftUI

/// A single significant event detected during a night of sleep.
struct SleepEvent: Identifiable, Hashable {
    enum Kind: String {
        case lightsOut, asleep, talking, snoring, movement, lightSleep, deepSleep, awake, alarm

        var label: String {
            switch self {
            case .lightsOut: return "Lights Out"
            case .asleep: return "Estimated Asleep"
            case .talking: return "Talking Detected"
            case .snoring: return "Snoring"
            case .movement: return "Movement"
            case .lightSleep: return "Light Sleep"
            case .deepSleep: return "Deep Sleep"
            case .awake: return "Awake"
            case .alarm: return "Alarm"
            }
        }

        var symbol: String {
            switch self {
            case .lightsOut: return "moon.fill"
            case .asleep: return "zzz"
            case .talking: return "waveform"
            case .snoring: return "wind"
            case .movement: return "figure.walk.motion"
            case .lightSleep: return "moon.zzz.fill"
            case .deepSleep: return "moon.stars.fill"
            case .awake: return "eye.fill"
            case .alarm: return "alarm.fill"
            }
        }

        var color: Color {
            switch self {
            case .lightsOut: return Color(red: 0.6, green: 0.6, blue: 0.9)
            case .asleep: return Color(red: 0.5, green: 0.8, blue: 0.95)
            case .talking: return Color(red: 0.95, green: 0.7, blue: 0.4)
            case .snoring: return Color(red: 0.95, green: 0.55, blue: 0.5)
            case .movement: return Color(red: 0.9, green: 0.65, blue: 0.85)
            case .lightSleep: return Color(red: 0.55, green: 0.75, blue: 0.95)
            case .deepSleep: return Color(red: 0.4, green: 0.5, blue: 0.9)
            case .awake: return Color(red: 0.98, green: 0.6, blue: 0.45)
            case .alarm: return Color(red: 0.45, green: 0.85, blue: 0.7)
            }
        }
    }

    let id = UUID()
    let time: String
    let kind: Kind
}

/// A completed (or in-progress) night of sleep.
struct SleepSession: Identifiable, Hashable {
    let id = UUID()
    let date: Date
    /// Minutes asleep.
    let durationMinutes: Int
    let bedtime: String
    let wakeTime: String
    let score: Int
    /// 0–100 quality estimate.
    let quality: Int
    let snoringMinutes: Int
    let interruptions: Int
    let events: [SleepEvent]

    var durationText: String {
        let h = durationMinutes / 60
        let m = durationMinutes % 60
        return "\(h)h \(m)m"
    }
}

/// A weekday data point for charts.
struct SleepTrendPoint: Identifiable, Hashable {
    let id = UUID()
    let label: String
    let date: Date
    let score: Int
    let durationHours: Double
    let bedtimeHour: Double
}
