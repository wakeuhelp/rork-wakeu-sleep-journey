//
//  TimeOfDay.swift
//  WakeU
//

import SwiftUI

/// The four phases of the day that drive wakeU's adaptive palette and home layout.
enum TimeOfDay: String, CaseIterable, Identifiable {
    case morning
    case afternoon
    case evening
    case night

    var id: String { rawValue }

    /// Resolves the time of day from a given hour (0–23).
    static func current(date: Date = Date(), calendar: Calendar = .current) -> TimeOfDay {
        let hour = calendar.component(.hour, from: date)
        switch hour {
        case 5..<11: return .morning
        case 11..<17: return .afternoon
        case 17..<21: return .evening
        default: return .night
        }
    }

    var greeting: String {
        switch self {
        case .morning: return "Good Morning"
        case .afternoon: return "Good Afternoon"
        case .evening: return "Good Evening"
        case .night: return "Good Night"
        }
    }

    var symbol: String {
        switch self {
        case .morning: return "sunrise.fill"
        case .afternoon: return "sun.max.fill"
        case .evening: return "sunset.fill"
        case .night: return "moon.stars.fill"
        }
    }

    var subtitle: String {
        switch self {
        case .morning: return "Here's how you slept"
        case .afternoon: return "Plan tonight's rest"
        case .evening: return "Time to unwind"
        case .night: return "Drift off gently"
        }
    }
}
