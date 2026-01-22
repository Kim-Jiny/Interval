//
//  ChallengeManager.swift
//  IntervalApp
//
//  Created by Claude on 2024.
//

import Foundation

@MainActor
class ChallengeManager: ObservableObject {
    static let shared = ChallengeManager()

    // API Base URL
    private var baseURL: String {
        ConfigManager.apiBaseURL
    }

    // Published state
    @Published var joinableChallenges: [ChallengeListItem] = []
    @Published var myChallenges: [ChallengeListItem] = []
    @Published var currentChallenge: Challenge?
    @Published var currentParticipants: [ChallengeParticipant] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // For deep link handling
    @Published var pendingChallenge: Challenge?
    @Published var showJoinConfirmation: Bool = false
    @Published var showDeepLinkError: Bool = false
    @Published var deepLinkErrorMessage: String?
    @Published var showAlreadyParticipating: Bool = false
    @Published var showCannotJoin: Bool = false

    /// 진행 중인 챌린지만 (홈화면용)
    /// 현재 시간이 챌린지 시작~종료 사이인 것만 표시
    var activeChallenges: [ChallengeListItem] {
        myChallenges.filter { $0.isCurrentlyActive }
    }

    // Pagination for joinable challenges
    @Published var joinableCurrentPage: Int = 1
    @Published var joinableTotalPages: Int = 1
    @Published var joinableHasMorePages: Bool = false

    private init() {}

    // MARK: - Clear User Data (on logout)

    /// 로그아웃 시 사용자 관련 데이터 초기화
    func clearUserData() {
        myChallenges = []
        currentChallenge = nil
        currentParticipants = []
        pendingChallenge = nil
        showJoinConfirmation = false
        showDeepLinkError = false
        deepLinkErrorMessage = nil
        showAlreadyParticipating = false
        showCannotJoin = false
    }

    // MARK: - Fetch Public Challenges

    func fetchJoinableChallenges(page: Int = 1) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            // 기본값: 모집 중(registration) + 진행 중(active) 챌린지
            var urlString = "\(baseURL)/challenges/list.php?page=\(page)"

            var request = URLRequest(url: URL(string: urlString)!)
            request.httpMethod = "GET"

