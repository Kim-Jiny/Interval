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
    private static let adMileageKey = "configAdMileage"
    private static let adDailyLimitKey = "configAdDailyLimit"
    private static let adBannerEnableKey = "configAdBannerEnable"
    private static let adRewardEnableKey = "configAdRewardEnable"

    // Default values
    private static let defaultApiBaseURL = "http://daeqws1.mycafe24.com/Interval/api"
    private static let defaultWebBaseURL = "http://daeqws1.mycafe24.com/Interval"
    private static let defaultAdMileage = 50
    private static let defaultAdDailyLimit = 5
    private static let defaultAdBannerEnable = true
    private static let defaultAdRewardEnable = true

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

    // MARK: - Ad Config

    nonisolated static var adMileage: Int {
        let value = UserDefaults.standard.integer(forKey: adMileageKey)
        return value > 0 ? value : defaultAdMileage
    }

    nonisolated static var adDailyLimit: Int {
        let value = UserDefaults.standard.integer(forKey: adDailyLimitKey)
        return value > 0 ? value : defaultAdDailyLimit
    }

    nonisolated static var adBannerEnable: Bool {
        if UserDefaults.standard.object(forKey: adBannerEnableKey) == nil {
            return defaultAdBannerEnable
        }
        return UserDefaults.standard.bool(forKey: adBannerEnableKey)
    }

    nonisolated static var adRewardEnable: Bool {
        if UserDefaults.standard.object(forKey: adRewardEnableKey) == nil {
            return defaultAdRewardEnable
        }
        return UserDefaults.standard.bool(forKey: adRewardEnableKey)
    }

    private init() {
        // Load cached config on init (if not already set)
        if UserDefaults.standard.string(forKey: Self.apiBaseURLKey) == nil {
            UserDefaults.standard.set(Self.defaultApiBaseURL, forKey: Self.apiBaseURLKey)
            UserDefaults.standard.set(Self.defaultWebBaseURL, forKey: Self.webBaseURLKey)
            print("⚙️ [Config] Initialized with default URL: \(Self.defaultApiBaseURL)")
        } else {
            print("⚙️ [Config] Using cached URL: \(Self.apiBaseURL)")
        }
    }

    // MARK: - Debug Logging

    /// 현재 설정된 URL 로그 출력
    nonisolated static func logCurrentConfig() {
        #if DEBUG
        print("⚙️ ========== Current Config ==========")
        print("⚙️ API Base URL: \(apiBaseURL)")
        print("⚙️ Web Base URL: \(webBaseURL)")
        print("⚙️ Watch Push URL: \(watchPushURL)")
        print("⚙️ Live Activity URL: \(liveActivityPushURL)")
        print("⚙️ ======================================")
        #endif
    }

    // MARK: - Public Methods

    /// 앱 시작 시 호출 - 설정 로드
    func loadConfig() async {
        #if DEBUG
        print("⚙️ [Config] Loading config...")
        #endif

        // Check if cache is still valid
        if isCacheValid() {
            #if DEBUG
            print("⚙️ [Config] Using cached config (still valid)")
            Self.logCurrentConfig()
            #endif
            isLoaded = true
            return
        }

        // Fetch from GitHub
        await fetchConfig()

        #if DEBUG
        Self.logCurrentConfig()
        #endif
    }

    /// 강제로 설정 새로고침
    func refreshConfig() async {
        await fetchConfig()
    }

    // MARK: - Private Methods

    private func fetchConfig() async {
        #if DEBUG
        print("⚙️ [Config] Fetching from GitHub: \(configURL)")
        #endif

        guard let url = URL(string: configURL) else {
            print("⚙️ [Config] Invalid config URL")
            isLoaded = true
            return
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                print("⚙️ [Config] Fetch failed with status: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
                print("⚙️ [Config] Using fallback URL: \(Self.apiBaseURL)")
                isLoaded = true
                return
            }

            let config = try JSONDecoder().decode(AppConfig.self, from: data)

            // Save to UserDefaults (thread-safe storage)
            UserDefaults.standard.set(config.apiBaseURL, forKey: Self.apiBaseURLKey)
            UserDefaults.standard.set(config.webBaseURL, forKey: Self.webBaseURLKey)
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: Self.configLastFetchKey)

            // Save ad config
            if let adConfig = config.ad {
                UserDefaults.standard.set(adConfig.mileage, forKey: Self.adMileageKey)
                UserDefaults.standard.set(adConfig.dailyLimit, forKey: Self.adDailyLimitKey)
                UserDefaults.standard.set(adConfig.bannerEnable, forKey: Self.adBannerEnableKey)
                UserDefaults.standard.set(adConfig.rewardEnable, forKey: Self.adRewardEnableKey)
            }

            #if DEBUG
            print("⚙️ [Config] ✅ Loaded from GitHub successfully!")
            print("⚙️ [Config] API: \(config.apiBaseURL)")
            print("⚙️ [Config] Web: \(config.webBaseURL)")
            print("⚙️ [Config] Ad - Mileage: \(Self.adMileage), Banner: \(Self.adBannerEnable), Reward: \(Self.adRewardEnable)")
            #endif
            isLoaded = true

        } catch {
            print("⚙️ [Config] Fetch error: \(error.localizedDescription)")
            print("⚙️ [Config] Using fallback URL: \(Self.apiBaseURL)")
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
    let ad: AdConfig?

    enum CodingKeys: String, CodingKey {
        case apiBaseURL = "api_base_url"
        case webBaseURL = "web_base_url"
        case ad
    }
}

struct AdConfig: Codable {
    let mileage: Int
    let dailyLimit: Int
    let bannerEnable: Bool
    let rewardEnable: Bool

    enum CodingKeys: String, CodingKey {
        case mileage
        case dailyLimit = "daily_limit"
        case bannerEnable = "banner_enable"
        case rewardEnable = "reward_enable"
    }
}
