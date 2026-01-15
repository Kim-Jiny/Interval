//
//  WorkoutInterval.swift
//  IntervalApp
//
//  Created by 김미진 on 1/14/26.
//

import Foundation

enum IntervalType: String, Codable, CaseIterable {
    case workout = "workout"
    case rest = "rest"
    case warmup = "warmup"
    case cooldown = "cooldown"

    var displayName: String {
        switch self {
        case .workout: return String(localized: "Workout")
        case .rest: return String(localized: "Rest")
        case .warmup: return String(localized: "Warmup")
        case .cooldown: return String(localized: "Cooldown")
        }
    }
}

struct WorkoutInterval: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var duration: TimeInterval // seconds
    var type: IntervalType

    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    static var defaultWorkout: WorkoutInterval {
        WorkoutInterval(
            name: String(localized: "Workout"),
            duration: 30,
            type: .workout
        )
    }

    static var defaultRest: WorkoutInterval {
        WorkoutInterval(
            name: String(localized: "Rest"),
            duration: 10,
            type: .rest
        )
    }
}
