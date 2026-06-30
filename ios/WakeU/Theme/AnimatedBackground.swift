//
//  AnimatedBackground.swift
//  WakeU
//

import SwiftUI

/// A slowly breathing gradient with drifting glow orbs and (at night) soft stars.
/// This is the signature atmosphere behind every wakeU screen.
struct AnimatedBackground: View {
    let palette: WakePalette
    var dimmed: Double = 0

    @State private var animate = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [palette.gradientTop, palette.gradientMid, palette.gradientBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Soft drifting glow orbs for depth.
            GeometryReader { geo in
                ZStack {
                    glowOrb(palette.accentSoft.opacity(0.45), size: geo.size.width * 0.9)
                        .offset(
                            x: animate ? -geo.size.width * 0.25 : geo.size.width * 0.1,
                            y: animate ? -geo.size.height * 0.15 : geo.size.height * 0.05
                        )
                    glowOrb(palette.accent.opacity(0.28), size: geo.size.width * 0.7)
                        .offset(
                            x: animate ? geo.size.width * 0.3 : -geo.size.width * 0.05,
                            y: animate ? geo.size.height * 0.35 : geo.size.height * 0.5
                        )
                }
                .blur(radius: 40)
            }
            .ignoresSafeArea()

            if palette.showsStars {
                StarFieldView()
                    .ignoresSafeArea()
                    .transition(.opacity)
            }

            Color.black
                .opacity(dimmed)
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 1.2), value: dimmed)
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 16).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
    }

    private func glowOrb(_ color: Color, size: CGFloat) -> some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [color, color.opacity(0)],
                    center: .center,
                    startRadius: 0,
                    endRadius: size / 2
                )
            )
            .frame(width: size, height: size)
    }
}

/// A field of faint twinkling stars used for evening and night palettes.
struct StarFieldView: View {
    private struct Star: Identifiable {
        let id = UUID()
        let x: CGFloat
        let y: CGFloat
        let size: CGFloat
        let baseOpacity: Double
        let phase: Double
    }

    @State private var stars: [Star] = []
    @State private var twinkle = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(stars) { star in
                    Circle()
                        .fill(.white)
                        .frame(width: star.size, height: star.size)
                        .position(x: star.x * geo.size.width, y: star.y * geo.size.height)
                        .opacity(twinkle ? star.baseOpacity : star.baseOpacity * 0.35)
                        .animation(
                            reduceMotion ? nil :
                                .easeInOut(duration: 2.4 + star.phase)
                                .repeatForever(autoreverses: true)
                                .delay(star.phase),
                            value: twinkle
                        )
                }
            }
            .onAppear {
                if stars.isEmpty {
                    stars = (0..<70).map { _ in
                        Star(
                            x: .random(in: 0...1),
                            y: .random(in: 0...0.65),
                            size: .random(in: 1...2.6),
                            baseOpacity: .random(in: 0.3...0.9),
                            phase: .random(in: 0...2)
                        )
                    }
                }
                twinkle = true
            }
        }
    }
}
