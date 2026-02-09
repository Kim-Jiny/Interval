//
//  AuthManager.swift
//  IntervalApp
//
//  Created on 1/21/26.
//

import Foundation
import SwiftUI
import AuthenticationServices
import CryptoKit

// MARK: - User Model

struct User: Codable {
    let id: Int
    let email: String
    let name: String?
    var nickname: String
    let profileImage: String?
    let provider: String?
}

// MARK: - Auth Response

struct AuthResponse: Codable {
    let success: Bool
    let user: User?
    let accessToken: String?
    let refreshToken: String?
    let error: String?
}

// MARK: - Social Login Provider

enum SocialLoginProvider: String {
    case apple = "apple"
    case google = "google"
    case kakao = "kakao"
}

// MARK: - AuthManager

@MainActor
class AuthManager: NSObject, ObservableObject {
    static let shared = AuthManager()

    // API Base URL
    private var baseURL: String {
        ConfigManager.apiBaseURL
    }

    // Published 상태
    @Published var isLoggedIn: Bool = false
    @Published var currentUser: User?
    @Published var isLoading: Bool = false

    // APNS Token
    var apnsToken: String?

    // Apple Sign In
    private var currentNonce: String?
    private var appleSignInCompletion: ((Result<Void, Error>) -> Void)?

    // 토큰 저장 키
    private let accessTokenKey = "accessToken"
    private let refreshTokenKey = "refreshToken"
    private let userKey = "currentUser"

    override private init() {
        super.init()
        loadSavedSession()
    }

    // MARK: - Session Management

    private func loadSavedSession() {
        if let userData = UserDefaults.standard.data(forKey: userKey),
           let user = try? JSONDecoder().decode(User.self, from: userData),
           getAccessToken() != nil {
            self.currentUser = user
            self.isLoggedIn = true
        }
    }

    private func saveSession(user: User, accessToken: String, refreshToken: String) {
        UserDefaults.standard.set(accessToken, forKey: accessTokenKey)
        UserDefaults.standard.set(refreshToken, forKey: refreshTokenKey)

        if let userData = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(userData, forKey: userKey)
        }

