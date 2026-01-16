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
    }

    var routineName: String
    var totalIntervals: Int
}