            // Add auth token if available
            if let accessToken = AuthManager.shared.getAccessToken() {
                request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            }

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw ChallengeError.networkError
            }

            #if DEBUG
            if let jsonString = String(data: data, encoding: .utf8) {
                print("🏆 Joinable Challenges Response (\(httpResponse.statusCode)): \(jsonString)")
            }
            #endif

            let listResponse = try JSONDecoder().decode(ChallengeListResponse.self, from: data)

            if listResponse.success {
                if page == 1 {
                    self.joinableChallenges = listResponse.challenges
                } else {
                    self.joinableChallenges.append(contentsOf: listResponse.challenges)
                }
                self.joinableCurrentPage = listResponse.pagination.page
                self.joinableTotalPages = listResponse.pagination.totalPages
                self.joinableHasMorePages = listResponse.pagination.page < listResponse.pagination.totalPages
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Fetch My Challenges

    func fetchMyChallenges(type: String = "all") async {
        guard let accessToken = AuthManager.shared.getAccessToken() else {
            errorMessage = "Please log in first"
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let url = URL(string: "\(baseURL)/challenges/my.php?type=\(type)")!
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw ChallengeError.networkError
            }

            #if DEBUG
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📋 My Challenges Response (\(httpResponse.statusCode)): \(jsonString)")
            }
            #endif

            if httpResponse.statusCode == 401 {
                try await AuthManager.shared.refreshTokenIfNeeded()
                await fetchMyChallenges(type: type)
                return
            }

            let listResponse = try JSONDecoder().decode(ChallengeListResponse.self, from: data)

            if listResponse.success {
                self.myChallenges = listResponse.challenges
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Fetch Challenge by Code

    func fetchChallenge(code: String) async throws -> Challenge {
        let url = URL(string: "\(baseURL)/challenges/get.php?code=\(code)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        if let accessToken = AuthManager.shared.getAccessToken() {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ChallengeError.networkError
        }

        #if DEBUG
        if let jsonString = String(data: data, encoding: .utf8) {
            print("🔍 Challenge Get Response (\(httpResponse.statusCode)): \(jsonString)")
        }
        #endif

        struct GetResponse: Codable {
            let success: Bool
            let challenge: Challenge?
            let error: String?
        }

        let getResponse = try JSONDecoder().decode(GetResponse.self, from: data)

        if let challenge = getResponse.challenge {
            return challenge
        } else {
            throw ChallengeError.notFound
        }
    }

    // MARK: - Fetch Challenge Detail

    func fetchChallengeDetail(id: Int) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            var url = URL(string: "\(baseURL)/challenges/detail.php?id=\(id)")!
            var request = URLRequest(url: url)
            request.httpMethod = "GET"

            if let accessToken = AuthManager.shared.getAccessToken() {
                request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            }

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw ChallengeError.networkError
            }

            #if DEBUG
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📄 Challenge Detail Response (\(httpResponse.statusCode)): \(jsonString)")
            }
            #endif

            let detailResponse = try JSONDecoder().decode(ChallengeDetailResponse.self, from: data)

            if detailResponse.success {
                self.currentChallenge = detailResponse.challenge
                self.currentParticipants = detailResponse.participants
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Create Challenge

    func createChallenge(
        title: String,
        description: String?,
        routine: Routine,
        registrationEndAt: Date,
        challengeStartAt: Date,
        challengeEndAt: Date,
        isPublic: Bool,
        maxParticipants: Int?,
        entryFee: Int
    ) async throws -> (Challenge, String) {
        guard let accessToken = AuthManager.shared.getAccessToken() else {
            throw ChallengeError.notLoggedIn
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let url = URL(string: "\(baseURL)/challenges/create.php")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        // Convert routine to JSON format
        let routineData: [String: Any] = [
            "intervals": routine.intervals.map { interval in
                [
                    "name": interval.name,
                    "duration": Int(interval.duration),
                    "type": interval.type.rawValue
                ]
            },
            "rounds": routine.rounds
        ]

        var body: [String: Any] = [
            "title": title,
            "routineName": routine.name,
            "routineData": routineData,
            "registrationEndAt": dateFormatter.string(from: registrationEndAt),
            "challengeStartAt": dateFormatter.string(from: challengeStartAt),
            "challengeEndAt": dateFormatter.string(from: challengeEndAt),
            "isPublic": isPublic ? 1 : 0,
            "entryFee": entryFee
        ]

        if let description = description, !description.isEmpty {
            body["description"] = description
        }
        if let maxParticipants = maxParticipants {
            body["maxParticipants"] = maxParticipants
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ChallengeError.networkError
        }

        #if DEBUG
        if let jsonString = String(data: data, encoding: .utf8) {
            print("✨ Challenge Create Response (\(httpResponse.statusCode)): \(jsonString)")
        }
        #endif

        if httpResponse.statusCode == 401 {
            try await AuthManager.shared.refreshTokenIfNeeded()
            return try await createChallenge(
                title: title,
                description: description,
                routine: routine,
                registrationEndAt: registrationEndAt,
                challengeStartAt: challengeStartAt,
                challengeEndAt: challengeEndAt,
                isPublic: isPublic,
                maxParticipants: maxParticipants,
                entryFee: entryFee
            )
        }

        let createResponse = try JSONDecoder().decode(ChallengeCreateResponse.self, from: data)

        if createResponse.success {
            // Refresh mileage balance
            await MileageManager.shared.fetchBalance()
            // Refresh challenge lists
            await fetchMyChallenges()
            await fetchJoinableChallenges()
            return (createResponse.challenge, createResponse.shareUrl)
        } else {
            throw ChallengeError.serverError("Failed to create challenge")
        }
    }

    // MARK: - Join Challenge

    func joinChallenge(id: Int? = nil, shareCode: String? = nil) async throws {
        guard let accessToken = AuthManager.shared.getAccessToken() else {
            throw ChallengeError.notLoggedIn
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let url = URL(string: "\(baseURL)/challenges/join.php")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        var body: [String: Any] = [:]
        if let id = id {
            body["challengeId"] = id
        }
        if let shareCode = shareCode {
            body["shareCode"] = shareCode
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ChallengeError.networkError
        }

        #if DEBUG
        if let jsonString = String(data: data, encoding: .utf8) {
            print("🤝 Challenge Join Response (\(httpResponse.statusCode)): \(jsonString)")
        }
        #endif

        if httpResponse.statusCode == 401 {
            try await AuthManager.shared.refreshTokenIfNeeded()
            try await joinChallenge(id: id, shareCode: shareCode)
            return
        }

        struct ErrorResponse: Codable {
            let error: String?
        }

        if httpResponse.statusCode != 200 {
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw ChallengeError.serverError(errorResponse.error ?? "Failed to join challenge")
            }
            throw ChallengeError.serverError("Failed to join challenge")
        }

        let joinResponse = try JSONDecoder().decode(ChallengeJoinResponse.self, from: data)

        if joinResponse.success {
            // Refresh mileage balance
            await MileageManager.shared.fetchBalance()
            // Refresh my challenges
            await fetchMyChallenges()
        } else {
            throw ChallengeError.serverError("Failed to join challenge")
        }
    }

    // MARK: - Leave Challenge

    func leaveChallenge(id: Int) async throws -> Int {
        guard let accessToken = AuthManager.shared.getAccessToken() else {
            throw ChallengeError.notLoggedIn
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let url = URL(string: "\(baseURL)/challenges/leave.php")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let body: [String: Any] = ["challengeId": id]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ChallengeError.networkError
        }

        #if DEBUG
        if let jsonString = String(data: data, encoding: .utf8) {
            print("👋 Challenge Leave Response (\(httpResponse.statusCode)): \(jsonString)")
        }
        #endif

        if httpResponse.statusCode == 401 {
            try await AuthManager.shared.refreshTokenIfNeeded()
            return try await leaveChallenge(id: id)
        }

        struct ErrorResponse: Codable {
            let error: String?
        }

        if httpResponse.statusCode != 200 {
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw ChallengeError.serverError(errorResponse.error ?? "Failed to leave challenge")
            }
            throw ChallengeError.serverError("Failed to leave challenge")
        }

        let leaveResponse = try JSONDecoder().decode(ChallengeLeaveResponse.self, from: data)

        if leaveResponse.success {
            // Refresh mileage balance
            await MileageManager.shared.fetchBalance()
            // Refresh my challenges
            await fetchMyChallenges()
            return leaveResponse.refundedAmount
        } else {
            throw ChallengeError.serverError("Failed to leave challenge")
        }
    }

    // MARK: - Record Workout

    func recordWorkout(challengeId: Int, totalDuration: Int, roundsCompleted: Int) async throws {
        guard let accessToken = AuthManager.shared.getAccessToken() else {
            throw ChallengeError.notLoggedIn
        }

        let url = URL(string: "\(baseURL)/challenges/record-workout.php")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let body: [String: Any] = [
            "challengeId": challengeId,
            "totalDuration": totalDuration,
            "roundsCompleted": roundsCompleted,
            "workoutDate": dateFormatter.string(from: Date())
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ChallengeError.networkError
        }

        #if DEBUG
        if let jsonString = String(data: data, encoding: .utf8) {
            print("🏃 Record Workout Response (\(httpResponse.statusCode)): \(jsonString)")
        }
        #endif

        if httpResponse.statusCode == 401 {
            try await AuthManager.shared.refreshTokenIfNeeded()
            try await recordWorkout(challengeId: challengeId, totalDuration: totalDuration, roundsCompleted: roundsCompleted)
            return
        }

        struct ErrorResponse: Codable {
            let error: String?
        }

        if httpResponse.statusCode != 200 {
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw ChallengeError.serverError(errorResponse.error ?? "Failed to record workout")
            }
            throw ChallengeError.serverError("Failed to record workout")
        }

        // Mark as completed locally
        markTodayCompleted(challengeId: challengeId)
    }

    /// Mark a challenge as completed for today (local update)
    func markTodayCompleted(challengeId: Int) {
        if let index = myChallenges.firstIndex(where: { $0.id == challengeId }) {
            myChallenges[index].todayCompleted = true
        }
    }

    // MARK: - Finalize Challenge (Prize Distribution)

    func finalizeChallenge(id: Int) async throws -> [FinalRanking] {
        guard let accessToken = AuthManager.shared.getAccessToken() else {
            throw ChallengeError.notLoggedIn
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let url = URL(string: "\(baseURL)/challenges/finalize.php")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let body: [String: Any] = ["challengeId": id]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ChallengeError.networkError
        }

        #if DEBUG
        if let jsonString = String(data: data, encoding: .utf8) {
            print("🏆 Challenge Finalize Response (\(httpResponse.statusCode)): \(jsonString)")
        }
        #endif

        if httpResponse.statusCode == 401 {
            try await AuthManager.shared.refreshTokenIfNeeded()
            return try await finalizeChallenge(id: id)
        }

        struct ErrorResponse: Codable {
            let error: String?
        }

        if httpResponse.statusCode != 200 {
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw ChallengeError.serverError(errorResponse.error ?? "Failed to finalize challenge")
            }
            throw ChallengeError.serverError("Failed to finalize challenge")
        }

        let finalizeResponse = try JSONDecoder().decode(ChallengeFinalizeResponse.self, from: data)

        if finalizeResponse.success {
            // Refresh mileage balance
            await MileageManager.shared.fetchBalance()
            // Refresh challenge detail
            await fetchChallengeDetail(id: id)
            // Refresh my challenges
            await fetchMyChallenges()
            return finalizeResponse.results
        } else {
            throw ChallengeError.serverError("Failed to finalize challenge")
        }
    }

    // MARK: - Handle Deep Link

    func handleDeepLink(shareCode: String) async {
        #if DEBUG
        print("🔗 handleDeepLink called with shareCode: \(shareCode)")
        #endif

        do {
            let challenge = try await fetchChallenge(code: shareCode)
            #if DEBUG
            print("🔗 Challenge fetched: \(challenge.title), isParticipating: \(challenge.isParticipating ?? false)")
            #endif
            self.pendingChallenge = challenge

            // 이미 참여 중인 경우
            if challenge.isParticipating == true {
                self.showAlreadyParticipating = true
            }
            // 모집 기간인지 확인
            else if let regStart = challenge.registrationStartDate,
                    let regEnd = challenge.registrationEndDate {
                let now = Date()
                if now >= regStart && now <= regEnd {
                    // 모집 기간 내 - 참가 가능
                    self.showJoinConfirmation = true
                } else {
                    // 모집 기간 아님
                    self.showCannotJoin = true
                }
            }
            // 날짜 파싱 실패 시 canJoin 필드로 폴백
            else if challenge.canJoin == true {
                self.showJoinConfirmation = true
            } else {
                self.showCannotJoin = true
            }
        } catch {
            #if DEBUG
            print("🔗 Deep link error: \(error.localizedDescription)")
            #endif
            self.deepLinkErrorMessage = error.localizedDescription
            self.showDeepLinkError = true
        }
    }

    func confirmJoinPendingChallenge() async throws {
        guard let challenge = pendingChallenge else { return }

        try await joinChallenge(id: challenge.id)
        pendingChallenge = nil
        showJoinConfirmation = false
    }

    func cancelPendingChallenge() {
        pendingChallenge = nil
        showJoinConfirmation = false
    }

    // MARK: - Refresh All

    func refreshAll() async {
        await fetchJoinableChallenges()
        if AuthManager.shared.isLoggedIn {
            await fetchMyChallenges()
        }
    }
}

// MARK: - Challenge Error

enum ChallengeError: LocalizedError {
    case networkError
    case serverError(String)
    case notLoggedIn
    case notFound
    case alreadyParticipating
    case registrationClosed
    case challengeFull

    var errorDescription: String? {
        switch self {
        case .networkError:
            return String(localized: "Network error. Please try again.")
        case .serverError(let message):
            return message
        case .notLoggedIn:
            return String(localized: "Please log in first.")
        case .notFound:
            return String(localized: "Challenge not found.")
        case .alreadyParticipating:
            return String(localized: "You are already participating in this challenge.")
        case .registrationClosed:
            return String(localized: "Registration period has ended.")
        case .challengeFull:
            return String(localized: "This challenge is full.")
        }
    }
}