        self.currentUser = user
        self.isLoggedIn = true
    }

    private func clearSession() {
        UserDefaults.standard.removeObject(forKey: accessTokenKey)
        UserDefaults.standard.removeObject(forKey: refreshTokenKey)
        UserDefaults.standard.removeObject(forKey: userKey)

        self.currentUser = nil
        self.isLoggedIn = false

        // 사용자 관련 데이터 초기화
        ChallengeManager.shared.clearUserData()
        MileageManager.shared.clearUserData()
        WorkoutHistoryManager.shared.clearUserData()
    }

    func getAccessToken() -> String? {
        return UserDefaults.standard.string(forKey: accessTokenKey)
    }

    private func getRefreshToken() -> String? {
        return UserDefaults.standard.string(forKey: refreshTokenKey)
    }

    // MARK: - Social Login API

    /// 소셜 로그인 (서버로 토큰/정보 전송)
    func socialLogin(provider: SocialLoginProvider, providerToken: String, email: String?, nickname: String?) async throws {
        isLoading = true
        defer { isLoading = false }

        let url = URL(string: "\(baseURL)/auth/social.php")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var body: [String: Any] = [
            "provider": provider.rawValue,
            "providerToken": providerToken
        ]
        if let email = email { body["email"] = email }
        if let nickname = nickname { body["nickname"] = nickname }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.networkError
        }

        // 디버깅용 - 서버 응답 출력
        #if DEBUG
        if let jsonString = String(data: data, encoding: .utf8) {
            print("🔐 Social Login Response (\(httpResponse.statusCode)): \(jsonString)")
        }
        #endif

        let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)

        if httpResponse.statusCode == 200, authResponse.success,
           let user = authResponse.user,
           let accessToken = authResponse.accessToken,
           let refreshToken = authResponse.refreshToken {
            saveSession(user: user, accessToken: accessToken, refreshToken: refreshToken)

            // 로그인 성공 후 APNS 토큰 전송
            if let apnsToken = apnsToken {
                try? await updateAPNSToken(apnsToken)
            }
        } else {
            throw AuthError.serverError(authResponse.error ?? "Login failed")
        }
    }

    /// 로그아웃
    func logout() {
        clearSession()
    }

    /// 회원 탈퇴
    func deleteAccount() async throws {
        guard let accessToken = getAccessToken() else {
            throw AuthError.notLoggedIn
        }

        isLoading = true
        defer { isLoading = false }

        let url = URL(string: "\(baseURL)/auth/delete.php")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.networkError
        }

        #if DEBUG
        if let jsonString = String(data: data, encoding: .utf8) {
            print("🗑️ Delete Account Response (\(httpResponse.statusCode)): \(jsonString)")
        }
        #endif

        if httpResponse.statusCode == 200 {
            clearSession()
        } else {
            let errorResponse = try? JSONDecoder().decode(AuthResponse.self, from: data)
            throw AuthError.serverError(errorResponse?.error ?? "Failed to delete account")
        }
    }

    /// 닉네임 변경
    func updateNickname(_ newNickname: String) async throws {
        guard let accessToken = getAccessToken() else {
            throw AuthError.notLoggedIn
        }

        isLoading = true
        defer { isLoading = false }

        let url = URL(string: "\(baseURL)/auth/update-nickname.php")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let body: [String: Any] = ["nickname": newNickname]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.networkError
        }

        #if DEBUG
        if let jsonString = String(data: data, encoding: .utf8) {
            print("✏️ Update Nickname Response (\(httpResponse.statusCode)): \(jsonString)")
        }
        #endif

        let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)

        if httpResponse.statusCode == 200, authResponse.success, let user = authResponse.user {
            // 세션 업데이트 (토큰은 유지, 사용자 정보만 업데이트)
            if let userData = try? JSONEncoder().encode(user) {
                UserDefaults.standard.set(userData, forKey: userKey)
            }
            self.currentUser = user
        } else {
            throw AuthError.serverError(authResponse.error ?? "Failed to update nickname")
        }
    }

    /// APNS 토큰 업데이트
    func updateAPNSToken(_ token: String, isRetry: Bool = false) async throws {
        guard let accessToken = getAccessToken() else {
            throw AuthError.notLoggedIn
        }

        let url = URL(string: "\(baseURL)/auth/update-apns-token.php")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let body: [String: Any] = ["apnsToken": token]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.networkError
        }

        #if DEBUG
        if let jsonString = String(data: data, encoding: .utf8) {
            print("📱 Update APNS Token Response (\(httpResponse.statusCode)): \(jsonString)")
        }
        #endif

        // 401 에러 시 토큰 갱신 후 재시도
        if httpResponse.statusCode == 401 && !isRetry {
            try await refreshTokenIfNeeded()
            try await updateAPNSToken(token, isRetry: true)
            return
        }

        if httpResponse.statusCode != 200 {
            throw AuthError.serverError("Failed to update APNS token")
        }
    }

    /// 푸시 알림 설정 업데이트
    func updatePushSetting(enabled: Bool, isRetry: Bool = false) async throws {
        guard let accessToken = getAccessToken() else {
            throw AuthError.notLoggedIn
        }

        let url = URL(string: "\(baseURL)/auth/update-push-setting.php")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let body: [String: Any] = ["pushEnabled": enabled]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.networkError
        }

        #if DEBUG
        if let jsonString = String(data: data, encoding: .utf8) {
            print("🔔 Update Push Setting Response (\(httpResponse.statusCode)): \(jsonString)")
        }
        #endif

        // 401 에러 시 토큰 갱신 후 재시도
        if httpResponse.statusCode == 401 && !isRetry {
            try await refreshTokenIfNeeded()
            try await updatePushSetting(enabled: enabled, isRetry: true)
            return
        }

        if httpResponse.statusCode != 200 {
            throw AuthError.serverError("Failed to update push setting")
        }
    }

    /// 챌린지 푸시 알림 설정 업데이트
    func updateChallengePushSetting(enabled: Bool, isRetry: Bool = false) async throws {
        guard let accessToken = getAccessToken() else {
            throw AuthError.notLoggedIn
        }

        let url = URL(string: "\(baseURL)/auth/update-challenge-push-setting.php")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let body: [String: Any] = ["challengePushEnabled": enabled]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.networkError
        }

        #if DEBUG
        if let jsonString = String(data: data, encoding: .utf8) {
            print("🏁 Update Challenge Push Setting Response (\(httpResponse.statusCode)): \(jsonString)")
        }
        #endif

        if httpResponse.statusCode == 401 && !isRetry {
            try await refreshTokenIfNeeded()
            try await updateChallengePushSetting(enabled: enabled, isRetry: true)
            return
        }

        if httpResponse.statusCode != 200 {
            throw AuthError.serverError("Failed to update challenge push setting")
        }
    }

    /// 토큰 갱신
    func refreshTokenIfNeeded() async throws {
        guard let refreshToken = getRefreshToken() else {
            throw AuthError.notLoggedIn
        }

        let url = URL(string: "\(baseURL)/auth/refresh.php")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = ["refreshToken": refreshToken]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.networkError
        }

        if httpResponse.statusCode == 401 {
            clearSession()
            throw AuthError.sessionExpired
        }

        let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)

        if authResponse.success,
           let user = authResponse.user,
           let accessToken = authResponse.accessToken,
           let newRefreshToken = authResponse.refreshToken {
            saveSession(user: user, accessToken: accessToken, refreshToken: newRefreshToken)
        } else {
            clearSession()
            throw AuthError.sessionExpired
        }
    }

    var needsLogin: Bool {
        return !isLoggedIn
    }

    // MARK: - Sign in with Apple

    func signInWithApple() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            let nonce = randomNonceString()
            currentNonce = nonce
            appleSignInCompletion = { result in
                continuation.resume(with: result)
            }

            let appleIDProvider = ASAuthorizationAppleIDProvider()
            let request = appleIDProvider.createRequest()
            request.requestedScopes = [.fullName, .email]
            request.nonce = sha256(nonce)

            let authorizationController = ASAuthorizationController(authorizationRequests: [request])
            authorizationController.delegate = self
            authorizationController.performRequests()
        }
    }

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce.")
        }
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension AuthManager: ASAuthorizationControllerDelegate {
    nonisolated func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        Task { @MainActor in
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let identityTokenData = appleIDCredential.identityToken,
                  let identityToken = String(data: identityTokenData, encoding: .utf8) else {
                appleSignInCompletion?(.failure(AuthError.serverError("Failed to get Apple ID token")))
                return
            }

            let email = appleIDCredential.email
            let fullName = appleIDCredential.fullName
            let nickname = [fullName?.givenName, fullName?.familyName]
                .compactMap { $0 }
                .joined(separator: " ")

            do {
                try await socialLogin(
                    provider: .apple,
                    providerToken: identityToken,
                    email: email,
                    nickname: nickname.isEmpty ? nil : nickname
                )
                appleSignInCompletion?(.success(()))
            } catch {
                appleSignInCompletion?(.failure(error))
            }
        }
    }

    nonisolated func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        Task { @MainActor in
            appleSignInCompletion?(.failure(error))
        }
    }
}

// MARK: - Auth Error

enum AuthError: LocalizedError {
    case networkError
    case serverError(String)
    case notLoggedIn
    case sessionExpired
    case cancelled

    var errorDescription: String? {
        switch self {
        case .networkError:
            return String(localized: "Network error. Please try again.")
        case .serverError(let message):
            return message
        case .notLoggedIn:
            return String(localized: "Please log in first.")
        case .sessionExpired:
            return String(localized: "Session expired. Please log in again.")
        case .cancelled:
            return String(localized: "Login cancelled.")
        }
    }
}
