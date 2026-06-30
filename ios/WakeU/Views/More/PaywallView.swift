//
//  PaywallView.swift
//  WakeU
//

import SwiftUI

struct PaywallView: View {
    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPlan = 1

    private var palette: WakePalette { app.palette }
    private let features: [(String, String)] = [
        ("waveform", "Unlimited sounds & exclusive packs"),
        ("brain.head.profile", "AI Sleep Coach & deep analytics"),
        ("alarm.waves.left.and.right.fill", "Unlimited wake challenges"),
        ("books.vertical.fill", "AI bedtime stories with narration"),
        ("ear.fill", "Multiple hearing profiles"),
        ("chart.line.uptrend.xyaxis", "Long-term sleep trends & cloud sync"),
    ]

    var body: some View {
        ZStack {
            AnimatedBackground(palette: palette)
            ScrollView {
                VStack(spacing: 22) {
                    Image(systemName: "moon.stars.circle.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(palette.accent)
                        .padding(.top, 30)
                    VStack(spacing: 6) {
                        Text("wakeU Premium")
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundStyle(palette.primaryText)
                        Text("Unlock your complete sleep journey")
                            .font(.subheadline).foregroundStyle(palette.secondaryText)
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(features, id: \.1) { feature in
                            HStack(spacing: 14) {
                                Image(systemName: feature.0)
                                    .foregroundStyle(palette.accent)
                                    .frame(width: 28)
                                Text(feature.1)
                                    .font(.subheadline)
                                    .foregroundStyle(palette.primaryText)
                                Spacer()
                            }
                        }
                    }
                    .padding(20)
                    .wakeGlass(cornerRadius: 24)

                    VStack(spacing: 12) {
                        planOption(index: 0, title: "Monthly", price: "$6.99", note: "billed monthly")
                        planOption(index: 1, title: "Yearly", price: "$39.99", note: "Save 52% · best value")
                    }

                    PrimaryActionButton(title: "Start 7-Day Free Trial", icon: "sparkles", fill: palette.accent) {
                        app.isPremium = true
                        dismiss()
                    }
                    Text("Cancel anytime. Then \(selectedPlan == 0 ? "$6.99/mo" : "$39.99/yr").")
                        .font(.caption).foregroundStyle(palette.secondaryText)
                    Button("Maybe later") { dismiss() }
                        .font(.subheadline).foregroundStyle(palette.secondaryText)
                        .padding(.bottom, 30)
                }
                .padding(.horizontal, 20)
            }
            .scrollIndicators(.hidden)
        }
        .environment(\.palette, palette)
        .preferredColorScheme(.dark)
    }

    private func planOption(index: Int, title: String, price: String, note: String) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { selectedPlan = index }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.headline).foregroundStyle(palette.primaryText)
                    Text(note).font(.caption).foregroundStyle(palette.secondaryText)
                }
                Spacer()
                Text(price).font(.headline).foregroundStyle(palette.primaryText)
                Image(systemName: selectedPlan == index ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(selectedPlan == index ? palette.accent : palette.secondaryText)
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(selectedPlan == index ? palette.accent : .clear, lineWidth: 2)
            )
            .wakeGlass(cornerRadius: 20)
        }
        .buttonStyle(.plain)
    }
}
