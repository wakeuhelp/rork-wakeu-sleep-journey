//
//  ContentModels.swift
//  WakeU
//

import Foundation
import SwiftUI

// MARK: - Sleep Sounds

struct SleepSound: Identifiable, Hashable {
    enum Texture {
        case white, pink, brown, rain, ocean, forest, fireplace, fan, thunder, meditation, ambient, lofi
    }

    let id: String
    let name: String
    let symbol: String
    let texture: Texture
    let isPremium: Bool
    let tint: Color

    static let all: [SleepSound] = [
        SleepSound(id: "rain", name: "Rain", symbol: "cloud.rain.fill", texture: .rain, isPremium: false, tint: Color(red: 0.5, green: 0.7, blue: 0.95)),
        SleepSound(id: "ocean", name: "Ocean", symbol: "water.waves", texture: .ocean, isPremium: false, tint: Color(red: 0.35, green: 0.72, blue: 0.85)),
        SleepSound(id: "forest", name: "Forest", symbol: "tree.fill", texture: .forest, isPremium: false, tint: Color(red: 0.45, green: 0.78, blue: 0.55)),
        SleepSound(id: "fireplace", name: "Fireplace", symbol: "flame.fill", texture: .fireplace, isPremium: true, tint: Color(red: 0.95, green: 0.55, blue: 0.35)),
        SleepSound(id: "fan", name: "Fan", symbol: "fanblades.fill", texture: .fan, isPremium: false, tint: Color(red: 0.6, green: 0.66, blue: 0.78)),
        SleepSound(id: "brown", name: "Brown Noise", symbol: "waveform.path", texture: .brown, isPremium: false, tint: Color(red: 0.7, green: 0.55, blue: 0.42)),
        SleepSound(id: "white", name: "White Noise", symbol: "waveform", texture: .white, isPremium: false, tint: Color(red: 0.8, green: 0.82, blue: 0.88)),
        SleepSound(id: "pink", name: "Pink Noise", symbol: "waveform.path.ecg", texture: .pink, isPremium: true, tint: Color(red: 0.92, green: 0.6, blue: 0.74)),
        SleepSound(id: "thunder", name: "Thunderstorm", symbol: "cloud.bolt.rain.fill", texture: .thunder, isPremium: true, tint: Color(red: 0.55, green: 0.58, blue: 0.8)),
        SleepSound(id: "meditation", name: "Meditation", symbol: "figure.mind.and.body", texture: .meditation, isPremium: true, tint: Color(red: 0.7, green: 0.7, blue: 0.95)),
        SleepSound(id: "ambient", name: "Deep Ambient", symbol: "circle.hexagongrid.fill", texture: .ambient, isPremium: true, tint: Color(red: 0.55, green: 0.65, blue: 0.92)),
        SleepSound(id: "lofi", name: "Lo-Fi Sleep", symbol: "music.note", texture: .lofi, isPremium: true, tint: Color(red: 0.85, green: 0.6, blue: 0.78)),
    ]

    static func find(_ id: String) -> SleepSound? { all.first { $0.id == id } }
}

// MARK: - Dream Journal

struct DreamEntry: Identifiable, Hashable {
    let id: UUID
    var date: Date
    var text: String
    var mood: Mood
    var themes: [String]
    var symbols: [String]
    var interpretation: String

    enum Mood: String, CaseIterable, Identifiable {
        case peaceful, joyful, neutral, anxious, strange
        var id: String { rawValue }
        var label: String { rawValue.capitalized }
        var symbol: String {
            switch self {
            case .peaceful: return "leaf.fill"
            case .joyful: return "sun.max.fill"
            case .neutral: return "cloud.fill"
            case .anxious: return "cloud.bolt.fill"
            case .strange: return "sparkles"
            }
        }
        var color: Color {
            switch self {
            case .peaceful: return Color(red: 0.5, green: 0.82, blue: 0.7)
            case .joyful: return Color(red: 0.98, green: 0.78, blue: 0.4)
            case .neutral: return Color(red: 0.65, green: 0.7, blue: 0.82)
            case .anxious: return Color(red: 0.95, green: 0.55, blue: 0.5)
            case .strange: return Color(red: 0.78, green: 0.6, blue: 0.95)
            }
        }
    }

    init(id: UUID = UUID(), date: Date, text: String, mood: Mood, themes: [String] = [], symbols: [String] = [], interpretation: String = "") {
        self.id = id
        self.date = date
        self.text = text
        self.mood = mood
        self.themes = themes
        self.symbols = symbols
        self.interpretation = interpretation
    }
}

// MARK: - Alarms

struct WakeAlarm: Identifiable, Hashable {
    let id: UUID
    var hour: Int
    var minute: Int
    var label: String
    var isEnabled: Bool
    var repeatDays: Set<Int> // 1 = Sunday ... 7 = Saturday
    var soundID: String
    var sunriseEnabled: Bool
    var smartVolume: Bool
    var challengeID: String

    init(id: UUID = UUID(), hour: Int, minute: Int, label: String, isEnabled: Bool, repeatDays: Set<Int> = [], soundID: String = "rain", sunriseEnabled: Bool = true, smartVolume: Bool = true, challengeID: String = "math") {
        self.id = id
        self.hour = hour
        self.minute = minute
        self.label = label
        self.isEnabled = isEnabled
        self.repeatDays = repeatDays
        self.soundID = soundID
        self.sunriseEnabled = sunriseEnabled
        self.smartVolume = smartVolume
        self.challengeID = challengeID
    }

