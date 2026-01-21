//
//  IntervalAppApp.swift
//  IntervalApp
//
//  Created by 김미진 on 1/14/26.
//

import SwiftUI
import KakaoSDKCommon
import KakaoSDKAuth

@main
struct IntervalAppApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var routineStore = RoutineStore()

    init() {
        // Kakao SDK 초기화
        KakaoSDK.initSDK(appKey: "ffd04ea2b7cd15d6325dba4bc2acbdc8")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(routineStore)
                .onOpenURL { url in
                    // Kakao 로그인 URL 처리
                    if AuthApi.isKakaoTalkLoginUrl(url) {
                        _ = AuthController.handleOpenUrl(url: url)
                        return
                    }

                    // Google 로그인 URL 처리
                    if GoogleSignInManager.shared.handle(url) {
                        return
                    }

                    // 앱 딥링크 처리 (intervalApp://)
                    handleDeepLink(url)
                }
        }
    }

    private func handleDeepLink(_ url: URL) {
        // intervalApp://workout/SHARECODE
        // intervalApp://routine/SHARECODE
        guard url.scheme == "intervalApp" else { return }

        let host = url.host
        let path = url.pathComponents.dropFirst().first

        switch host {
        case "workout":
            if let shareCode = path {
                // 운동 기록 공유 처리
                print("Open shared workout: \(shareCode)")
            }
        case "routine":
            if let shareCode = path {
                // 루틴 공유 처리
                print("Open shared routine: \(shareCode)")
            }
        default:
            break
        }
    }
}
