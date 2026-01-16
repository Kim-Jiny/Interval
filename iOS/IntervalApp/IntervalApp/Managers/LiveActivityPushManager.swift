//
//  LiveActivityPushManager.swift
//  IntervalApp
//
//  Created by Claude on 1/16/26.
//

import Foundation
import ActivityKit

class LiveActivityPushManager {
    static let shared = LiveActivityPushManager()

    // PHP 서버 URL (Debug/Release 분기)
    private var pushURL: String {
        #if DEBUG
        return "http://kjiny.shop/Interval/api/update_live_activity_sandbox.php"
        #else
        return "http://kjiny.shop/Interval/api/update_live_activity.php"
        #endif
    }

    private var currentPushToken: String?
    private var pushTokenTask: Task<Void, Never>?

    private init() {}

    // MARK: - Push Token 관리

    /// Live Activity의 푸시 토큰 모니터링 시작
    func startMonitoringPushToken(for activity: Activity<TimerActivityAttributes>) {
        pushTokenTask?.cancel()

        pushTokenTask = Task {
            for await tokenData in activity.pushTokenUpdates {
                let token = tokenData.map { String(format: "%02x", $0) }.joined()
                await MainActor.run {
                    self.currentPushToken = token
                    print("Live Activity Push Token: \(token)")
                }
            }
        }
    }

    /// 푸시 토큰 모니터링 중지
    func stopMonitoringPushToken() {
        pushTokenTask?.cancel()
        pushTokenTask = nil
        currentPushToken = nil
    }

    // MARK: - 서버로 업데이트 전송

    /// Live Activity 업데이트 요청
    func sendUpdate(
        currentIntervalName: String,
        endTime: Date,
        intervalType: String,
        currentRound: Int,
        totalRounds: Int
    ) {
        guard let pushToken = currentPushToken else {
            print("No push token available")
            return
        }

        let body: [String: Any] = [
            "pushToken": pushToken,
            "event": "update",
            "currentIntervalName": currentIntervalName,
            "endTime": endTime.timeIntervalSince1970,  // Unix timestamp
            "intervalType": intervalType,
            "currentRound": currentRound,
            "totalRounds": totalRounds
        ]

        sendRequest(body: body)
    }

    /// Live Activity 종료 요청
    func sendEnd(
        currentIntervalName: String = "Done",
        intervalType: String = "workout",
        currentRound: Int,
        totalRounds: Int
    ) {
        guard let pushToken = currentPushToken else {
            print("No push token available for end")
            return
        }

        let body: [String: Any] = [
            "pushToken": pushToken,
            "event": "end",
            "currentIntervalName": currentIntervalName,
            "endTime": Date().timeIntervalSince1970,
            "intervalType": intervalType,
            "currentRound": currentRound,
            "totalRounds": totalRounds
        ]

        sendRequest(body: body)
    }

    // MARK: - Private

    private func sendRequest(body: [String: Any]) {
        guard let url = URL(string: pushURL) else {
            print("Invalid URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            print("Failed to serialize request body: \(error)")
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Push request failed: \(error.localizedDescription)")
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    print("Push request successful")
                } else {
                    print("Push request failed with status: \(httpResponse.statusCode)")
                    if let data = data, let body = String(data: data, encoding: .utf8) {
                        print("Response: \(body)")
                    }
                }
            }
        }.resume()
    }
}
