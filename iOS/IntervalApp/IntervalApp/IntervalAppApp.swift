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
        // intervalApp://routine/SHARECODE
        // intervalApp://workout/SHARECODE

        #if DEBUG
        print("🔗 Deep link received: \(url.absoluteString)")
        print("🔗 Scheme: \(url.scheme ?? "nil")")
        print("🔗 Host: \(url.host ?? "nil")")
        print("🔗 Path: \(url.path)")
        print("🔗 PathComponents: \(url.pathComponents)")
        #endif

        guard url.scheme?.lowercased() == "intervalapp" else {
            print("🔗 Invalid scheme")
            return
        }

        let host = url.host

        // pathComponents에서 share code 추출
        // intervalApp://routine/ABC123 -> path = "/ABC123" -> pathComponents = ["/", "ABC123"]
        var shareCode: String?
        if url.pathComponents.count > 1 {
            shareCode = url.pathComponents[1]
        } else if !url.path.isEmpty {
            // path가 "/ABC123" 형태일 경우
            shareCode = String(url.path.dropFirst())
        }

        #if DEBUG
        print("🔗 Extracted shareCode: \(shareCode ?? "nil")")
        #endif

        switch host {
        case "workout":
            if let code = shareCode, !code.isEmpty {
                print("Open shared workout: \(code)")
            }
        case "routine":
            if let code = shareCode, !code.isEmpty {
                print("🔗 Fetching routine with code: \(code)")
                Task { @MainActor in
                    do {
                        try await RoutineShareManager.shared.fetchRoutine(code: code)
                        print("🔗 Routine fetched successfully, showShareConfirmation: \(RoutineShareManager.shared.showShareConfirmation)")
                    } catch {
                        print("🔗 Failed to fetch shared routine: \(error)")
                    }
                }
            } else {
                print("🔗 No share code found")
            }
        case "challenge":
            if let code = shareCode, !code.isEmpty {
                print("🔗 Fetching challenge with code: \(code)")
                Task { @MainActor in
                    await ChallengeManager.shared.handleDeepLink(shareCode: code)
                    print("🔗 Challenge deep link handled, showJoinConfirmation: \(ChallengeManager.shared.showJoinConfirmation)")
                }
            } else {
                print("🔗 No share code found for challenge")
            }
        default:
            print("🔗 Unknown host: \(host ?? "nil")")
        }
    }
}
