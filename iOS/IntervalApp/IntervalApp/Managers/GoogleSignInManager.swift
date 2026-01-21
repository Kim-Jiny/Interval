//
//  GoogleSignInManager.swift
//  IntervalApp
//
//  Created on 1/21/26.
//

import Foundation
import UIKit
import GoogleSignIn

@MainActor
class GoogleSignInManager: NSObject, ObservableObject {
    static let shared = GoogleSignInManager()

    @Published var isSigningIn = false

    private override init() {
        super.init()
    }

    /// Google Sign-In 수행
    /// - Returns: (idToken, email, name)
    func signIn() async throws -> (idToken: String, email: String?, name: String?) {
        isSigningIn = true
        defer { isSigningIn = false }

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            throw GoogleSignInError.noRootViewController
        }

        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)

        guard let idToken = result.user.idToken?.tokenString else {
            throw GoogleSignInError.noIdToken
        }

        return (
            idToken: idToken,
            email: result.user.profile?.email,
            name: result.user.profile?.name
        )
    }

    /// URL 처리 (AppDelegate에서 호출)
    func handle(_ url: URL) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }

    /// 앱 시작시 이전 로그인 상태 복원
    func restorePreviousSignIn() async -> Bool {
        do {
            let user = try await GIDSignIn.sharedInstance.restorePreviousSignIn()
            return true
        } catch {
            return false
        }
    }
}

enum GoogleSignInError: LocalizedError {
    case notConfigured
    case noRootViewController
    case noIdToken
    case cancelled

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Google Sign-In SDK not configured yet"
        case .noRootViewController:
            return "Unable to find root view controller"
        case .noIdToken:
            return "Failed to get Google ID token"
        case .cancelled:
            return "Google Sign-In was cancelled"
        }
    }
}
