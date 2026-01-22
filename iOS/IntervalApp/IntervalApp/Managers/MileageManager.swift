//
//  MileageManager.swift
//  IntervalApp
//
//  Created by Claude on 2024.
//

import Foundation

@MainActor
class MileageManager: ObservableObject {
    static let shared = MileageManager()

    // API Base URL
    private var baseURL: String {
        #if DEBUG
        return "http://kjiny.shop/Interval/api"
        #else
        return "http://kjiny.shop/Interval/api"
        #endif
    }

    // Published state
    @Published var balance: MileageBalance?
    @Published var transactions: [MileageTransaction] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // Ad reward status
    @Published var adRemainingCount: Int = 5
    @Published var adDailyLimit: Int = 5

    // Pagination
    @Published var currentPage: Int = 1
    @Published var totalPages: Int = 1
    @Published var hasMorePages: Bool = false

    private init() {}

    // MARK: - Fetch Balance

    func fetchBalance() async {
        guard let accessToken = AuthManager.shared.getAccessToken() else {
            errorMessage = "Please log in first"
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let url = URL(string: "\(baseURL)/mileage/balance.php")!
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw MileageError.networkError
            }

            #if DEBUG
            if let jsonString = String(data: data, encoding: .utf8) {
                print("💰 Mileage Balance Response (\(httpResponse.statusCode)): \(jsonString)")
            }
            #endif

            if httpResponse.statusCode == 401 {
                try await AuthManager.shared.refreshTokenIfNeeded()
                await fetchBalance()
                return
            }

            let balanceResponse = try JSONDecoder().decode(MileageBalanceResponse.self, from: data)

            if balanceResponse.success {
                self.balance = balanceResponse.mileage
            } else {
                throw MileageError.serverError("Failed to fetch balance")
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Fetch History

    func fetchHistory(page: Int = 1, limit: Int = 20) async {
        guard let accessToken = AuthManager.shared.getAccessToken() else {
            errorMessage = "Please log in first"
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let url = URL(string: "\(baseURL)/mileage/history.php?page=\(page)&limit=\(limit)")!
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw MileageError.networkError
            }

            #if DEBUG
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📜 Mileage History Response (\(httpResponse.statusCode)): \(jsonString)")
            }
            #endif

            if httpResponse.statusCode == 401 {
                try await AuthManager.shared.refreshTokenIfNeeded()
                await fetchHistory(page: page, limit: limit)
                return
            }

            let historyResponse = try JSONDecoder().decode(MileageHistoryResponse.self, from: data)

            if historyResponse.success {
                if page == 1 {
                    self.transactions = historyResponse.transactions
                } else {
                    self.transactions.append(contentsOf: historyResponse.transactions)
                }
                self.currentPage = historyResponse.pagination.page
                self.totalPages = historyResponse.pagination.totalPages
                self.hasMorePages = historyResponse.pagination.page < historyResponse.pagination.totalPages
            } else {
                throw MileageError.serverError("Failed to fetch history")
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Load More

    func loadMoreIfNeeded() async {
        guard hasMorePages, !isLoading else { return }
        await fetchHistory(page: currentPage + 1)
    }

    // MARK: - Refresh

    func refresh() async {
        currentPage = 1
        await fetchBalance()
        await fetchHistory(page: 1)
        await fetchAdStatus()
    }

    // MARK: - Fetch Ad Status

    func fetchAdStatus() async {
        guard let accessToken = AuthManager.shared.getAccessToken() else { return }

        do {
            let url = URL(string: "\(baseURL)/mileage/ad-status.php")!
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else { return }

            struct AdStatusResponse: Codable {
                let success: Bool
                let todayCount: Int
                let dailyLimit: Int
                let remaining: Int
            }

            let statusResponse = try JSONDecoder().decode(AdStatusResponse.self, from: data)

            if statusResponse.success {
                self.adRemainingCount = statusResponse.remaining
                self.adDailyLimit = statusResponse.dailyLimit
            }
        } catch {
            print("Failed to fetch ad status: \(error)")
        }
    }

    // MARK: - Ad Reward

    func claimAdReward() async throws -> Int {
        guard let accessToken = AuthManager.shared.getAccessToken() else {
            throw MileageError.serverError("Please log in first")
        }

        let url = URL(string: "\(baseURL)/mileage/ad-reward.php")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw MileageError.networkError
        }

        #if DEBUG
        if let jsonString = String(data: data, encoding: .utf8) {
            print("🎁 Ad Reward Response (\(httpResponse.statusCode)): \(jsonString)")
        }
        #endif

        if httpResponse.statusCode == 401 {
            try await AuthManager.shared.refreshTokenIfNeeded()
            return try await claimAdReward()
        }

        struct AdRewardResponse: Codable {
            let success: Bool
            let message: String?
            let rewardAmount: Int?
            let newBalance: Int?
            let error: String?
        }

        let rewardResponse = try JSONDecoder().decode(AdRewardResponse.self, from: data)

        if rewardResponse.success, let reward = rewardResponse.rewardAmount {
            // 잔액 업데이트
            await fetchBalance()
            return reward
        } else {
            throw MileageError.serverError(rewardResponse.error ?? "Failed to claim reward")
        }
    }
}

// MARK: - Mileage Error

enum MileageError: LocalizedError {
    case networkError
    case serverError(String)
    case insufficientBalance

    var errorDescription: String? {
        switch self {
        case .networkError:
            return String(localized: "Network error. Please try again.")
        case .serverError(let message):
            return message
        case .insufficientBalance:
            return String(localized: "Insufficient mileage balance.")
        }
    }
}
