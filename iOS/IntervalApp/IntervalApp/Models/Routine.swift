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

// MARK: - Routine Templates

struct RoutineTemplate: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let icon: String
    let routine: Routine

    static var templates: [RoutineTemplate] {
        [
            RoutineTemplate(
                name: String(localized: "Empty"),
                description: String(localized: "Start from scratch"),
                icon: "plus.square.dashed",
                routine: Routine(
                    name: String(localized: "New Routine"),
                    intervals: [
                        WorkoutInterval(name: String(localized: "Warmup"), duration: 10, type: .warmup),
                        WorkoutInterval(name: String(localized: "Workout"), duration: 30, type: .workout),
                        WorkoutInterval(name: String(localized: "Rest"), duration: 10, type: .rest)
                    ],
                    rounds: 3
                )
            ),
            RoutineTemplate(
                name: String(localized: "Tabata"),
                description: String(localized: "20s workout, 10s rest x 8"),
                icon: "flame.fill",
                routine: Routine(
                    name: String(localized: "Tabata"),
                    intervals: [
                        WorkoutInterval(name: String(localized: "Warmup"), duration: 10, type: .warmup),
                        WorkoutInterval(name: String(localized: "Workout"), duration: 20, type: .workout),
                        WorkoutInterval(name: String(localized: "Rest"), duration: 10, type: .rest)
                    ],
                    rounds: 8
                )
            ),
            RoutineTemplate(
                name: String(localized: "Running Intervals"),
                description: String(localized: "Run/Walk intervals for beginners"),
                icon: "figure.run",
                routine: Routine(
                    name: String(localized: "Running Intervals"),
                    intervals: [
                        WorkoutInterval(name: String(localized: "Warmup Walk"), duration: 180, type: .warmup),
                        WorkoutInterval(name: String(localized: "Run"), duration: 120, type: .workout),
                        WorkoutInterval(name: String(localized: "Walk"), duration: 90, type: .rest),
                        WorkoutInterval(name: String(localized: "Run"), duration: 120, type: .workout),
                        WorkoutInterval(name: String(localized: "Walk"), duration: 90, type: .rest),
                        WorkoutInterval(name: String(localized: "Run"), duration: 120, type: .workout),
                        WorkoutInterval(name: String(localized: "Walk"), duration: 90, type: .rest),
                        WorkoutInterval(name: String(localized: "Cooldown Walk"), duration: 180, type: .cooldown)
                    ],
                    rounds: 1
                )
            ),
            RoutineTemplate(
                name: String(localized: "Plank Challenge"),
                description: String(localized: "Hold plank with rest intervals"),
                icon: "figure.core.training",
                routine: Routine(
                    name: String(localized: "Plank Challenge"),
                    intervals: [
                        WorkoutInterval(name: String(localized: "Get Ready"), duration: 5, type: .warmup),
                        WorkoutInterval(name: String(localized: "Plank"), duration: 60, type: .workout),
                        WorkoutInterval(name: String(localized: "Rest"), duration: 30, type: .rest),
                        WorkoutInterval(name: String(localized: "Plank"), duration: 60, type: .workout),
                        WorkoutInterval(name: String(localized: "Rest"), duration: 30, type: .rest),
                        WorkoutInterval(name: String(localized: "Plank"), duration: 60, type: .workout),
                        WorkoutInterval(name: String(localized: "Rest"), duration: 30, type: .rest),
                        WorkoutInterval(name: String(localized: "Plank"), duration: 60, type: .workout),
                        WorkoutInterval(name: String(localized: "Rest"), duration: 30, type: .rest),
                        WorkoutInterval(name: String(localized: "Plank"), duration: 60, type: .workout),
                        WorkoutInterval(name: String(localized: "Cooldown"), duration: 10, type: .cooldown)
                    ],
                    rounds: 1
                )
            ),
            RoutineTemplate(
                name: String(localized: "Leg Raises"),
                description: String(localized: "Core workout with leg raises"),
                icon: "figure.strengthtraining.functional",
                routine: Routine(
                    name: String(localized: "Leg Raises"),
                    intervals: [
                        WorkoutInterval(name: String(localized: "Get Ready"), duration: 5, type: .warmup),
                        WorkoutInterval(name: String(localized: "Leg Raises"), duration: 30, type: .workout),
                        WorkoutInterval(name: String(localized: "Rest"), duration: 20, type: .rest)
                    ],
                    rounds: 5
                )
            ),
            RoutineTemplate(
                name: String(localized: "HIIT Circuit"),
                description: String(localized: "High intensity interval training"),
                icon: "bolt.fill",
                routine: Routine(
                    name: String(localized: "HIIT Circuit"),
                    intervals: [
                        WorkoutInterval(name: String(localized: "Warmup"), duration: 60, type: .warmup),
                        WorkoutInterval(name: String(localized: "Burpees"), duration: 30, type: .workout),
                        WorkoutInterval(name: String(localized: "Rest"), duration: 15, type: .rest),
                        WorkoutInterval(name: String(localized: "Mountain Climbers"), duration: 30, type: .workout),
                        WorkoutInterval(name: String(localized: "Rest"), duration: 15, type: .rest),
                        WorkoutInterval(name: String(localized: "Jump Squats"), duration: 30, type: .workout),
                        WorkoutInterval(name: String(localized: "Rest"), duration: 15, type: .rest),
                        WorkoutInterval(name: String(localized: "High Knees"), duration: 30, type: .workout),
                        WorkoutInterval(name: String(localized: "Cooldown"), duration: 60, type: .cooldown)
                    ],
                    rounds: 3
                )
            ),
            RoutineTemplate(
                name: String(localized: "Stretching"),
                description: String(localized: "Relaxing stretch routine"),
                icon: "figure.flexibility",
                routine: Routine(
                    name: String(localized: "Stretching"),
                    intervals: [
                        WorkoutInterval(name: String(localized: "Neck Stretch"), duration: 30, type: .workout),
                        WorkoutInterval(name: String(localized: "Shoulder Stretch"), duration: 30, type: .workout),
                        WorkoutInterval(name: String(localized: "Arm Stretch"), duration: 30, type: .workout),
                        WorkoutInterval(name: String(localized: "Back Stretch"), duration: 30, type: .workout),
                        WorkoutInterval(name: String(localized: "Hip Stretch"), duration: 30, type: .workout),
                        WorkoutInterval(name: String(localized: "Leg Stretch"), duration: 30, type: .workout),
                        WorkoutInterval(name: String(localized: "Calf Stretch"), duration: 30, type: .workout)
                    ],
                    rounds: 2
                )
            )
        ]
    }
}
