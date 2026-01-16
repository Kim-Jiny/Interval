//
//  SettingsView.swift
//  IntervalApp
//
//  Created by Claude on 1/15/26.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("vibrationEnabled") private var vibrationEnabled = true
    @AppStorage("soundEnabled") private var soundEnabled = true
    @AppStorage("backgroundSoundEnabled") private var backgroundSoundEnabled = true
    @EnvironmentObject var routineStore: RoutineStore
    @ObservedObject private var connectivityManager = PhoneConnectivityManager.shared

    @AppStorage("lastWatchSyncTime") private var lastSyncTimeInterval: Double = 0
    @State private var showingAlert = false
    @State private var alertMessage = ""

    var body: some View {
        NavigationStack {
            List {
                // MARK: - 알림 설정
                Section {
                    Toggle(isOn: $vibrationEnabled) {
                        Label {
                            Text("Vibration")
                        } icon: {
                            Image(systemName: "iphone.radiowaves.left.and.right")
                                .foregroundColor(.orange)
                        }
                    }

                    Toggle(isOn: $soundEnabled) {
                        Label {
                            Text("Sound")
                        } icon: {
                            Image(systemName: "speaker.wave.2.fill")
                                .foregroundColor(.blue)
                        }
                    }

                    Toggle(isOn: $backgroundSoundEnabled) {
                        Label {
                            Text("Background Sound")
                        } icon: {
                            Image(systemName: "bell.badge.waveform.fill")
                                .foregroundColor(.purple)
                        }
                    }
                } header: {
                    Text("Notifications")
                } footer: {
                    Text("Background Sound plays periodic tick sounds to keep the timer running when the app is in background.")
                }

                // MARK: - Apple Watch
                Section {
                    Button {
                        syncToWatch()
                    } label: {
                        HStack {
                            Label {
                                Text("Sync to Watch")
                            } icon: {
                                Image(systemName: "applewatch")
                                    .foregroundColor(.green)
                            }

                            Spacer()

                            Text(lastSyncTimeString)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .foregroundColor(.primary)

                    HStack {
                        Label {
                            Text("Watch Connection")
                        } icon: {
                            Image(systemName: "antenna.radiowaves.left.and.right")
                                .foregroundColor(.purple)
                        }

                        Spacer()

                        Text(connectivityManager.isWatchReachable ? "Connected" : "Not Connected")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Apple Watch")
                }

                // MARK: - 앱 정보
                Section {
                    HStack {
                        Label {
                            Text("Version")
                        } icon: {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.gray)
                        }

                        Spacer()

                        Text(appVersion)
                            .foregroundColor(.secondary)
                    }

                    #if DEBUG
                    HStack {
                        Label {
                            Text("Build")
                        } icon: {
                            Image(systemName: "hammer.fill")
                                .foregroundColor(.gray)
                        }

                        Spacer()

                        Text(buildNumber)
                            .foregroundColor(.secondary)
                    }
                    #endif
                } header: {
                    Text("App Info")
                }
            }
            .navigationTitle("Settings")
            .alert("Sync Failed", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    private var lastSyncTimeString: String {
        guard lastSyncTimeInterval > 0 else {
            return String(localized: "Never")
        }

        let date = Date(timeIntervalSince1970: lastSyncTimeInterval)
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private func syncToWatch() {
        let result = PhoneConnectivityManager.shared.syncRoutines(routineStore.routines)

        switch result {
        case .success:
            lastSyncTimeInterval = Date().timeIntervalSince1970
        case .watchAppNotInstalled:
            alertMessage = String(localized: "Watch app is not installed. Please install the app on your Apple Watch.")
            showingAlert = true
        case .sessionNotActivated:
            alertMessage = String(localized: "Watch connection is not ready. Please try again.")
            showingAlert = true
        case .encodingFailed:
            alertMessage = String(localized: "Failed to prepare data.")
            showingAlert = true
        case .syncFailed(let error):
            alertMessage = String(localized: "Sync failed: \(error)")
            showingAlert = true
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(RoutineStore())
}
