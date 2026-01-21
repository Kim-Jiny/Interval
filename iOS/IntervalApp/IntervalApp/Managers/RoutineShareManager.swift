//
//  RoutineShareManager.swift
//  IntervalApp
//
//  Created on 1/21/26.
//

import Foundation
import SwiftUI

// MARK: - Shared Routine Model

struct SharedRoutine: Codable {
    let id: Int
    let shareCode: String
    let name: String
    let description: String?
    let intervals: [SharedInterval]
    let rounds: Int
    let totalDuration: Int
    let downloadCount: Int?
    let likeCount: Int?
    let author: String?
    let createdAt: String?
}

struct SharedInterval: Codable {
    let id: String?
    let name: String
    let duration: Double
    let type: String
}

// MARK: - API Response

struct ShareRoutineResponse: Codable {
    let success: Bool
    let routine: SharedRoutineInfo?
    let shareUrl: String?
    let error: String?
}

struct SharedRoutineInfo: Codable {
    let id: Int
    let shareCode: String
    let name: String
    let description: String?
    let rounds: Int
    let totalDuration: Int
    let isPublic: Bool
}

struct GetRoutineResponse: Codable {
    let success: Bool
    let routine: SharedRoutine?
    let error: String?
}

// MARK: - RoutineShareManager

@MainActor
class RoutineShareManager: ObservableObject {
    static let shared = RoutineShareManager()

    private var baseURL: String {
        #if DEBUG
        return "http://kjiny.shop/Interval/api"
        #else
        return "http://kjiny.shop/Interval/api"
        #endif
    }

    // 공유받은 루틴 상태
    @Published var pendingRoutine: SharedRoutine?
    @Published var showShareConfirmation = false
    @Published var isLoading = false
    @Published var errorMessage: String?

    private init() {}

    // MARK: - Share Routine

    /// 루틴 공유하기 (DB에 저장하고 공유 URL 받기)
    func shareRoutine(_ routine: Routine) async throws -> String {
        guard let accessToken = AuthManager.shared.getAccessToken() else {
            throw ShareError.notLoggedIn
        }

        isLoading = true
        defer { isLoading = false }

        let url = URL(string: "\(baseURL)/routines/share.php")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        // intervals 변환
        let intervals = routine.intervals.map { interval -> [String: Any] in
            return [
                "id": interval.id.uuidString,
                "name": interval.name,
                "duration": interval.duration,
                "type": interval.type.rawValue
            ]
        }

        let body: [String: Any] = [
            "name": routine.name,
            "description": "",
            "intervals": intervals,
            "rounds": routine.rounds,
            "isPublic": true
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ShareError.networkError
        }

        #if DEBUG
        if let jsonString = String(data: data, encoding: .utf8) {
            print("📤 Share Routine Response (\(httpResponse.statusCode)): \(jsonString)")
        }
        #endif

        let shareResponse = try JSONDecoder().decode(ShareRoutineResponse.self, from: data)

        if httpResponse.statusCode == 200, shareResponse.success, let shareUrl = shareResponse.shareUrl {
            return shareUrl
        } else {
            throw ShareError.serverError(shareResponse.error ?? "Failed to share routine")
        }
    }

    // MARK: - Fetch Shared Routine

    /// 공유 코드로 루틴 가져오기
    func fetchRoutine(code: String) async throws {
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        let url = URL(string: "\(baseURL)/routines/get.php?code=\(code)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ShareError.networkError
        }

        #if DEBUG
        if let jsonString = String(data: data, encoding: .utf8) {
            print("📥 Get Routine Response (\(httpResponse.statusCode)): \(jsonString)")
        }
        #endif

        let getResponse = try JSONDecoder().decode(GetRoutineResponse.self, from: data)

        if httpResponse.statusCode == 200, getResponse.success, let routine = getResponse.routine {
            #if DEBUG
            print("📥 Setting pendingRoutine: \(routine.name)")
            print("📥 showShareConfirmation will be set to true")
            #endif
            pendingRoutine = routine
            showShareConfirmation = true
            #if DEBUG
            print("📥 showShareConfirmation is now: \(showShareConfirmation)")
            #endif
        } else if httpResponse.statusCode == 404 {
            throw ShareError.notFound
        } else {
            throw ShareError.serverError(getResponse.error ?? "Failed to get routine")
        }
    }

    // MARK: - Convert to Local Routine

    /// 공유받은 루틴을 로컬 Routine으로 변환
    func convertToRoutine(_ shared: SharedRoutine) -> Routine {
        let intervals = shared.intervals.map { interval -> WorkoutInterval in
            let type = IntervalType(rawValue: interval.type) ?? .workout
            return WorkoutInterval(
                name: interval.name,
                duration: interval.duration,
                type: type
            )
        }

        return Routine(
            name: shared.name,
            intervals: intervals,
            rounds: shared.rounds
        )
    }

    /// 확인 후 루틴 추가
    func addPendingRoutine(to store: RoutineStore) {
        guard let pending = pendingRoutine else { return }

        let routine = convertToRoutine(pending)
        store.addRoutine(routine)

        // 상태 초기화
        pendingRoutine = nil
        showShareConfirmation = false
    }

    /// 취소
    func cancelPendingRoutine() {
        pendingRoutine = nil
        showShareConfirmation = false
    }
}

// MARK: - Share Error

enum ShareError: LocalizedError {
    case notLoggedIn
    case networkError
    case notFound
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .notLoggedIn:
            return String(localized: "Please log in to share routines.", comment: "Share error - not logged in")
        case .networkError:
            return String(localized: "Network error. Please try again.", comment: "Share error - network")
        case .notFound:
            return String(localized: "Routine not found or no longer available.", comment: "Share error - not found")
        case .serverError(let message):
            return message
        }
    }
}
