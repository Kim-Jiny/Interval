//
//  AdManager.swift
//  IntervalApp
//
//  Created by Claude on 2024.
//

import Foundation
import GoogleMobileAds
import SwiftUI
import AppTrackingTransparency
import AdSupport

@MainActor
class AdManager: NSObject, ObservableObject {
    static let shared = AdManager()

    // MARK: - Ad Unit IDs
    #if DEBUG
    private let bannerAdUnitID = "ca-app-pub-3940256099942544/2934735716"  // 테스트 배너
    private let rewardedAdUnitID = "ca-app-pub-3940256099942544/1712485313" // 테스트 리워드
    #else
    private let bannerAdUnitID = "ca-app-pub-2707874353926722/6959385230"   // 실제 배너
    private let rewardedAdUnitID = "ca-app-pub-2707874353926722/4555926638" // 실제 리워드
    #endif

    // MARK: - Published Properties
    @Published var isRewardedAdReady = false
    @Published var isLoadingRewardedAd = false
    @Published var rewardedAdError: String?
    @Published var trackingAuthorizationStatus: ATTrackingManager.AuthorizationStatus = .notDetermined

    // MARK: - Private Properties
    private var rewardedAd: RewardedAd?
    private var rewardCompletion: ((Bool) -> Void)?

    private override init() {
        super.init()
    }

    // MARK: - Initialize SDK

    func configure() {
        // ATT 권한 요청 후 AdMob 초기화
        requestTrackingAuthorization { [weak self] in
            MobileAds.shared.start { status in
                print("📺 AdMob SDK initialized")
                // 리워드 광고 미리 로드
                Task { @MainActor in
                    await self?.loadRewardedAd()
                }
            }
        }
    }

    // MARK: - App Tracking Transparency

    func requestTrackingAuthorization(completion: @escaping () -> Void) {
        // iOS 14 이상에서만 ATT 요청
        if #available(iOS 14, *) {
            // 앱이 활성화된 후 요청해야 함
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                ATTrackingManager.requestTrackingAuthorization { [weak self] status in
                    DispatchQueue.main.async {
                        self?.trackingAuthorizationStatus = status

                        switch status {
                        case .authorized:
                            print("📺 Tracking authorized")
                        case .denied:
                            print("📺 Tracking denied")
                        case .notDetermined:
                            print("📺 Tracking not determined")
                        case .restricted:
                            print("📺 Tracking restricted")
                        @unknown default:
                            print("📺 Tracking unknown status")
                        }

                        completion()
                    }
                }
            }
        } else {
            completion()
        }
    }

    // MARK: - Banner Ad

    func getBannerAdUnitID() -> String {
        return bannerAdUnitID
    }

    // MARK: - Rewarded Ad

    func loadRewardedAd() async {
        guard !isLoadingRewardedAd else { return }

        isLoadingRewardedAd = true
        rewardedAdError = nil

        do {
            rewardedAd = try await RewardedAd.load(
                with: rewardedAdUnitID,
                request: Request()
            )
            rewardedAd?.fullScreenContentDelegate = self
            isRewardedAdReady = true
            isLoadingRewardedAd = false
            print("📺 Rewarded ad loaded successfully")
        } catch {
            isRewardedAdReady = false
            isLoadingRewardedAd = false
            rewardedAdError = error.localizedDescription
            print("📺 Failed to load rewarded ad: \(error.localizedDescription)")
        }
    }

    func showRewardedAd(completion: @escaping (Bool) -> Void) {
        guard let rewardedAd = rewardedAd,
              let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            completion(false)
            return
        }

        // 가장 상위의 presented view controller 찾기
        var topController = rootViewController
        while let presented = topController.presentedViewController {
            topController = presented
        }

        self.rewardCompletion = completion

        rewardedAd.present(from: topController) { [weak self] in
            // 리워드 획득
            let reward = rewardedAd.adReward
            print("📺 User earned reward: \(reward.amount) \(reward.type)")
            self?.rewardCompletion?(true)
            self?.rewardCompletion = nil
        }
    }
}

// MARK: - FullScreenContentDelegate

extension AdManager: FullScreenContentDelegate {
    nonisolated func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        Task { @MainActor in
            print("📺 Rewarded ad dismissed")
            isRewardedAdReady = false
            // 다음 광고 미리 로드
            await loadRewardedAd()
        }
    }

    nonisolated func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        Task { @MainActor in
            print("📺 Failed to present rewarded ad: \(error.localizedDescription)")
            rewardCompletion?(false)
            rewardCompletion = nil
            isRewardedAdReady = false
            await loadRewardedAd()
        }
    }

    nonisolated func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("📺 Rewarded ad will present")
    }
}
