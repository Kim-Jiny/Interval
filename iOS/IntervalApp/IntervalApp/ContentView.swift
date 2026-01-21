//
//  ContentView.swift
//  IntervalApp
//
//  Created by 김미진 on 1/14/26.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var routineStore: RoutineStore
    @ObservedObject private var shareManager = RoutineShareManager.shared

    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .alert(String(localized: "Add Shared Routine", comment: "Add shared routine alert title"),
               isPresented: $shareManager.showShareConfirmation) {
            Button(String(localized: "Add", comment: "Add button")) {
                shareManager.addPendingRoutine(to: routineStore)
            }
            Button(String(localized: "Cancel", comment: "Cancel button"), role: .cancel) {
                shareManager.cancelPendingRoutine()
            }
        } message: {
            if let routine = shareManager.pendingRoutine {
                Text(String(format: String(localized: "Do you want to add '%@' to your routines?", comment: "Add shared routine confirmation message"), routine.name))
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(RoutineStore())
}
