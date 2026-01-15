//
//  Routine.swift
//  IntervalApp
//
//  Created by 김미진 on 1/14/26.
//

import Foundation

struct Routine: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var intervals: [WorkoutInterval]
    var rounds: Int
    var createdAt: Date
    var updatedAt: Date

    var totalDuration: TimeInterval {
        let singleRoundDuration = intervals.reduce(0) { $0 + $1.duration }
        return singleRoundDuration * Double(rounds)
    }

    var formattedTotalDuration: String {
        let totalSeconds = Int(totalDuration)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    init(
        id: UUID = UUID(),
        name: String,
        intervals: [WorkoutInterval],
        rounds: Int = 1,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.intervals = intervals
        self.rounds = rounds
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    static var sample: Routine {
        Routine(
            name: String(localized: "Basic Interval"),
            intervals: [
                WorkoutInterval(name: String(localized: "Warmup"), duration: 10, type: .warmup),
                WorkoutInterval(name: String(localized: "Workout"), duration: 30, type: .workout),
                WorkoutInterval(name: String(localized: "Rest"), duration: 10, type: .rest),
                WorkoutInterval(name: String(localized: "Workout"), duration: 30, type: .workout),
                WorkoutInterval(name: String(localized: "Rest"), duration: 10, type: .rest),
                WorkoutInterval(name: String(localized: "Cooldown"), duration: 10, type: .cooldown)
            ],
            rounds: 3
        )
    }

    static var tabata: Routine {
        Routine(
            name: String(localized: "Tabata"),
            intervals: [
                WorkoutInterval(name: String(localized: "Warmup"), duration: 10, type: .warmup),
                WorkoutInterval(name: String(localized: "Workout"), duration: 20, type: .workout),
                WorkoutInterval(name: String(localized: "Rest"), duration: 10, type: .rest)
            ],
            rounds: 8
        )
    }
}
