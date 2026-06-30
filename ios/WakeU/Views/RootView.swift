//
//  RootView.swift
//  WakeU
//

import SwiftUI

enum RootTab: Hashable {
    case home, sounds, sleep, dreams, more
}

struct RootView: View {
    @State private var app = AppState()
    @State private var sound = SoundEngine()
    @State private var selectedTab: RootTab = .home
    @State private var showGoodnight = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            AnimatedBackground(palette: app.palette)

            TabView(selection: $selectedTab) {
                Tab("Home", systemImage: "house.fill", value: RootTab.home) {
                    NavigationStack {
                        HomeView(selectedTab: $selectedTab, showGoodnight: $showGoodnight)
                            .navigationBarHidden(true)
                            .background(Color.clear)
                    }
                }
                Tab("Sounds", systemImage: "waveform", value: RootTab.sounds) {
                    NavigationStack {
                        SoundsView().navigationBarHidden(true).background(Color.clear)
                    }
                }
                Tab("Sleep", systemImage: "bed.double.fill", value: RootTab.sleep) {
                    NavigationStack {
                        SleepView().navigationBarHidden(true).background(Color.clear)
                    }
                }
                Tab("Dreams", systemImage: "cloud.moon.fill", value: RootTab.dreams) {
                    NavigationStack {
                        DreamJournalView().navigationBarHidden(true).background(Color.clear)
                    }
                }
                Tab("Alarms", systemImage: "alarm.fill", value: RootTab.more) {
                    NavigationStack {
                        AlarmsView().navigationBarHidden(true).background(Color.clear)
                    }
                }
            }
            .tint(app.palette.accent)
        }
        .environment(app)
        .environment(sound)
        .environment(\.palette, app.palette)
        .preferredColorScheme(app.palette.preferredScheme)
        .fullScreenCover(isPresented: $showGoodnight) {
            GoodnightView().environment(app).environment(sound)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { app.refreshTimeOfDay() }
        }
        .task {
            // Periodically refresh time of day so the palette shifts naturally.
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(60))
                app.refreshTimeOfDay()
            }
        }
    }
}

#Preview {
    RootView()
}
