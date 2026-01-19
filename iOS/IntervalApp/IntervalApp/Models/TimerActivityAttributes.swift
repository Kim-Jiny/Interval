//
//  TimerActivityAttributes.swift
//  IntervalApp
//
//  Created by 김미진 on 1/15/26.
//

import ActivityKit
import Foundation

struct TimerActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var currentIntervalName: String
        var endTime: Date  // 카운트다운 종료 시간
        var intervalType: String
        var currentRound: Int
        var totalRounds: Int
        var isPaused: Bool
        var remainingSeconds: Int  // 일시정지 시 표시할 남은 시간

        // 서버에서 isPaused, remainingSeconds가 없을 때 기본값 사용
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            currentIntervalName = try container.decode(String.self, forKey: .currentIntervalName)
            endTime = try container.decode(Date.self, forKey: .endTime)
            intervalType = try container.decode(String.self, forKey: .intervalType)
            currentRound = try container.decode(Int.self, forKey: .currentRound)
            totalRounds = try container.decode(Int.self, forKey: .totalRounds)
            isPaused = try container.decodeIfPresent(Bool.self, forKey: .isPaused) ?? false
            remainingSeconds = try container.decodeIfPresent(Int.self, forKey: .remainingSeconds) ?? 0
        }

        init(currentIntervalName: String, endTime: Date, intervalType: String, currentRound: Int, totalRounds: Int, isPaused: Bool, remainingSeconds: Int) {
            self.currentIntervalName = currentIntervalName
            self.endTime = endTime
            self.intervalType = intervalType
            self.currentRound = currentRound
            self.totalRounds = totalRounds
            self.isPaused = isPaused
            self.remainingSeconds = remainingSeconds
        }
    }

    var routineName: String
    var totalIntervals: Int
}
