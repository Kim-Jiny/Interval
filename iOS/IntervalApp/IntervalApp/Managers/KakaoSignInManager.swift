//
//  KakaoSignInManager.swift
//  IntervalApp
//
//  Created on 1/21/26.
//

import Foundation
import UIKit
import KakaoSDKCommon
import KakaoSDKAuth
import KakaoSDKUser

@MainActor
class KakaoSignInManager: NSObject, ObservableObject {
    static let shared = KakaoSignInManager()

    @Published var isSigningIn = false

    private override init() {
        super.init()
    }

    /// Kakao SDK 초기화 (AppDelegate에서 호출)
    static func initialize(appKey: String) {
        KakaoSDK.initSDK(appKey: appKey)
    }

    /// Kakao 로그인 수행
    /// - Returns: (accessToken, email, nickname)
    func signIn() async throws -> (accessToken: String, email: String?, nickname: String?) {
        isSigningIn = true
        defer { isSigningIn = false }

        return try await withCheckedThrowingContinuation { continuation in
            Task { @MainActor in
                // 카카오톡 설치 여부에 따라 분기
                if UserApi.isKakaoTalkLoginAvailable() {
                    UserApi.shared.loginWithKakaoTalk { oauthToken, error in
                        if let error = error {
                            continuation.resume(throwing: error)
                            return
                        }

                        guard let accessToken = oauthToken?.accessToken else {
                            continuation.resume(throwing: KakaoSignInError.noAccessToken)
                            return
                        }

                        // 사용자 정보 가져오기
                        self.fetchUserInfo(accessToken: accessToken, continuation: continuation)
                    }
                } else {
                    UserApi.shared.loginWithKakaoAccount { oauthToken, error in
                        if let error = error {
                            continuation.resume(throwing: error)
                            return
                        }

                        guard let accessToken = oauthToken?.accessToken else {
                            continuation.resume(throwing: KakaoSignInError.noAccessToken)
                            return
                        }

                        self.fetchUserInfo(accessToken: accessToken, continuation: continuation)
                    }
                }
            }
        }
    }

    private func fetchUserInfo(accessToken: String, continuation: CheckedContinuation<(accessToken: String, email: String?, nickname: String?), Error>) {
        UserApi.shared.me { user, error in
            if let error = error {
                continuation.resume(throwing: error)
                return
            }

            let email = user?.kakaoAccount?.email
            let nickname = user?.kakaoAccount?.profile?.nickname

            continuation.resume(returning: (accessToken, email, nickname))
        }
    }

    /// URL 처리 (AppDelegate에서 호출)
    func handleOpenUrl(_ url: URL) -> Bool {
        if AuthApi.isKakaoTalkLoginUrl(url) {
            return AuthController.handleOpenUrl(url: url)
        }
        return false
    }

    /// 로그아웃
    func logout() async {
        UserApi.shared.logout { error in
            if let error = error {
                print("Kakao logout error: \(error)")
            }
        }
    }
}

enum KakaoSignInError: LocalizedError {
    case notConfigured
    case noAccessToken
    case cancelled

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Kakao Sign-In SDK not configured yet"
        case .noAccessToken:
            return "Failed to get Kakao access token"
        case .cancelled:
            return "Kakao Sign-In was cancelled"
        }
    }
}
