//
//  WorkoutRecord.swift
//  IntervalApp
//
//  Created on 1/26/26.
//

import Foundation

/// 앱 내 운동 기록 모델
struct WorkoutRecord: Codable, Identifiable, Equatable {
    let id: Int
    let routineName: String
    let routineData: RoutineData?
    let totalDuration: Int
    let roundsCompleted: Int
    let workoutDate: String
    let createdAt: String?

    /// 포맷된 운동 시간
    var formattedDuration: String {
        let minutes = totalDuration / 60
        let seconds = totalDuration % 60
        if minutes >= 60 {
            let hours = minutes / 60
            let mins = minutes % 60
            return String(format: "%d:%02d:%02d", hours, mins, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }

    /// 운동 날짜 (Date)
    var date: Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: workoutDate)
    }

    struct RoutineData: Codable, Equatable {
        let intervals: [IntervalData]?
        let rounds: Int?

        struct IntervalData: Codable, Equatable {
            let name: String
            let duration: Int
            let type: String
        }
    }
}

/// 운동 기록 저장 응답
struct WorkoutRecordSaveResponse: Codable {
    let success: Bool
    let record: WorkoutRecord?
    let error: String?
}

/// 운동 기록 목록 응답
struct WorkoutHistoryResponse: Codable {
    let success: Bool
    let year: Int
    let month: Int
    let records: [WorkoutRecord]
    let recordsByDate: [String: [WorkoutRecord]]
    let totalWorkouts: Int
    let workoutDays: Int
    let error: String?
}