    var timeText: String {
        let date = Calendar.current.date(from: DateComponents(hour: hour, minute: minute)) ?? Date()
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f.string(from: date)
    }

    var repeatText: String {
        if repeatDays.isEmpty { return "Once" }
        if repeatDays.count == 7 { return "Every day" }
        if repeatDays == [2, 3, 4, 5, 6] { return "Weekdays" }
        if repeatDays == [1, 7] { return "Weekends" }
        let names = ["", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        return repeatDays.sorted().map { names[$0] }.joined(separator: " ")
    }
}

// MARK: - Wake Challenges

struct WakeChallenge: Identifiable, Hashable {
    enum Difficulty: String, CaseIterable, Identifiable {
        case easy, medium, hard
        var id: String { rawValue }
        var label: String { rawValue.capitalized }
        var color: Color {
            switch self {
            case .easy: return Color(red: 0.5, green: 0.82, blue: 0.6)
            case .medium: return Color(red: 0.98, green: 0.72, blue: 0.4)
            case .hard: return Color(red: 0.95, green: 0.5, blue: 0.45)
            }
        }
    }

    enum Kind: String {
        case math, memory, pattern, color, shake, steps, qr, photo, phrase, smile
    }

    let id: String
    let name: String
    let detail: String
    let symbol: String
    let kind: Kind
    let isPremium: Bool

    static let all: [WakeChallenge] = [
        WakeChallenge(id: "math", name: "Quick Maths", detail: "Solve a simple equation", symbol: "function", kind: .math, isPremium: false),
        WakeChallenge(id: "memory", name: "Memory Game", detail: "Repeat the sequence", symbol: "square.grid.2x2.fill", kind: .memory, isPremium: true),
        WakeChallenge(id: "pattern", name: "Pattern Match", detail: "Match the shown pattern", symbol: "circle.grid.cross.fill", kind: .pattern, isPremium: true),
        WakeChallenge(id: "color", name: "Colour Sequence", detail: "Tap colours in order", symbol: "paintpalette.fill", kind: .color, isPremium: true),
        WakeChallenge(id: "shake", name: "Shake It Off", detail: "Shake your device", symbol: "iphone.gen3.radiowaves.left.and.right", kind: .shake, isPremium: false),
        WakeChallenge(id: "steps", name: "Walk 20 Steps", detail: "Get out of bed and move", symbol: "figure.walk", kind: .steps, isPremium: true),
        WakeChallenge(id: "qr", name: "Scan a QR Code", detail: "Scan a code in another room", symbol: "qrcode.viewfinder", kind: .qr, isPremium: true),
        WakeChallenge(id: "photo", name: "Photo Mission", detail: "Photograph your bathroom sink", symbol: "camera.fill", kind: .photo, isPremium: true),
        WakeChallenge(id: "phrase", name: "Read Aloud", detail: "Say a phrase out loud", symbol: "text.bubble.fill", kind: .phrase, isPremium: true),
        WakeChallenge(id: "smile", name: "Smile to Wake", detail: "Smile at the camera", symbol: "face.smiling.fill", kind: .smile, isPremium: true),
    ]

    static func find(_ id: String) -> WakeChallenge? { all.first { $0.id == id } }
}

// MARK: - Hearing Profile

struct HearingProfile: Identifiable, Hashable {
    let id: UUID
    var name: String
    /// Highest frequency (Hz) the person could reliably hear.
    var maxFrequency: Double

    init(id: UUID = UUID(), name: String, maxFrequency: Double) {
        self.id = id
        self.name = name
        self.maxFrequency = maxFrequency
    }

    var approxAge: String {
        switch maxFrequency {
        case 17000...: return "Under 24"
        case 16000..<17000: return "Around 24–30"
        case 15000..<16000: return "Around 30–40"
        case 14000..<15000: return "Around 40–50"
        case 12000..<14000: return "Around 50–60"
        default: return "60+"
        }
    }
}

// MARK: - Bedtime story themes

struct StoryTheme: Identifiable, Hashable {
    let id: String
    let name: String
    let symbol: String
    let tint: Color

    static let all: [StoryTheme] = [
        StoryTheme(id: "space", name: "Space", symbol: "moon.stars.fill", tint: Color(red: 0.55, green: 0.6, blue: 0.95)),
        StoryTheme(id: "ocean", name: "Ocean", symbol: "water.waves", tint: Color(red: 0.35, green: 0.72, blue: 0.85)),
        StoryTheme(id: "fantasy", name: "Fantasy", symbol: "sparkles", tint: Color(red: 0.78, green: 0.6, blue: 0.95)),
        StoryTheme(id: "nature", name: "Nature", symbol: "leaf.fill", tint: Color(red: 0.5, green: 0.8, blue: 0.6)),
        StoryTheme(id: "rain", name: "Rain", symbol: "cloud.rain.fill", tint: Color(red: 0.55, green: 0.68, blue: 0.85)),
        StoryTheme(id: "cabin", name: "Cabin", symbol: "house.fill", tint: Color(red: 0.85, green: 0.6, blue: 0.45)),
        StoryTheme(id: "mountains", name: "Mountains", symbol: "mountain.2.fill", tint: Color(red: 0.6, green: 0.68, blue: 0.78)),
    ]
}
