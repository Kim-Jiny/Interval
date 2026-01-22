//
//  SettingsView.swift
//  IntervalApp
//
//  Created by Claude on 1/15/26.
//

import SwiftUI
import UserNotifications

struct SettingsView: View {
    @AppStorage("pushNotificationEnabled") private var pushNotificationEnabled = true
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
    @State private var showingAccountActions = false
    @State private var showingNicknameEdit = false
    @State private var editingNickname = ""
    @State private var isUpdatingNickname = false
    @State private var pushPermissionDenied = false

    var body: some View {
        NavigationStack {
            List {
                // MARK: - 계정 카드
                Section {
                    accountCard
                } header: {
                    HStack(spacing: 6) {
                        Image(systemName: "person.crop.circle.fill")
                            .foregroundStyle(.blue)
                        Text("Account", comment: "Section header for account settings")
                            .fontWeight(.semibold)
                    }
                    .textCase(nil)
                }

                // MARK: - 알림 설정
                Section {
                    Toggle(isOn: $pushNotificationEnabled) {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.red.opacity(0.15))
                                    .frame(width: 32, height: 32)
                                Image(systemName: "bell.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.red)
                            }
                            Text("Push Notifications", comment: "Push notification toggle label")
                        }
                    }
                    .onChange(of: pushNotificationEnabled) { _, newValue in
                        handlePushNotificationToggle(newValue)
                    }

                    Toggle(isOn: $vibrationEnabled) {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.orange.opacity(0.15))
                                    .frame(width: 32, height: 32)
                                Image(systemName: "iphone.radiowaves.left.and.right")
                                    .font(.system(size: 14))
                                    .foregroundColor(.orange)
                            }
                            Text("Vibration")
                        }
                    }

                    Toggle(isOn: $soundEnabled) {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.blue.opacity(0.15))
                                    .frame(width: 32, height: 32)
                                Image(systemName: "speaker.wave.2.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.blue)
                            }
                            Text("Sound")
                        }
                    }

                    Toggle(isOn: $backgroundSoundEnabled) {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.purple.opacity(0.15))
                                    .frame(width: 32, height: 32)
                                Image(systemName: "bell.badge.waveform.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.purple)
                            }
                            Text("Background Sound")
                        }
                    }
                } header: {
                    HStack(spacing: 6) {
                        Image(systemName: "bell.fill")
                            .foregroundStyle(.red)
                        Text("Notifications")
                            .fontWeight(.semibold)
                    }
                    .textCase(nil)
                } footer: {
                    VStack(alignment: .leading, spacing: 4) {
                        if pushPermissionDenied {
                            Button {
                                openAppSettings()
                            } label: {
                                Text("Push notifications are disabled in system settings. Tap to open Settings.", comment: "Push permission denied message")
                                    .foregroundColor(.orange)
                            }
                        }
                        Text("Background Sound plays periodic tick sounds to keep the timer running when the app is in background.")
                    }
                }

                // MARK: - Apple Watch
                Section {
                    Button {
                        syncToWatch()
                    } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.green.opacity(0.15))
                                    .frame(width: 32, height: 32)
                                Image(systemName: "applewatch")
                                    .font(.system(size: 14))
                                    .foregroundColor(.green)
                            }
                            Text("Sync to Watch", comment: "Button to sync routines to Apple Watch")

                            Spacer()

                            Text(lastSyncTimeString)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .foregroundColor(.primary)

                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.purple.opacity(0.15))
                                .frame(width: 32, height: 32)
                            Image(systemName: "antenna.radiowaves.left.and.right")
                                .font(.system(size: 14))
                                .foregroundColor(.purple)
                        }
                        Text("Watch Connection", comment: "Label showing Apple Watch connection status")

                        Spacer()

                        HStack(spacing: 4) {
                            Circle()
                                .fill(connectivityManager.isWatchReachable ? Color.green : Color.gray)
                                .frame(width: 8, height: 8)
                            Text(connectivityManager.isWatchReachable
                                 ? String(localized: "Connected", comment: "Watch is connected")
                                 : String(localized: "Not Connected", comment: "Watch is not connected"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    HStack(spacing: 6) {
                        Image(systemName: "applewatch")
                            .foregroundStyle(.green)
                        Text("Apple Watch", comment: "Section header for Apple Watch settings")
                            .fontWeight(.semibold)
                    }
                    .textCase(nil)
                } footer: {
                    if !connectivityManager.isWatchReachable {
                        Text("Opening the Watch app will automatically connect.", comment: "Help text when watch is not connected")
                    }
                }

                // MARK: - 앱 정보
                Section {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.15))
                                .frame(width: 32, height: 32)
                            Image(systemName: "info.circle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                        Text("Version")

                        Spacer()

                        if updateManager.isUpdateAvailable {
                            Button {
                                UIApplication.shared.open(updateManager.appStoreURL)
                            } label: {
                                HStack(spacing: 4) {
                                    Text(appVersion)
                                    Image(systemName: "arrow.up.circle.fill")
                                }
                                .font(.subheadline)
                                .foregroundColor(.blue)
                            }
                        } else {
                            Text(appVersion)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }

                    #if DEBUG
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.15))
                                .frame(width: 32, height: 32)
                            Image(systemName: "hammer.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                        Text("Build")

                        Spacer()

                        Text(buildNumber)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    #endif
                } header: {
                    HStack(spacing: 6) {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(.gray)
                        Text("App Info")
                            .fontWeight(.semibold)
                    }
                    .textCase(nil)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(
                LinearGradient(
                    colors: [
                        Color.purple.opacity(0.05),
                        Color(.systemGroupedBackground)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Settings")
            .task {
                await updateManager.checkForUpdate()
            }
            .onAppear {
                checkPushNotificationStatus()
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
            .confirmationDialog(String(localized: "Account", comment: "Account actions dialog title"), isPresented: $showingAccountActions, titleVisibility: .visible) {
                Button(String(localized: "Change Nickname", comment: "Button to change nickname")) {
                    editingNickname = authManager.currentUser?.nickname ?? ""
                    showingNicknameEdit = true
                }
                Button(String(localized: "Log Out", comment: "Log out button"), role: .destructive) {
                    showingLogoutConfirm = true
                }
                Button(String(localized: "Delete Account", comment: "Delete account button"), role: .destructive) {
                    showingDeleteConfirm = true
                }
                Button(String(localized: "Cancel", comment: "Cancel button"), role: .cancel) { }
            }
        }
    }

    // MARK: - Account Card

    private var accountCard: some View {
        Button {
            if authManager.isLoggedIn {
                showingAccountActions = true
            } else {
                showingLoginSheet = true
            }
        } label: {
            HStack(spacing: 14) {
                if authManager.isLoggedIn, let user = authManager.currentUser {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.blue, .blue.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 50, height: 50)

                        Text(String(user.nickname.prefix(1)).uppercased())
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(user.nickname)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text(user.email)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    ZStack {
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 50, height: 50)

                        Image(systemName: "person.fill")
                            .font(.title2)
                            .foregroundStyle(.gray)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Guest", comment: "Guest user label")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text("Tap to log in", comment: "Guest user tap to login")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
        .foregroundColor(.primary)
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

    private func checkPushNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                pushPermissionDenied = settings.authorizationStatus == .denied
                // 권한이 거부된 상태면 토글도 꺼진 상태로
                if settings.authorizationStatus == .denied {
                    pushNotificationEnabled = false
                }
            }
        }
    }

    private func handlePushNotificationToggle(_ enabled: Bool) {
        #if DEBUG
        print("🔔 Push toggle changed to: \(enabled)")
        #endif

        if enabled {
            // 푸시 권한 요청
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                DispatchQueue.main.async {
                    #if DEBUG
                    print("🔔 Push authorization result: granted=\(granted), error=\(String(describing: error))")
                    #endif

                    if granted {
                        UIApplication.shared.registerForRemoteNotifications()
                        pushPermissionDenied = false
                        // 서버에 푸시 설정 동기화
                        syncPushSettingToServer(enabled: true)
                    } else {
                        pushNotificationEnabled = false
                        pushPermissionDenied = true
                    }
                }
            }
        } else {
            // 서버에 푸시 설정 동기화 (끄기)
            syncPushSettingToServer(enabled: false)
        }
    }

    private func syncPushSettingToServer(enabled: Bool) {
        guard authManager.isLoggedIn else {
            #if DEBUG
            print("🔔 Skip sync - not logged in")
            #endif
            return
        }

        #if DEBUG
        print("🔔 Syncing push setting to server: \(enabled)")
        #endif

        Task {
            do {
                try await authManager.updatePushSetting(enabled: enabled)
                #if DEBUG
                print("🔔 Push setting synced successfully: \(enabled)")
                #endif
            } catch {
                #if DEBUG
                print("🔔 Failed to sync push setting: \(error)")
                #endif
            }
        }
    }

    private func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(RoutineStore())
}
