//
//  SleepView.swift
//  WakeU
//

import SwiftUI
import Charts

struct SleepView: View {
    @Environment(AppState.self) private var app
    @State private var segment = 0

    private var palette: WakePalette { app.palette }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header

                Picker("Section", selection: $segment) {
                    Text("Coach").tag(0)
                    Text("Timeline").tag(1)
                    Text("Stats").tag(2)
                }
                .pickerStyle(.segmented)

                switch segment {
                case 0: coachSection
                case 1: timelineSection
                default: statsSection
                }
                Color.clear.frame(height: 90)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
        .scrollIndicators(.hidden)
        .environment(\.palette, palette)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Sleep")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(palette.primaryText)
            Text("Insights for \(dateText)")
                .font(.subheadline).foregroundStyle(palette.secondaryText)
        }
        .padding(.top, 4)
    }

    // MARK: - Coach

    private var coachSection: some View {
        VStack(spacing: 18) {
            HStack(spacing: 16) {
                ScoreRing(score: app.lastNight.score, size: 130, lineWidth: 12)
                VStack(alignment: .leading, spacing: 10) {
                    StatPill(icon: "bed.double.fill", title: "Time asleep", value: app.lastNight.durationText)
                    StatPill(icon: "sparkles", title: "Quality", value: "\(app.lastNight.quality)%")
                    StatPill(icon: "wind", title: "Snoring", value: "\(app.lastNight.snoringMinutes) min")
                }
            }
            .padding(18)
            .wakeGlass(cornerRadius: 26)

            GlassCard {
                VStack(alignment: .leading, spacing: 12) {
                    Label("AI Sleep Coach", systemImage: "brain.head.profile")
                        .font(.headline).foregroundStyle(palette.primaryText)
                    Text(SleepCoach.summary(for: app.lastNight, averageScore: app.averageScore))
                        .font(.subheadline).foregroundStyle(palette.secondaryText)
                    Divider().background(palette.primaryText.opacity(0.12))
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "lightbulb.fill").foregroundStyle(palette.accent)
                        Text(SleepCoach.recommendation(for: app.lastNight))
                            .font(.subheadline.weight(.medium)).foregroundStyle(palette.primaryText)
                    }
                }
            }

            VStack(spacing: 12) {
                ForEach(SleepCoach.insights(for: app.lastNight)) { insight in
                    HStack(spacing: 14) {
                        Image(systemName: insight.symbol).foregroundStyle(palette.accent).frame(width: 26)
                        Text(insight.text).font(.subheadline).foregroundStyle(palette.primaryText)
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
                .padding(.horizontal, 4)
            }
            .padding(16)
            .wakeGlass(cornerRadius: 24)
        }
    }

    // MARK: - Timeline

    private var timelineSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 0) {
                Text("Last Night")
                    .font(.headline).foregroundStyle(palette.primaryText)
                    .padding(.bottom, 12)
                ForEach(Array(app.lastNight.events.enumerated()), id: \.element.id) { index, event in
                    HStack(alignment: .top, spacing: 14) {
                        VStack(spacing: 0) {
                            Circle().fill(event.kind.color).frame(width: 12, height: 12)
                            if index < app.lastNight.events.count - 1 {
                                Rectangle().fill(palette.primaryText.opacity(0.15))
                                    .frame(width: 2).frame(maxHeight: .infinity)
                            }
                        }
                        .frame(height: 52)
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 8) {
                                Image(systemName: event.kind.symbol)
                                    .font(.caption).foregroundStyle(event.kind.color)
                                Text(event.kind.label)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(palette.primaryText)
                            }
                            Text(event.time).font(.caption).foregroundStyle(palette.secondaryText)
                        }
                        Spacer()
                    }
                }
            }
        }
    }

    // MARK: - Stats

    private var statsSection: some View {
        VStack(spacing: 18) {
            chartCard("Sleep Score", "Last 7 days") {
                Chart(app.history) { point in
                    BarMark(
                        x: .value("Day", point.label),
                        y: .value("Score", point.score)
                    )
                    .foregroundStyle(LinearGradient(colors: [palette.accentSoft, palette.accent], startPoint: .bottom, endPoint: .top))
                    .cornerRadius(6)
                }
                .chartYScale(domain: 0...100)
                .frame(height: 160)
            }

            chartCard("Sleep Duration", "Hours per night") {
                Chart(app.history) { point in
                    AreaMark(
                        x: .value("Day", point.label),
                        y: .value("Hours", point.durationHours)
                    )
                    .foregroundStyle(LinearGradient(colors: [palette.accent.opacity(0.4), .clear], startPoint: .top, endPoint: .bottom))
                    .interpolationMethod(.catmullRom)
                    LineMark(
                        x: .value("Day", point.label),
                        y: .value("Hours", point.durationHours)
                    )
                    .foregroundStyle(palette.accent)
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 3))
                }
                .chartYScale(domain: 4...10)
                .frame(height: 160)
            }

            chartCard("Bedtime Consistency", "When you fall asleep") {
                Chart(app.history) { point in
                    PointMark(
                        x: .value("Day", point.label),
                        y: .value("Bedtime", point.bedtimeHour)
                    )
                    .foregroundStyle(palette.accent)
                    .symbolSize(120)
                }
                .chartYScale(domain: 22...24)
                .frame(height: 140)
            }

            HStack(spacing: 14) {
                statBox("Avg Bedtime", "10:54 PM", "bed.double.fill")
                statBox("Avg Wake", "6:58 AM", "sunrise.fill")
            }
            HStack(spacing: 14) {
                statBox("Avg Score", "\(app.averageScore)", "star.fill")
                statBox("Challenge Wins", "92%", "checkmark.seal.fill")
            }
        }
    }

    private func chartCard<C: View>(_ title: String, _ subtitle: String, @ViewBuilder chart: () -> C) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 6) {
                Text(title).font(.headline).foregroundStyle(palette.primaryText)
                Text(subtitle).font(.caption).foregroundStyle(palette.secondaryText)
                chart()
                    .chartXAxis {
                        AxisMarks { _ in
                            AxisValueLabel().foregroundStyle(palette.secondaryText)
                        }
                    }
                    .chartYAxis {
                        AxisMarks { _ in
                            AxisGridLine().foregroundStyle(palette.primaryText.opacity(0.1))
                            AxisValueLabel().foregroundStyle(palette.secondaryText)
                        }
                    }
                    .padding(.top, 8)
            }
        }
    }

    private func statBox(_ title: String, _ value: String, _ icon: String) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: icon).foregroundStyle(palette.accent)
                Text(value).font(.title3.weight(.bold)).foregroundStyle(palette.primaryText)
                Text(title).font(.caption).foregroundStyle(palette.secondaryText)
            }
        }
    }

    private var dateText: String {
        let f = DateFormatter(); f.dateFormat = "EEEE, MMM d"
        return f.string(from: app.lastNight.date)
    }
}
