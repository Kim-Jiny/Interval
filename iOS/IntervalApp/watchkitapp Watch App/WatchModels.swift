//
//  WatchModels.swift
//  IntervalApp Watch App
//
//  Created by Claude on 1/15/26.
//

import Foundation

// MARK: - Watch용 모델 (iPhone 모델과 동일한 구조)

struct WatchRoutine: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var intervals: [WatchInterval]
    var rounds: Int

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
}

struct WatchInterval: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var duration: TimeInterval
    var type: WatchIntervalType

    var formattedDuration: String {
        let totalSeconds = Int(duration)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        if minutes > 0 {
            return String(format: "%d:%02d", minutes, seconds)
        } else {
            return "\(seconds)s"
        }
    }
}

enum WatchIntervalType: String, Codable, CaseIterable {
    case workout
    case rest
    case warmup
    case cooldown

    var displayName: String {
        switch self {
        case .workout: return String(localized: "Workout")
        case .rest: return String(localized: "Rest")
        case .warmup: return String(localized: "Warmup")
        case .cooldown: return String(localized: "Cooldown")
        }
    }
}

// MARK: - Routine Store for Watch (Singleton)

class WatchRoutineStore: ObservableObject {
    static let shared = WatchRoutineStore()

    @Published var routines: [WatchRoutine] = []

    private let userDefaultsKey = "watchRoutines"

    init() {
        loadRoutines()
    }

    func loadRoutines() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode([WatchRoutine].self, from: data) {
            routines = decoded
        }
    }

    func saveRoutines() {
        if let encoded = try? JSONEncoder().encode(routines) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }

    func updateRoutines(_ newRoutines: [WatchRoutine]) {
        routines = newRoutines
        saveRoutines()
    }
}
