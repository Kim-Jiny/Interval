//
//  WorkoutHistoryManager.swift
//  IntervalApp
//
//  Created on 1/26/26.
//

import Foundation

/// 앱 내 운동 기록 API 매니저
@MainActor
class WorkoutHistoryManager: ObservableObject {
    static let shared = WorkoutHistoryManager()

    private var baseURL: String {
        ConfigManager.apiBaseURL
    }

    @Published var monthlyRecords: [String: [WorkoutRecord]] = [:]
    @Published var isLoading = false

    private init() {}

    // MARK: - API Methods

    /// 운동 기록 저장
    func recordWorkout(
        routineName: String,
        totalDuration: Int,
        roundsCompleted: Int,
        routineData: [String: Any]? = nil
    ) async throws {
        #if DEBUG
        print("📝 WorkoutHistoryManager.recordWorkout() - routineName: \(routineName), duration: \(totalDuration), rounds: \(roundsCompleted)")
        #endif

        guard let accessToken = AuthManager.shared.getAccessToken() else {
            #if DEBUG
            print("❌ WorkoutHistoryManager.recordWorkout() - No access token")
            #endif
            throw WorkoutHistoryError.notLoggedIn
        }

        let url = URL(string: "\(baseURL)/workouts/record.php")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        var body: [String: Any] = [
            "routineName": routineName,
            "totalDuration": totalDuration,
            "roundsCompleted": roundsCompleted,
            "workoutDate": Self.dateFormatter.string(from: Date())
        ]

        if let routineData = routineData {
            body["routineData"] = routineData
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw WorkoutHistoryError.networkError
        }

        #if DEBUG
        if let jsonString = String(data: data, encoding: .utf8) {
            print("📝 Workout Record API Response (\(httpResponse.statusCode)): \(jsonString)")
        }
        #endif

        if httpResponse.statusCode == 401 {
            try await AuthManager.shared.refreshTokenIfNeeded()
            try await recordWorkout(
                routineName: routineName,
                totalDuration: totalDuration,
                roundsCompleted: roundsCompleted,
                routineData: routineData
            )
            return
        }

        guard httpResponse.statusCode == 200 else {
            throw WorkoutHistoryError.serverError("Failed to record workout")
        }

        let recordResponse = try JSONDecoder().decode(WorkoutRecordSaveResponse.self, from: data)

        if !recordResponse.success {
            throw WorkoutHistoryError.serverError(recordResponse.error ?? "Unknown error")
        }

        // 캐시된 데이터 새로고침
        let now = Date()
        let calendar = Calendar.current
        let year = calendar.component(.year, from: now)
        let month = calendar.component(.month, from: now)
        _ = try? await fetchHistory(year: year, month: month, forceRefresh: true)
    }

    /// 월별 운동 기록 조회
    func fetchHistory(year: Int, month: Int, forceRefresh: Bool = false) async throws -> [WorkoutRecord] {
        let cacheKey = "\(year)-\(month)"

        // 캐시 확인
        if !forceRefresh, let cached = monthlyRecords[cacheKey] {
            return cached
        }

        guard let accessToken = AuthManager.shared.getAccessToken() else {
            throw WorkoutHistoryError.notLoggedIn
        }

        isLoading = true
        defer { isLoading = false }

        let url = URL(string: "\(baseURL)/workouts/history.php?year=\(year)&month=\(month)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw WorkoutHistoryError.networkError
        }

        #if DEBUG
        if let jsonString = String(data: data, encoding: .utf8) {
            print("📅 Workout History API Response (\(httpResponse.statusCode)): \(jsonString)")
        }
        #endif

        if httpResponse.statusCode == 401 {
            try await AuthManager.shared.refreshTokenIfNeeded()
            return try await fetchHistory(year: year, month: month, forceRefresh: forceRefresh)
        }

        guard httpResponse.statusCode == 200 else {
            throw WorkoutHistoryError.serverError("Failed to fetch history")
        }

        let historyResponse = try JSONDecoder().decode(WorkoutHistoryResponse.self, from: data)

        if !historyResponse.success {
            throw WorkoutHistoryError.serverError(historyResponse.error ?? "Unknown error")
        }

        // 캐시에 저장
        monthlyRecords[cacheKey] = historyResponse.records

        return historyResponse.records
    }

    /// 특정 날짜의 운동 기록 조회
    func getRecordsForDate(_ date: Date) -> [WorkoutRecord] {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let cacheKey = "\(year)-\(month)"

        guard let records = monthlyRecords[cacheKey] else {
            return []
        }

        let dateString = Self.dateFormatter.string(from: date)
        return records.filter { $0.workoutDate == dateString }
    }

    /// 운동 기록 삭제
    func deleteRecord(id: Int, year: Int, month: Int) async throws {
        guard let accessToken = AuthManager.shared.getAccessToken() else {
            throw WorkoutHistoryError.notLoggedIn
        }

        let url = URL(string: "\(baseURL)/workouts/delete.php?id=\(id)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw WorkoutHistoryError.networkError
        }

        #if DEBUG
        if let jsonString = String(data: data, encoding: .utf8) {
            print("Delete Record Response (\(httpResponse.statusCode)): \(jsonString)")
        }
        #endif

        if httpResponse.statusCode == 401 {
            try await AuthManager.shared.refreshTokenIfNeeded()
            try await deleteRecord(id: id, year: year, month: month)
            return
        }

        guard httpResponse.statusCode == 200 else {
            throw WorkoutHistoryError.serverError("Failed to delete record")
        }

        // 캐시에서 삭제
        let cacheKey = "\(year)-\(month)"
        if var records = monthlyRecords[cacheKey] {
            records.removeAll { $0.id == id }
            monthlyRecords[cacheKey] = records
        }
    }

    /// 사용자 데이터 초기화
    func clearUserData() {
        monthlyRecords.removeAll()
    }

    // MARK: - Helpers

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

// MARK: - Error

enum WorkoutHistoryError: LocalizedError {
    case notLoggedIn
    case networkError
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .notLoggedIn:
            return String(localized: "Please log in to save workout records.")
        case .networkError:
            return String(localized: "Network error. Please try again.")
        case .serverError(let message):
            return message
        }
    }
}
