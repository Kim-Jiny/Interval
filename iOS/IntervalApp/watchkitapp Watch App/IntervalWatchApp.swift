//
//  IntervalWatchApp.swift
//  IntervalApp Watch App
//
//  Created by Claude on 1/15/26.
//

import SwiftUI

@main
struct IntervalWatchApp: App {
    @StateObject private var connectivityManager = WatchConnectivityManager.shared
    @StateObject private var routineStore = WatchRoutineStore.shared

    var body: some Scene {
        WindowGroup {
            WatchContentView()
                .environmentObject(connectivityManager)
                .environmentObject(routineStore)
        }
    }
}
