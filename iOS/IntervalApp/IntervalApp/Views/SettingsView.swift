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
    @ObservedObject private var authManager = AuthManager.shared
    @StateObject private var updateManager = AppUpdateManager.shared

    @AppStorage("lastWatchSyncTime") private var lastSyncTimeInterval: Double = 0
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showingLoginSheet = false
    @State private var showingLogoutConfirm = false
    @State private var showingDeleteConfirm = false
    @State private var isDeleting = false
    @State private var isAccountExpanded = false
    @State private var showingNicknameEdit = false
    @State private var editingNickname = ""
    @State private var isUpdatingNickname = false

    var body: some View {
        NavigationStack {
            List {
                // MARK: - 계정
                Section {
                    Button {
                        withAnimation {
                            isAccountExpanded.toggle()
                        }
                    } label: {
                        HStack {
                            if authManager.isLoggedIn, let user = authManager.currentUser {
                                Image(systemName: "person.crop.circle.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.accentColor)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(user.nickname)
                                        .font(.headline)
                                    Text(user.email)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            } else {
                                Image(systemName: "person.crop.circle.badge.plus")
                                    .font(.system(size: 40))
                                    .foregroundColor(.gray)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Guest", comment: "Guest user label")
                                        .font(.headline)
                                    Text("Log in to share routines and workouts", comment: "Guest user description")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .rotationEffect(.degrees(isAccountExpanded ? 90 : 0))
                        }
                        .padding(.vertical, 4)
                    }
                    .foregroundColor(.primary)

                    if isAccountExpanded {
                        if authManager.isLoggedIn {
                            Button {
                                editingNickname = authManager.currentUser?.nickname ?? ""
                                showingNicknameEdit = true
                            } label: {
                                HStack {
                                    Label(String(localized: "Change Nickname", comment: "Button to change nickname"), systemImage: "pencil")
                                    Spacer()
                                    if isUpdatingNickname {
                                        ProgressView()
                                    }
                                }
                            }
                            .disabled(isUpdatingNickname)

                            Button(role: .destructive) {
                                showingLogoutConfirm = true
                            } label: {
                                Label(String(localized: "Log Out", comment: "Button to log out"), systemImage: "rectangle.portrait.and.arrow.right")
                            }

                            Button(role: .destructive) {
                                showingDeleteConfirm = true
                            } label: {
                                HStack {
                                    Label(String(localized: "Delete Account", comment: "Button to delete account"), systemImage: "person.crop.circle.badge.minus")
                                    if isDeleting {
                                        Spacer()
                                        ProgressView()
                                    }
                                }
                            }
                            .disabled(isDeleting)
                        } else {
                            Button {
                                showingLoginSheet = true
                            } label: {
                                Label(String(localized: "Log In", comment: "Button to log in"), systemImage: "person.crop.circle.badge.checkmark")
                            }
                        }
                    }
                } header: {
                    Text("Account", comment: "Section header for account settings")
                }

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
                                Text("Sync to Watch", comment: "Button to sync routines to Apple Watch")
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
                            Text("Watch Connection", comment: "Label showing Apple Watch connection status")
                        } icon: {
                            Image(systemName: "antenna.radiowaves.left.and.right")
                                .foregroundColor(.purple)
                        }

                        Spacer()

                        Text(connectivityManager.isWatchReachable
                             ? String(localized: "Connected", comment: "Watch is connected")
                             : String(localized: "Not Connected", comment: "Watch is not connected"))
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Apple Watch", comment: "Section header for Apple Watch settings")
                } footer: {
                    if !connectivityManager.isWatchReachable {
                        Text("Opening the Watch app will automatically connect.", comment: "Help text when watch is not connected")
                    }
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

                        if updateManager.isUpdateAvailable {
                            Button {
                                UIApplication.shared.open(updateManager.appStoreURL)
                            } label: {
                                HStack(spacing: 4) {
                                    Text(appVersion)
                                    Image(systemName: "arrow.up.circle.fill")
                                }
                                .foregroundColor(.accentColor)
                            }
                        } else {
                            Text(appVersion)
                                .foregroundColor(.secondary)
                        }
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
            .task {
                await updateManager.checkForUpdate()
            }
            .alert("Error", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
            .sheet(isPresented: $showingLoginSheet) {
                LoginView()
            }
            .confirmationDialog(String(localized: "Log Out", comment: "Log out dialog title"), isPresented: $showingLogoutConfirm, titleVisibility: .visible) {
                Button(String(localized: "Log Out", comment: "Log out button"), role: .destructive) {
                    authManager.logout()
                }
                Button(String(localized: "Cancel", comment: "Cancel button"), role: .cancel) { }
            } message: {
                Text("Are you sure you want to log out?", comment: "Log out confirmation message")
            }
            .confirmationDialog(String(localized: "Delete Account", comment: "Delete account dialog title"), isPresented: $showingDeleteConfirm, titleVisibility: .visible) {
                Button(String(localized: "Delete Account", comment: "Delete account button"), role: .destructive) {
                    Task {
                        await deleteAccount()
                    }
                }
                Button(String(localized: "Cancel", comment: "Cancel button"), role: .cancel) { }
            } message: {
                Text("This will permanently delete your account and all associated data. This action cannot be undone.", comment: "Delete account warning message")
            }
            .alert(String(localized: "Change Nickname", comment: "Change nickname dialog title"), isPresented: $showingNicknameEdit) {
                TextField(String(localized: "Nickname", comment: "Nickname text field placeholder"), text: $editingNickname)
                Button(String(localized: "Save", comment: "Save button")) {
                    Task {
                        await updateNickname()
                    }
                }
                Button(String(localized: "Cancel", comment: "Cancel button"), role: .cancel) { }
            } message: {
                Text("Enter your new nickname (2-20 characters)", comment: "Nickname requirements message")
            }
            .onChange(of: authManager.isLoggedIn) { _, isLoggedIn in
                if isLoggedIn {
                    withAnimation {
                        isAccountExpanded = false
                    }
                }
            }
        }
    }

    private func deleteAccount() async {
        isDeleting = true
        defer { isDeleting = false }

        do {
            try await authManager.deleteAccount()
        } catch {
            alertMessage = error.localizedDescription
            showingAlert = true
        }
    }

    private func updateNickname() async {
        let trimmed = editingNickname.trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmed.count >= 2 && trimmed.count <= 20 else {
            alertMessage = String(localized: "Nickname must be 2-20 characters", comment: "Nickname validation error")
            showingAlert = true
            return
        }

        isUpdatingNickname = true
        defer { isUpdatingNickname = false }

        do {
            try await authManager.updateNickname(trimmed)
        } catch {
            alertMessage = error.localizedDescription
            showingAlert = true
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
