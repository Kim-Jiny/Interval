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
    @ObservedObject private var challengeManager = ChallengeManager.shared

    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            CommunityView()
                .tabItem {
                    Label("Challenge", systemImage: "trophy.fill")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        // Routine share confirmation alert
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
        // Challenge detail view from deep link
        .sheet(isPresented: $challengeManager.showChallengeDetail, onDismiss: {
            challengeManager.pendingChallenge = nil
        }) {
            if let challenge = challengeManager.pendingChallenge {
                NavigationStack {
                    ChallengeDetailView(challengeId: challenge.id)
                }
            }
        }
        // Deep link error alert
        .alert(String(localized: "Error", comment: "Error alert title"),
               isPresented: $challengeManager.showDeepLinkError) {
            Button(String(localized: "OK", comment: "OK button"), role: .cancel) {}
        } message: {
            Text(challengeManager.deepLinkErrorMessage ?? String(localized: "Failed to open challenge"))
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(RoutineStore())
}
