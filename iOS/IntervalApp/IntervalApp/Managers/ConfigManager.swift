//
//  ConfigManager.swift
//  IntervalApp
//
//  Created by Claude on 2024.
//

import Foundation

// MARK: - Thread-safe URL Storage (클래스 외부)
private enum ConfigURLStorage {
    static let lock = NSLock()
    static var apiBaseURL = "http://daeqws1.mycafe24.com/Interval/api"
    static var webBaseURL = "http://daeqws1.mycafe24.com/Interval"

    static func get() -> (api: String, web: String) {
        lock.lock()
        defer { lock.unlock() }
        return (apiBaseURL, webBaseURL)
    }

    static func set(api: String, web: String) {
        lock.lock()
        apiBaseURL = api
        webBaseURL = web
        lock.unlock()
    }
}

@MainActor
class ConfigManager: ObservableObject {
    static let shared = ConfigManager()

    // GitHub Raw URL for config JSON
    private let configURL = "https://raw.githubusercontent.com/Kim-Jiny/Interval/refs/heads/main/Data/api.json"

    // Ad config (실시간 적용)
    @Published var adMileage: Int = 50
    @Published var adDailyLimit: Int = 5
    @Published var adBannerEnable: Bool = true
    @Published var adRewardEnable: Bool = true

    // Published config values (for SwiftUI binding)
    @Published private(set) var isLoaded: Bool = false

    // MARK: - Thread-safe URL accessors

    nonisolated static var apiBaseURL: String {
        ConfigURLStorage.get().api
    }

    nonisolated static var webBaseURL: String {
        ConfigURLStorage.get().web
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
        print("⚙️ [Config] Initialized with default URL: \(ConfigManager.apiBaseURL)")
    }

    // MARK: - Debug Logging

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

        // 항상 GitHub에서 최신 설정 가져오기 (광고 설정 실시간 적용)
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

            // URL 설정 (thread-safe)
            ConfigURLStorage.set(api: config.apiBaseURL, web: config.webBaseURL)

            // Save ad config (실시간 적용)
            if let adConfig = config.ad {
                self.adMileage = adConfig.mileage
                self.adDailyLimit = adConfig.dailyLimit
                self.adBannerEnable = adConfig.bannerEnable
                self.adRewardEnable = adConfig.rewardEnable
            }

            #if DEBUG
            print("⚙️ [Config] ✅ Loaded from GitHub successfully!")
            print("⚙️ [Config] API: \(config.apiBaseURL)")
            print("⚙️ [Config] Web: \(config.webBaseURL)")
            print("⚙️ [Config] Ad - Mileage: \(self.adMileage), DailyLimit: \(self.adDailyLimit), Banner: \(self.adBannerEnable), Reward: \(self.adRewardEnable)")
            #endif
            isLoaded = true

        } catch {
            print("⚙️ [Config] Fetch error: \(error.localizedDescription)")
            print("⚙️ [Config] Using fallback URL: \(Self.apiBaseURL)")
            isLoaded = true
        }
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
