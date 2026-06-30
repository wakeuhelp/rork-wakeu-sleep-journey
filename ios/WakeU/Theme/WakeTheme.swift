//
//  WakeTheme.swift
//  WakeU
//

import SwiftUI

/// A resolved colour palette for a given time of day. wakeU's whole surface
/// shifts subtly through the day to feel alive and calming.
struct WakePalette: Equatable {
    let gradientTop: Color
    let gradientMid: Color
    let gradientBottom: Color
    /// Primary readable text colour on top of the gradient.
    let primaryText: Color
    let secondaryText: Color
    /// Accent used for highlights, rings and key actions.
    let accent: Color
    let accentSoft: Color
    /// Whether faint stars should drift across the background.
    let showsStars: Bool
    /// Suggested colour scheme for system controls.
    let preferredScheme: ColorScheme

    static func palette(for time: TimeOfDay) -> WakePalette {
        switch time {
        case .morning:
            return WakePalette(
                gradientTop: Color(red: 0.99, green: 0.78, blue: 0.55),
                gradientMid: Color(red: 0.97, green: 0.66, blue: 0.58),
                gradientBottom: Color(red: 0.78, green: 0.80, blue: 0.92),
                primaryText: Color(red: 0.20, green: 0.14, blue: 0.18),
                secondaryText: Color(red: 0.30, green: 0.24, blue: 0.28).opacity(0.75),
                accent: Color(red: 0.95, green: 0.45, blue: 0.36),
                accentSoft: Color(red: 1.0, green: 0.72, blue: 0.55),
                showsStars: false,
                preferredScheme: .light
            )
        case .afternoon:
            return WakePalette(
                gradientTop: Color(red: 0.93, green: 0.96, blue: 1.0),
                gradientMid: Color(red: 0.84, green: 0.91, blue: 0.99),
                gradientBottom: Color(red: 0.74, green: 0.85, blue: 0.97),
                primaryText: Color(red: 0.10, green: 0.18, blue: 0.30),
                secondaryText: Color(red: 0.22, green: 0.32, blue: 0.45).opacity(0.78),
                accent: Color(red: 0.18, green: 0.52, blue: 0.92),
                accentSoft: Color(red: 0.55, green: 0.74, blue: 0.98),
                showsStars: false,
                preferredScheme: .light
            )
        case .evening:
            return WakePalette(
                gradientTop: Color(red: 0.36, green: 0.22, blue: 0.45),
                gradientMid: Color(red: 0.45, green: 0.26, blue: 0.42),
                gradientBottom: Color(red: 0.78, green: 0.42, blue: 0.34),
                primaryText: Color(red: 0.98, green: 0.95, blue: 0.98),
                secondaryText: Color(red: 0.92, green: 0.86, blue: 0.92).opacity(0.72),
                accent: Color(red: 0.98, green: 0.62, blue: 0.42),
                accentSoft: Color(red: 0.74, green: 0.52, blue: 0.78),
                showsStars: true,
                preferredScheme: .dark
            )
        case .night:
            return WakePalette(
                gradientTop: Color(red: 0.03, green: 0.04, blue: 0.10),
                gradientMid: Color(red: 0.05, green: 0.06, blue: 0.16),
                gradientBottom: Color(red: 0.09, green: 0.10, blue: 0.24),
                primaryText: Color(red: 0.92, green: 0.94, blue: 1.0),
                secondaryText: Color(red: 0.74, green: 0.78, blue: 0.92).opacity(0.7),
                accent: Color(red: 0.62, green: 0.72, blue: 1.0),
                accentSoft: Color(red: 0.40, green: 0.48, blue: 0.78),
                showsStars: true,
                preferredScheme: .dark
            )
        }
    }
}

private struct WakePaletteKey: EnvironmentKey {
    static let defaultValue: WakePalette = .palette(for: .night)
}

extension EnvironmentValues {
    var palette: WakePalette {
        get { self[WakePaletteKey.self] }
        set { self[WakePaletteKey.self] = newValue }
    }
}
