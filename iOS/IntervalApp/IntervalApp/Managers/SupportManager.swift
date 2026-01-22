//
//  SupportManager.swift
//  IntervalApp
//
//  Created by Claude on 2024.
//

import Foundation
import UIKit

@MainActor
class SupportManager: ObservableObject {
    static let shared = SupportManager()

    @Published var tickets: [SupportTicket] = []
    @Published var currentTicket: SupportTicket?
    @Published var currentReplies: [SupportReply] = []
    @Published var isLoading = false
    @Published var error: String?

    private var baseURL: String {
        ConfigManager.apiBaseURL
    }

    private init() {}

    // MARK: - Fetch Tickets

    func fetchTickets(page: Int = 1) async throws {
        isLoading = true
        error = nil
        defer { isLoading = false }

        guard let token = AuthManager.shared.getAccessToken() else {
            throw NSError(domain: "SupportManager", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }

        var components = URLComponents(string: "\(baseURL)/support/list.php")!
        components.queryItems = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "limit", value: "20")
        ]

        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "SupportManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }

        // Debug: Print raw response
        if let rawString = String(data: data, encoding: .utf8) {
            print("📋 Support API Response (\(httpResponse.statusCode)): \(rawString.prefix(500))")
        }

        if httpResponse.statusCode == 401 {
            throw NSError(domain: "SupportManager", code: 401, userInfo: [NSLocalizedDescriptionKey: "Authentication failed"])
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let result = try decoder.decode(SupportTicketListResponse.self, from: data)
        self.tickets = result.tickets
    }

    // MARK: - Fetch Ticket Detail

    func fetchTicketDetail(id: Int) async throws {
        isLoading = true
        error = nil
        defer { isLoading = false }

        guard let token = AuthManager.shared.getAccessToken() else {
            throw NSError(domain: "SupportManager", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }

        var components = URLComponents(string: "\(baseURL)/support/detail.php")!
        components.queryItems = [
            URLQueryItem(name: "id", value: "\(id)")
        ]

        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "SupportManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }

        if httpResponse.statusCode == 404 {
            throw NSError(domain: "SupportManager", code: 404, userInfo: [NSLocalizedDescriptionKey: "Ticket not found"])
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let result = try decoder.decode(SupportTicketDetailResponse.self, from: data)
        self.currentTicket = result.ticket
        self.currentReplies = result.replies
    }

    // MARK: - Create Ticket

    func createTicket(category: TicketCategory, title: String, content: String) async throws -> SupportTicket {
        isLoading = true
        error = nil
        defer { isLoading = false }

        guard let token = AuthManager.shared.getAccessToken() else {
            throw NSError(domain: "SupportManager", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }

        let url = URL(string: "\(baseURL)/support/create.php")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let deviceInfo = getDeviceInfo()
        let appVersion = getAppVersion()

        let body: [String: Any] = [
            "category": category.rawValue,
            "title": title,
            "content": content,
            "deviceInfo": deviceInfo,
            "appVersion": appVersion
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "SupportManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }

        // Debug: Print raw response
        if let rawString = String(data: data, encoding: .utf8) {
            print("📋 Support Create API Response (\(httpResponse.statusCode)): \(rawString.prefix(500))")
        }

        if httpResponse.statusCode != 200 {
            if let errorResponse = try? JSONDecoder().decode([String: String].self, from: data),
               let errorMessage = errorResponse["error"] {
                throw NSError(domain: "SupportManager", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
            }
            // Show raw response if not JSON
            if let rawString = String(data: data, encoding: .utf8) {
                throw NSError(domain: "SupportManager", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Server error: \(rawString.prefix(200))"])
            }
            throw NSError(domain: "SupportManager", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Failed to create ticket"])
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let result = try decoder.decode(SupportTicketCreateResponse.self, from: data)

        // Add to local list
        tickets.insert(result.ticket, at: 0)

        return result.ticket
    }

    // MARK: - Helper Methods

    private func getDeviceInfo() -> String {
        let device = UIDevice.current
        let model = device.model
        let systemVersion = device.systemVersion
        return "\(model), iOS \(systemVersion)"
    }

    private func getAppVersion() -> String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        return "\(version) (\(build))"
    }
}
