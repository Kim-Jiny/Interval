//
//  BannerAdView.swift
//  IntervalApp
//
//  Created by Claude on 2024.
//

import SwiftUI
import GoogleMobileAds

struct BannerAdView: UIViewRepresentable {
    let adUnitID: String

    init() {
        self.adUnitID = AdManager.shared.getBannerAdUnitID()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> BannerView {
        let bannerView = BannerView(adSize: AdSizeBanner)
        bannerView.adUnitID = adUnitID
        bannerView.delegate = context.coordinator

        print("📺 [Banner] Loading banner ad...")
        print("📺 [Banner] Ad Unit ID: \(adUnitID)")

        // Root view controller 설정
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            bannerView.rootViewController = rootViewController
        }

        bannerView.load(Request())
        return bannerView
    }

    class Coordinator: NSObject, BannerViewDelegate {
        func bannerViewDidReceiveAd(_ bannerView: BannerView) {
            print("📺 [Banner] ✅ Banner ad loaded successfully!")
            print("📺 [Banner] Response info: \(bannerView.responseInfo?.description ?? "nil")")
        }

        func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
            let nsError = error as NSError
            print("📺 [Banner] ❌ Banner ad failed to load")
            print("📺 [Banner] Error code: \(nsError.code)")
            print("📺 [Banner] Error domain: \(nsError.domain)")
            print("📺 [Banner] Error description: \(error.localizedDescription)")
            print("📺 [Banner] Error userInfo: \(nsError.userInfo)")
        }
    }

    func updateUIView(_ uiView: BannerView, context: Context) {
        // 필요시 업데이트
    }
}

// MARK: - Adaptive Banner (화면 너비에 맞춤)

struct AdaptiveBannerAdView: UIViewRepresentable {
    let adUnitID: String
    @Binding var adHeight: CGFloat

    init(adHeight: Binding<CGFloat> = .constant(50)) {
        self.adUnitID = AdManager.shared.getBannerAdUnitID()
        self._adHeight = adHeight
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> BannerView {
        let bannerView = BannerView()
        bannerView.adUnitID = adUnitID
        bannerView.delegate = context.coordinator

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            bannerView.rootViewController = rootViewController

            // Adaptive 배너 크기 계산
            let frame = windowScene.windows.first?.frame ?? .zero
            let viewWidth = frame.size.width
            bannerView.adSize = currentOrientationAnchoredAdaptiveBanner(width: viewWidth)
        }

        bannerView.load(Request())
        return bannerView
    }

    func updateUIView(_ uiView: BannerView, context: Context) {}

    class Coordinator: NSObject, BannerViewDelegate {
        var parent: AdaptiveBannerAdView

        init(_ parent: AdaptiveBannerAdView) {
            self.parent = parent
        }

        func bannerViewDidReceiveAd(_ bannerView: BannerView) {
            print("📺 Banner ad loaded")
            DispatchQueue.main.async {
                self.parent.adHeight = bannerView.adSize.size.height
            }
        }

        func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
            print("📺 Banner ad failed: \(error.localizedDescription)")
        }
    }
}

#Preview {
    VStack {
        Spacer()
        BannerAdView()
            .frame(height: 50)
    }
}
