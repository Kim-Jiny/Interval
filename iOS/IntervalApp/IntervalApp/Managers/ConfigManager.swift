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
    private let configURL = "https://raw.githubusercontent.com/kish191919/Interval_App/main/config.json"

    // UserDefaults keys
    private let configCacheKey = "cachedAppConfig"
    private let configLastFetchKey = "configLastFetchTime"

    // Cache duration: 1 hour
    private let cacheDuration: TimeInterval = 3600

    // Published config values
    @Published private(set) var apiBaseURL: String = "http://kjiny.shop/Interval/api"
    @Published private(set) var webBaseURL: String = "http://kjiny.shop/Interval"
    @Published private(set) var isLoaded: Bool = false

    // Computed URLs based on config
    var watchPushURL: String {
        #if DEBUG
        return "\(apiBaseURL)/send_watch_push_sandbox.php"
        #else
        return "\(apiBaseURL)/send_watch_push.php"
        #endif
    }

    var liveActivityPushURL: String {
        #if DEBUG
        return "\(apiBaseURL)/update_live_activity_sandbox.php"
        #else
        return "\(apiBaseURL)/update_live_activity.php"
        #endif
    }

    var challengeShareURL: String {
        "\(webBaseURL)/challenge/?code="
    }

    var routineShareURL: String {
        "\(webBaseURL)/share/?code="
    }

    private init() {
        // Load cached config on init
        loadCachedConfig()
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

            // Update values
            self.apiBaseURL = config.apiBaseURL
            self.webBaseURL = config.webBaseURL

            // Cache the config
            cacheConfig(data: data)

            print("⚙️ Config loaded from GitHub: \(config.apiBaseURL)")
            isLoaded = true

        } catch {
            print("⚙️ Config fetch error: \(error.localizedDescription)")
            isLoaded = true
        }
    }

    private func loadCachedConfig() {
        guard let data = UserDefaults.standard.data(forKey: configCacheKey) else {
            return
        }

        do {
            let config = try JSONDecoder().decode(AppConfig.self, from: data)
            self.apiBaseURL = config.apiBaseURL
            self.webBaseURL = config.webBaseURL
            print("⚙️ Config loaded from cache: \(config.apiBaseURL)")
        } catch {
            print("⚙️ Failed to load cached config: \(error.localizedDescription)")
        }
    }

    private func cacheConfig(data: Data) {
        UserDefaults.standard.set(data, forKey: configCacheKey)
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: configLastFetchKey)
    }

    private func isCacheValid() -> Bool {
        let lastFetch = UserDefaults.standard.double(forKey: configLastFetchKey)
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
