//
//  AppUpdateManager.swift
//  IntervalApp
//
//  Created on 1/21/26.
//

import Foundation

@MainActor
class AppUpdateManager: ObservableObject {
    static let shared = AppUpdateManager()

    private let appStoreId = "6757841430"

    @Published var isUpdateAvailable: Bool = false
    @Published var appStoreVersion: String?

    var appStoreURL: URL {
        URL(string: "https://apps.apple.com/app/id\(appStoreId)")!
    }

    private var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    private init() {}

    /// App Store 버전 확인
    func checkForUpdate() async {
        guard let url = URL(string: "https://itunes.apple.com/lookup?id=\(appStoreId)&country=kr") else {
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(AppStoreLookupResponse.self, from: data)

            guard let storeVersion = response.results.first?.version else {
                return
            }

            appStoreVersion = storeVersion
            isUpdateAvailable = isVersionLower(current: currentVersion, than: storeVersion)

            #if DEBUG
            print("📱 Current version: \(currentVersion), App Store version: \(storeVersion), Update available: \(isUpdateAvailable)")
            #endif
        } catch {
            #if DEBUG
            print("❌ Failed to check for update: \(error)")
            #endif
        }
    }

    /// 버전 비교 (current가 target보다 낮으면 true)
    private func isVersionLower(current: String, than target: String) -> Bool {
        let currentComponents = current.split(separator: ".").compactMap { Int($0) }
        let targetComponents = target.split(separator: ".").compactMap { Int($0) }

        let maxCount = max(currentComponents.count, targetComponents.count)

        for i in 0..<maxCount {
            let currentValue = i < currentComponents.count ? currentComponents[i] : 0
            let targetValue = i < targetComponents.count ? targetComponents[i] : 0

            if currentValue < targetValue {
                return true
            } else if currentValue > targetValue {
                return false
            }
        }

        return false
    }
}

// MARK: - App Store Lookup Response

private struct AppStoreLookupResponse: Codable {
    let resultCount: Int
    let results: [AppStoreApp]
}

private struct AppStoreApp: Codable {
    let version: String
}
