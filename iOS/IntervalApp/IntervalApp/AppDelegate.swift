//
//  AppDelegate.swift
//  IntervalApp
//
//  Created on 1/21/26.
//

import UIKit
import UserNotifications
import GoogleMobileAds

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self

        // 앱 시작 시 배지 초기화
        clearBadge()

        // ATT 요청 → 완료 후 푸시 권한 요청
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            print("📺 Starting ATT + Push flow...")
            AdManager.shared.configure {
                print("📺 ATT completed, requesting push...")
                self?.registerForPushNotifications()
            }
        }

        return true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // 앱이 포그라운드로 올 때 배지 초기화
        clearBadge()
    }

    private func clearBadge() {
        UNUserNotificationCenter.current().setBadgeCount(0) { error in
            if let error = error {
                print("❌ Failed to clear badge: \(error)")
            }
        }
    }

    // MARK: - Push Notifications

    private func registerForPushNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }

            #if DEBUG
            print("📱 Push notification permission: \(granted ? "granted" : "denied")")
            if let error = error {
                print("❌ Push permission error: \(error)")
            }
            #endif
        }
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()

        #if DEBUG
        print("📱 APNS Token: \(token)")
        #endif

        // AuthManager에 토큰 저장
        Task { @MainActor in
            AuthManager.shared.apnsToken = token
            // 로그인 상태라면 서버에 토큰 전송
            if AuthManager.shared.isLoggedIn {
                try? await AuthManager.shared.updateAPNSToken(token)
            }
        }
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        #if DEBUG
        print("❌ Failed to register for remote notifications: \(error)")
        #endif
    }

    // MARK: - UNUserNotificationCenterDelegate

    // 앱이 포그라운드일 때 알림 표시
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }

    // 알림 탭 처리
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        handleNotification(userInfo: userInfo)
        completionHandler()
    }

    private func handleNotification(userInfo: [AnyHashable: Any]) {
        // 푸시 알림 데이터 처리
        #if DEBUG
        print("📱 Received notification: \(userInfo)")
        #endif
    }
}
