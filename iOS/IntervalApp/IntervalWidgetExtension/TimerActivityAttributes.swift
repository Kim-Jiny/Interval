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
        var timeRemaining: TimeInterval
        var intervalType: String
        var currentRound: Int
        var totalRounds: Int
        var progress: Double
    }

    var routineName: String
    var totalIntervals: Int
}
