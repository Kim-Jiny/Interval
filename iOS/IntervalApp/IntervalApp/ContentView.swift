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
        // Challenge join confirmation alert
        .alert(String(localized: "Join Challenge", comment: "Join challenge alert title"),
               isPresented: $challengeManager.showJoinConfirmation) {
            Button(String(localized: "Join", comment: "Join button")) {
                Task {
                    try? await challengeManager.confirmJoinPendingChallenge()
                }
            }
            Button(String(localized: "Cancel", comment: "Cancel button"), role: .cancel) {
                challengeManager.cancelPendingChallenge()
            }
        } message: {
            if let challenge = challengeManager.pendingChallenge {
                Text(String(format: String(localized: "Do you want to join '%@'? Entry fee: %@", comment: "Join challenge confirmation message"), challenge.title, challenge.formattedEntryFee))
            }
        }
        // Deep link error alert
        .alert(String(localized: "Error", comment: "Error alert title"),
               isPresented: $challengeManager.showDeepLinkError) {
            Button(String(localized: "OK", comment: "OK button"), role: .cancel) {}
        } message: {
            Text(challengeManager.deepLinkErrorMessage ?? String(localized: "Failed to open challenge"))
        }
        // Already participating alert
        .alert(String(localized: "Already Joined", comment: "Already joined alert title"),
               isPresented: $challengeManager.showAlreadyParticipating) {
            Button(String(localized: "OK", comment: "OK button"), role: .cancel) {
                challengeManager.pendingChallenge = nil
            }
        } message: {
            if let challenge = challengeManager.pendingChallenge {
                Text(String(format: String(localized: "You are already participating in '%@'.", comment: "Already participating message"), challenge.title))
            }
        }
        // Cannot join alert (not in registration period)
        .alert(String(localized: "Cannot Join", comment: "Cannot join alert title"),
               isPresented: $challengeManager.showCannotJoin) {
            Button(String(localized: "OK", comment: "OK button"), role: .cancel) {
                challengeManager.pendingChallenge = nil
            }
        } message: {
            if let challenge = challengeManager.pendingChallenge {
                Text(String(format: String(localized: "'%@' is not currently accepting participants.", comment: "Cannot join message"), challenge.title))
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(RoutineStore())
}
