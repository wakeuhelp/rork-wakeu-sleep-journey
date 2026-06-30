//
//  GlassComponents.swift
//  WakeU
//

import SwiftUI

extension View {
    /// Applies Liquid Glass on iOS 26 with a polished material fallback.
    @ViewBuilder
    func wakeGlass(cornerRadius: CGFloat = 24, tint: Color? = nil) -> some View {
        if #available(iOS 26.0, *) {
            if let tint {
                self.glassEffect(.regular.tint(tint.opacity(0.25)), in: .rect(cornerRadius: cornerRadius))
            } else {
                self.glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
            }
        } else {
            self.background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [.white.opacity(0.18), .clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(.white.opacity(0.18), lineWidth: 0.6)
                    )
            )
        }
    }
}

/// Standard frosted card used throughout wakeU.
struct GlassCard<Content: View>: View {
    var cornerRadius: CGFloat = 26
    var padding: CGFloat = 18
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .wakeGlass(cornerRadius: cornerRadius)
    }
}

/// A small uppercase section label.
struct SectionLabel: View {
    let text: String
    @Environment(\.palette) private var palette

    var body: some View {
        Text(text.uppercased())
            .font(.caption.weight(.semibold))
            .tracking(1.4)
            .foregroundStyle(palette.secondaryText)
    }
}

/// The big circular sleep score ring with an animated fill.
struct ScoreRing: View {
    let score: Int
    var size: CGFloat = 180
    var lineWidth: CGFloat = 16
    @Environment(\.palette) private var palette
    @State private var progress: CGFloat = 0

    private var ringColors: [Color] {
        switch score {
        case 85...: return [Color(red: 0.4, green: 0.85, blue: 0.7), palette.accent]
        case 70..<85: return [palette.accentSoft, palette.accent]
        default: return [Color(red: 0.98, green: 0.6, blue: 0.45), palette.accent]
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(palette.primaryText.opacity(0.12), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(colors: ringColors, center: .center),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: ringColors.last?.opacity(0.5) ?? .clear, radius: 8)
            VStack(spacing: 2) {
                Text("\(score)")
                    .font(.system(size: size * 0.34, weight: .bold, design: .rounded))
                    .foregroundStyle(palette.primaryText)
                    .contentTransition(.numericText())
                Text("Sleep Score")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(palette.secondaryText)
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.easeOut(duration: 1.3)) {
                progress = CGFloat(score) / 100
            }
        }
        .onChange(of: score) { _, newValue in
            withAnimation(.easeOut(duration: 1.0)) {
                progress = CGFloat(newValue) / 100
            }
        }
    }
}

/// A small stat pill (label + value) used in compact summaries.
struct StatPill: View {
    let icon: String
    let title: String
    let value: String
    @Environment(\.palette) private var palette

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(palette.accent)
                .frame(width: 30)
            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.headline)
                    .foregroundStyle(palette.primaryText)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(palette.secondaryText)
            }
            Spacer(minLength: 0)
        }
    }
}

/// Big primary action button with a soft glow.
struct PrimaryActionButton: View {
    let title: String
    let icon: String
    var fill: Color
    var textColor: Color = .white
    let action: () -> Void

    @State private var pressed = false

    var body: some View {
        Button {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            action()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.headline)
                Text(title)
                    .font(.headline.weight(.semibold))
            }
            .foregroundStyle(textColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 17)
            .background(
                Capsule().fill(fill)
                    .shadow(color: fill.opacity(0.5), radius: 14, y: 6)
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(pressed ? 0.97 : 1)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: pressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in pressed = true }
                .onEnded { _ in pressed = false }
        )
    }
}
