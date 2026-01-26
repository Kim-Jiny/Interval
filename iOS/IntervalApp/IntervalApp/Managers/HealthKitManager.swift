//
//  HealthKitManager.swift
//  IntervalApp
//
//  Created on 1/26/26.
//

import Foundation
import HealthKit

/// HealthKit 운동 데이터 조회를 위한 매니저
@MainActor
class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()

    private let healthStore = HKHealthStore()

    @Published var isAuthorized = false
    @Published var authorizationStatus: HKAuthorizationStatus = .notDetermined

    private init() {
        checkAuthorizationStatus()
    }

    /// HealthKit 사용 가능 여부
    var isHealthDataAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    /// 권한 상태 확인
    func checkAuthorizationStatus() {
        guard isHealthDataAvailable else {
            isAuthorized = false
            return
        }

        let workoutType = HKObjectType.workoutType()
        authorizationStatus = healthStore.authorizationStatus(for: workoutType)
        isAuthorized = authorizationStatus == .sharingAuthorized
    }

    /// HealthKit 권한 요청
    func requestAuthorization() async -> Bool {
        guard isHealthDataAvailable else {
            return false
        }

        let typesToRead: Set<HKObjectType> = [
            HKObjectType.workoutType()
        ]

        do {
            try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
            checkAuthorizationStatus()
            return isAuthorized
        } catch {
            print("HealthKit authorization failed: \(error)")
            return false
        }
    }

    /// 특정 기간의 운동 데이터 조회
    func fetchWorkouts(from startDate: Date, to endDate: Date) async -> [HKWorkout] {
        guard isHealthDataAvailable else {
            return []
        }

        let workoutType = HKObjectType.workoutType()
        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictStartDate
        )
        let sortDescriptor = NSSortDescriptor(
            key: HKSampleSortIdentifierStartDate,
            ascending: false
        )

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: workoutType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    print("Failed to fetch workouts: \(error)")
                    continuation.resume(returning: [])
                    return
                }

                let workouts = samples as? [HKWorkout] ?? []
                continuation.resume(returning: workouts)
            }

            healthStore.execute(query)
        }
    }

    /// 특정 월의 운동 데이터 조회
    func fetchWorkoutsForMonth(year: Int, month: Int) async -> [HKWorkout] {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1

        guard let startDate = Calendar.current.date(from: components),
              let endDate = Calendar.current.date(byAdding: .month, value: 1, to: startDate) else {
            return []
        }

        return await fetchWorkouts(from: startDate, to: endDate)
    }
}

// MARK: - HKWorkout Extension

extension HKWorkout {
    /// 운동 타입의 로컬라이즈된 이름
    var workoutTypeName: String {
        switch workoutActivityType {
        case .running:
            return String(localized: "Running")
        case .walking:
            return String(localized: "Walking")
        case .cycling:
            return String(localized: "Cycling")
        case .swimming:
            return String(localized: "Swimming")
        case .yoga:
            return String(localized: "Yoga")
        case .functionalStrengthTraining:
            return String(localized: "Strength Training")
        case .traditionalStrengthTraining:
            return String(localized: "Strength Training")
        case .highIntensityIntervalTraining:
            return String(localized: "HIIT")
        case .crossTraining:
            return String(localized: "Cross Training")
        case .mixedCardio:
            return String(localized: "Mixed Cardio")
        case .coreTraining:
            return String(localized: "Core Training")
        case .flexibility:
            return String(localized: "Flexibility")
        case .dance:
            return String(localized: "Dance")
        case .pilates:
            return String(localized: "Pilates")
        case .elliptical:
            return String(localized: "Elliptical")
        case .rowing:
            return String(localized: "Rowing")
        case .stairs:
            return String(localized: "Stair Climbing")
        case .jumpRope:
            return String(localized: "Jump Rope")
        case .kickboxing:
            return String(localized: "Kickboxing")
        case .boxing:
            return String(localized: "Boxing")
        case .martialArts:
            return String(localized: "Martial Arts")
        case .hiking:
            return String(localized: "Hiking")
        case .basketball:
            return String(localized: "Basketball")
        case .soccer:
            return String(localized: "Soccer")
        case .tennis:
            return String(localized: "Tennis")
        case .badminton:
            return String(localized: "Badminton")
        case .tableTennis:
            return String(localized: "Table Tennis")
        case .golf:
            return String(localized: "Golf")
        default:
            return String(localized: "Workout")
        }
    }

    /// 운동 시간 (분)
    var durationMinutes: Int {
        Int(duration / 60)
    }

    /// 포맷된 운동 시간
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        if minutes >= 60 {
            let hours = minutes / 60
            let mins = minutes % 60
            return String(format: "%d:%02d:%02d", hours, mins, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }

    /// 운동 시작 날짜 (Date만)
    var workoutDate: Date {
        Calendar.current.startOfDay(for: startDate)
    }

    /// SF Symbol 이름
    var symbolName: String {
        switch workoutActivityType {
        case .running:
            return "figure.run"
        case .walking:
            return "figure.walk"
        case .cycling:
            return "figure.outdoor.cycle"
        case .swimming:
            return "figure.pool.swim"
        case .yoga:
            return "figure.yoga"
        case .functionalStrengthTraining, .traditionalStrengthTraining:
            return "dumbbell.fill"
        case .highIntensityIntervalTraining:
            return "flame.fill"
        case .crossTraining, .mixedCardio:
            return "figure.mixed.cardio"
        case .coreTraining:
            return "figure.core.training"
        case .flexibility:
            return "figure.flexibility"
        case .dance:
            return "figure.dance"
        case .pilates:
            return "figure.pilates"
        case .elliptical:
            return "figure.elliptical"
        case .rowing:
            return "figure.rower"
        case .stairs:
            return "figure.stairs"
        case .jumpRope:
            return "figure.jumprope"
        case .kickboxing, .boxing:
            return "figure.boxing"
        case .martialArts:
            return "figure.martial.arts"
        case .hiking:
            return "figure.hiking"
        case .basketball:
            return "figure.basketball"
        case .soccer:
            return "soccerball"
        case .tennis:
            return "figure.tennis"
        case .badminton:
            return "figure.badminton"
        case .tableTennis:
            return "figure.table.tennis"
        case .golf:
            return "figure.golf"
        default:
            return "figure.run"
        }
    }
}
