//
//  ConfigManager.swift
//  IntervalApp
//
//  Created by Claude on 2024.
//

import Foundation

@MainActor
class ConfigManager: ObservableObject {
    static let shared = ConfigManager()

    // GitHub Raw URL for config JSON
    private let configURL = "https://raw.githubusercontent.com/Kim-Jiny/Interval/refs/heads/main/Data/api.json"

    // UserDefaults keys
    private static let apiBaseURLKey = "configApiBaseURL"
    private static let webBaseURLKey = "configWebBaseURL"
    private static let configLastFetchKey = "configLastFetchTime"

    // Default values
    private static let defaultApiBaseURL = "http://daeqws1.mycafe24.com/Interval/api"
    private static let defaultWebBaseURL = "http://daeqws1.mycafe24.com/Interval"

    // Cache duration: 1 hour
    private let cacheDuration: TimeInterval = 3600

    // Published config values (for SwiftUI binding)
    @Published private(set) var isLoaded: Bool = false

    // MARK: - Thread-safe URL accessors (nonisolated)

    nonisolated static var apiBaseURL: String {
        UserDefaults.standard.string(forKey: apiBaseURLKey) ?? defaultApiBaseURL
    }

    nonisolated static var webBaseURL: String {
        UserDefaults.standard.string(forKey: webBaseURLKey) ?? defaultWebBaseURL
    }

    nonisolated static var watchPushURL: String {
        #if DEBUG
        return "\(apiBaseURL)/send_watch_push_sandbox.php"
        #else
        return "\(apiBaseURL)/send_watch_push.php"
        #endif
    }

    nonisolated static var liveActivityPushURL: String {
        #if DEBUG
        return "\(apiBaseURL)/update_live_activity_sandbox.php"
        #else
        return "\(apiBaseURL)/update_live_activity.php"
        #endif
    }

    nonisolated static var challengeShareURL: String {
        "\(webBaseURL)/challenge/?code="
    }

    nonisolated static var routineShareURL: String {
        "\(webBaseURL)/share/?code="
    }

    private init() {
        // Load cached config on init (if not already set)
        if UserDefaults.standard.string(forKey: Self.apiBaseURLKey) == nil {
            UserDefaults.standard.set(Self.defaultApiBaseURL, forKey: Self.apiBaseURLKey)
            UserDefaults.standard.set(Self.defaultWebBaseURL, forKey: Self.webBaseURLKey)
        }
    }

    // MARK: - Public Methods

    /// 앱 시작 시 호출 - 설정 로드
    func loadConfig() async {
        // Check if cache is still valid
        if isCacheValid() {
            isLoaded = true
            return
        }

        // Fetch from GitHub
        await fetchConfig()
    }

    /// 강제로 설정 새로고침
    func refreshConfig() async {
        await fetchConfig()
    }

    // MARK: - Private Methods

    private func fetchConfig() async {
        guard let url = URL(string: configURL) else {
            print("⚙️ Invalid config URL")
            isLoaded = true
            return
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                print("⚙️ Config fetch failed with status: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
                isLoaded = true
                return
            }

            let config = try JSONDecoder().decode(AppConfig.self, from: data)

            // Save to UserDefaults (thread-safe storage)
            UserDefaults.standard.set(config.apiBaseURL, forKey: Self.apiBaseURLKey)
            UserDefaults.standard.set(config.webBaseURL, forKey: Self.webBaseURLKey)
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: Self.configLastFetchKey)

            print("⚙️ Config loaded from GitHub: \(config.apiBaseURL)")
            isLoaded = true

        } catch {
            print("⚙️ Config fetch error: \(error.localizedDescription)")
            isLoaded = true
        }
    }

    private func isCacheValid() -> Bool {
        let lastFetch = UserDefaults.standard.double(forKey: Self.configLastFetchKey)
        guard lastFetch > 0 else { return false }

        let elapsed = Date().timeIntervalSince1970 - lastFetch
        return elapsed < cacheDuration
    }
}

// MARK: - Config Model

struct AppConfig: Codable {
    let apiBaseURL: String
    let webBaseURL: String

    enum CodingKeys: String, CodingKey {
        case apiBaseURL = "api_base_url"
        case webBaseURL = "web_base_url"
    }
}
