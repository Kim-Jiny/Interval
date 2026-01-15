//
//  IntervalWatchApp.swift
//  IntervalApp Watch App
//
//  Created by Claude on 1/15/26.
//

import SwiftUI
import UserNotifications

@main
struct IntervalWatchApp: App {
    @StateObject private var connectivityManager = WatchConnectivityManager.shared
    @StateObject private var routineStore = WatchRoutineStore.shared
    @WKApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            WatchContentView()
                .environmentObject(connectivityManager)
                .environmentObject(routineStore)
        }
    }
}

// MARK: - App Delegate for Notification Handling
class AppDelegate: NSObject, WKApplicationDelegate, UNUserNotificationCenterDelegate {

    func applicationDidFinishLaunching() {
        // 알림 delegate 설정
        UNUserNotificationCenter.current().delegate = self
    }

    // 앱이 포그라운드일 때 알림 표시 방법
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // 앱이 포그라운드일 때는 알림 표시하지 않음 (이미 타이머 화면으로 이동)
        completionHandler([])
    }

    // 알림 탭 처리
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // TIMER_START 카테고리 알림이면 타이머 화면으로 이동
        if response.notification.request.content.categoryIdentifier == "TIMER_START" {
            // 이미 pendingTimerStart가 설정되어 있으므로 앱이 열리면 자동 이동
            // WatchContentView의 onAppear에서 처리됨
        }
        completionHandler()
    }
}
