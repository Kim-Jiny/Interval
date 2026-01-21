//
//  LoginView.swift
//  IntervalApp
//
//  Created on 1/21/26.
//

import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var authManager = AuthManager.shared

    @State private var errorMessage: String?
    @State private var showError = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                // 로고
                Image("splash")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)

                Text("IntervalMate")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Log in to share routines\nand track your workouts", comment: "Login screen description")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Spacer()

                // 소셜 로그인 버튼들
                VStack(spacing: 12) {
                    // Apple 로그인
                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.fullName, .email]
                    } onCompletion: { result in
                        Task {
                            await handleAppleSignIn(result)
                        }
                    }
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 50)
                    .cornerRadius(12)

                    // Google 로그인
                    Button {
                        Task {
                            await signInWithGoogle()
                        }
                    } label: {
                        HStack {
                            Image("google_logo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                            Text("Sign in with Google", comment: "Google sign in button")
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.white)
                        .foregroundStyle(.black.opacity(0.8))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                    }

                    // 카카오 로그인
                    Button {
                        Task {
                            await signInWithKakao()
                        }
                    } label: {
                        HStack {
                            Image("kakao_logo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                            Text("Sign in with Kakao", comment: "Kakao sign in button")
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color(red: 254/255, green: 229/255, blue: 0))
                        .foregroundStyle(.black.opacity(0.85))
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                .disabled(authManager.isLoading)

                if authManager.isLoading {
                    ProgressView()
                        .padding()
                }

                // 게스트로 계속하기
                Button {
                    dismiss()
                } label: {
                    Text("Continue as Guest", comment: "Button to continue without logging in")
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 8)

                Spacer()
                    .frame(height: 40)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .alert(String(localized: "Login Error", comment: "Login error alert title"), isPresented: $showError) {
                Button(String(localized: "OK", comment: "OK button"), role: .cancel) {}
            } message: {
                Text(errorMessage ?? String(localized: "Unknown error", comment: "Unknown error message"))
            }
            .onChange(of: authManager.isLoggedIn) { _, isLoggedIn in
                if isLoggedIn {
                    dismiss()
                }
            }
        }
    }

    // MARK: - Apple Sign In

    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) async {
        switch result {
        case .success(let authorization):
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let identityTokenData = appleIDCredential.identityToken,
                  let identityToken = String(data: identityTokenData, encoding: .utf8) else {
                errorMessage = "Failed to get Apple ID credentials"
                showError = true
                return
            }

            let email = appleIDCredential.email
            let fullName = appleIDCredential.fullName
            let nickname = [fullName?.givenName, fullName?.familyName]
                .compactMap { $0 }
                .joined(separator: " ")

            do {
                try await authManager.socialLogin(
                    provider: .apple,
                    providerToken: identityToken,
                    email: email,
                    nickname: nickname.isEmpty ? nil : nickname
                )
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }

        case .failure(let error):
            if (error as NSError).code != ASAuthorizationError.canceled.rawValue {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }

    // MARK: - Google Sign In

    private func signInWithGoogle() async {
        do {
            let result = try await GoogleSignInManager.shared.signIn()

            try await authManager.socialLogin(
                provider: .google,
                providerToken: result.idToken,
                email: result.email,
                nickname: result.name
            )
        } catch {
            // 취소된 경우 에러 표시 안함
            if (error as NSError).code != -5 { // GIDSignInError.canceled
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }

    // MARK: - Kakao Sign In

    private func signInWithKakao() async {
        do {
            let result = try await KakaoSignInManager.shared.signIn()

            try await authManager.socialLogin(
                provider: .kakao,
                providerToken: result.accessToken,
                email: result.email,
                nickname: result.nickname
            )
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

// MARK: - Login Prompt View

struct LoginPromptView: View {
    @Binding var isPresented: Bool
    let message: String
    let onLogin: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.crop.circle.badge.exclamationmark")
                .font(.system(size: 50))
                .foregroundStyle(.orange)

            Text("Login Required", comment: "Login required title")
                .font(.title2)
                .fontWeight(.bold)

            Text(message)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            VStack(spacing: 12) {
                Button {
                    onLogin()
                } label: {
                    Text("Log In", comment: "Log in button")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .cornerRadius(12)
                }

                Button {
                    isPresented = false
                } label: {
                    Text("Cancel", comment: "Cancel button")
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal)
        }
        .padding()
    }
}

#Preview {
    LoginView()
}
