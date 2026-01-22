//
//  Challenge.swift
//  IntervalApp
//
//  Created by Claude on 2024.
//

import Foundation

// MARK: - Challenge Status

enum ChallengeStatus: String, Codable, CaseIterable {
    case registration = "registration"
    case active = "active"
    case completed = "completed"
    case cancelled = "cancelled"

    var displayName: String {
        switch self {
        case .registration:
            return String(localized: "Recruiting")
        case .active:
            return String(localized: "In Progress")
        case .completed:
            return String(localized: "Completed")
        case .cancelled:
            return String(localized: "Cancelled")
        }
    }

    var color: String {
        switch self {
        case .registration:
            return "blue"
        case .active:
            return "green"
        case .completed:
            return "gray"
        case .cancelled:
            return "red"
        }
    }
}

// MARK: - Challenge Model

struct Challenge: Identifiable, Codable, Equatable {
    let id: Int
    let shareCode: String
    let title: String
    let description: String?
    let routineName: String
    let routineData: RoutineData?
    let registrationStartAt: String
    let registrationEndAt: String
    let challengeStartAt: String
    let challengeEndAt: String
    let isPublic: Bool?
    let maxParticipants: Int?
    let entryFee: Int
    let totalPrizePool: Int
    let participantCount: Int
    let status: ChallengeStatus
    let creatorId: Int?
    let creatorNickname: String?
    let isParticipating: Bool?
    let canJoin: Bool?
    let canLeave: Bool?
    let myRank: Int?
    let myParticipation: ParticipationStats?
    let totalDays: Int?
    let createdAt: String

    var registrationStartDate: Date? {
        parseDate(registrationStartAt)
    }

    var registrationEndDate: Date? {
        parseDate(registrationEndAt)
    }

    var challengeStartDate: Date? {
        parseDate(challengeStartAt)
    }

    var challengeEndDate: Date? {
        parseDate(challengeEndAt)
    }

    var formattedEntryFee: String {
        "\(entryFee)M"
    }

    var formattedPrizePool: String {
        "\(totalPrizePool)M"
    }

    var daysRemaining: Int? {
        guard let endDate = challengeEndDate else { return nil }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: endDate)
        return max(0, components.day ?? 0)
    }

    /// 시간 기반 실제 상태 계산
    var computedStatus: ChallengeStatus {
        guard let regEndDate = registrationEndDate,
              let startDate = challengeStartDate,
              let endDate = challengeEndDate else {
            return status // 날짜 파싱 실패시 DB 상태 사용
        }

        let now = Date()

        if now > endDate {
            return .completed
        } else if now >= startDate {
            return .active
        } else if now <= regEndDate {
            return .registration
        } else {
            // 모집 종료 ~ 시작 전 (대기 상태, registration으로 표시)
            return .registration
        }
    }

    /// 챌린지가 종료되었지만 상금 분배가 안된 상태 (수령 대기)
    var needsClaimPrize: Bool {
        guard let endDate = challengeEndDate else { return false }
        let now = Date()
        return now > endDate && status != .completed
    }

    static func == (lhs: Challenge, rhs: Challenge) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Routine Data for Challenge

struct RoutineData: Codable, Equatable {
    let intervals: [ChallengeInterval]
    let rounds: Int

    func toRoutine(name: String) -> Routine {
        let workoutIntervals = intervals.map { interval in
            WorkoutInterval(
                name: interval.name,
                duration: TimeInterval(interval.duration),
                type: IntervalType(rawValue: interval.type) ?? .workout
            )
        }
        return Routine(
            name: name,
            intervals: workoutIntervals,
            rounds: rounds
        )
    }
}

struct ChallengeInterval: Codable, Equatable {
    let name: String
    let duration: Int
    let type: String
}

// MARK: - Participation Stats

struct ParticipationStats: Codable, Equatable {
    let completionCount: Int
    let attendanceRate: Double
    let finalRank: Int?
    let prizeWon: Int
    let entryFeePaid: Int
    let joinedAt: String?

    var formattedAttendanceRate: String {
        String(format: "%.1f%%", attendanceRate)
    }
}

// MARK: - Challenge Participant

struct ChallengeParticipant: Identifiable, Codable, Equatable {
    var id: Int { oderId }
    private let oderId: Int
    let rank: Int
    let userId: Int
    let nickname: String?
    let profileImage: String?
    let completionCount: Int
    let attendanceRate: Double
    let finalRank: Int?
    let prizeWon: Int
    let joinedAt: String

    var formattedAttendanceRate: String {
        String(format: "%.1f%%", attendanceRate)
    }

    private enum CodingKeys: String, CodingKey {
        case rank, userId, nickname, profileImage, completionCount, attendanceRate, finalRank, prizeWon, joinedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        rank = try container.decode(Int.self, forKey: .rank)
        userId = try container.decode(Int.self, forKey: .userId)
        nickname = try container.decodeIfPresent(String.self, forKey: .nickname)
        profileImage = try container.decodeIfPresent(String.self, forKey: .profileImage)
        completionCount = try container.decode(Int.self, forKey: .completionCount)
        attendanceRate = try container.decode(Double.self, forKey: .attendanceRate)
        finalRank = try container.decodeIfPresent(Int.self, forKey: .finalRank)
        prizeWon = try container.decode(Int.self, forKey: .prizeWon)
        joinedAt = try container.decode(String.self, forKey: .joinedAt)
        oderId = rank
    }

    init(rank: Int, userId: Int, nickname: String?, profileImage: String?, completionCount: Int, attendanceRate: Double, finalRank: Int?, prizeWon: Int, joinedAt: String) {
        self.rank = rank
        self.userId = userId
        self.nickname = nickname
        self.profileImage = profileImage
        self.completionCount = completionCount
        self.attendanceRate = attendanceRate
        self.finalRank = finalRank
        self.prizeWon = prizeWon
        self.joinedAt = joinedAt
        self.oderId = rank
    }

    static func == (lhs: ChallengeParticipant, rhs: ChallengeParticipant) -> Bool {
        lhs.rank == rhs.rank && lhs.userId == rhs.userId
    }
}

// MARK: - Challenge List Item (Simplified for list views)

struct ChallengeListItem: Identifiable, Codable, Equatable {
    var id: Int
    var shareCode: String
    var title: String
    var description: String?
    var routineName: String
    var routineData: RoutineData?
    var registrationStartAt: String
    var registrationEndAt: String
    var challengeStartAt: String
    var challengeEndAt: String
    var maxParticipants: Int?
    var entryFee: Int
    var totalPrizePool: Int
    var participantCount: Int
    var status: ChallengeStatus
    var creatorNickname: String?
    var isParticipating: Bool
    var isCreator: Bool?
    var todayCompleted: Bool?
    var myStats: ParticipationStats?
    var createdAt: String

    var formattedEntryFee: String {
        "\(entryFee)M"
    }

    var formattedPrizePool: String {
        "\(totalPrizePool)M"
    }

    var challengeStartDate: Date? {
        parseDate(challengeStartAt)
    }

    var challengeEndDate: Date? {
        parseDate(challengeEndAt)
    }

    var daysRemaining: Int? {
        guard let endDate = challengeEndDate else { return nil }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: endDate)
        return max(0, components.day ?? 0)
    }

    var daysUntilStart: Int? {
        guard let startDate = challengeStartDate else { return nil }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: startDate)
        return max(0, components.day ?? 0)
    }

    /// 현재 시간이 챌린지 진행 기간인지 확인
    var isCurrentlyActive: Bool {
        guard let startDate = challengeStartDate,
              let endDate = challengeEndDate else { return false }
        let now = Date()
        return now >= startDate && now <= endDate
    }

    /// 시간 기반 실제 상태 계산
    var computedStatus: ChallengeStatus {
        guard let regEndDate = parseDate(registrationEndAt),
              let startDate = challengeStartDate,
              let endDate = challengeEndDate else {
            return status // 날짜 파싱 실패시 DB 상태 사용
        }

        let now = Date()

        if now > endDate {
            return .completed
        } else if now >= startDate {
            return .active
        } else if now <= regEndDate {
            return .registration
        } else {
            // 모집 종료 ~ 시작 전 (대기 상태, registration으로 표시)
            return .registration
        }
    }

    /// Convert to Routine for starting workout
    func toRoutine() -> Routine? {
        routineData?.toRoutine(name: routineName)
    }

    /// 챌린지가 종료되었지만 상금 분배가 안된 상태 (수령 대기)
    var needsClaimPrize: Bool {
        guard let endDate = challengeEndDate else { return false }
        let now = Date()
        // 시간상 종료됨 + DB 상태가 아직 completed가 아님
        return now > endDate && status != .completed
    }

    /// 대기 중인 챌린지 (모집 중이거나 시작 전)
    var isUpcoming: Bool {
        guard let startDate = challengeStartDate else { return false }
        return Date() < startDate
    }

    /// 정렬 우선순위 (낮을수록 먼저)
    var sortPriority: Int {
        if needsClaimPrize { return 0 }
        if isCurrentlyActive { return 1 }
        if isUpcoming { return 2 }
        return 3 // completed
    }
}

// MARK: - Date Formatter Extensions

extension ISO8601DateFormatter {
    static let flexible: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
}

extension DateFormatter {
    static let challengeDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone.current
        return formatter
    }()
}

// Helper function to parse dates in multiple formats
func parseDate(_ dateString: String) -> Date? {
    // Try ISO8601 first
    if let date = ISO8601DateFormatter.flexible.date(from: dateString) {
        return date
    }
    // Try "yyyy-MM-dd HH:mm:ss" format
    if let date = DateFormatter.challengeDate.date(from: dateString) {
        return date
    }
    return nil
}

// MARK: - API Response Models

struct ChallengeListResponse: Codable {
    let success: Bool
    let challenges: [ChallengeListItem]
    let pagination: Pagination
}

struct ChallengeDetailResponse: Codable {
    let success: Bool
    let challenge: Challenge
    let participants: [ChallengeParticipant]
}

struct ChallengeCreateResponse: Codable {
    let success: Bool
    let challenge: Challenge
    let shareUrl: String
}

struct ChallengeJoinResponse: Codable {
    let success: Bool
    let message: String
    let challenge: ChallengeJoinInfo
    let entryFeePaid: Int
}

struct ChallengeJoinInfo: Codable {
    let id: Int
    let shareCode: String
    let title: String
    let participantCount: Int
    let totalPrizePool: Int
}

struct ChallengeLeaveResponse: Codable {
    let success: Bool
    let message: String
    let refundedAmount: Int
}

struct ChallengeFinalizeResponse: Codable {
    let success: Bool
    let message: String
    let results: [FinalRanking]
}

struct FinalRanking: Codable, Identifiable {
    var id: Int { rank }
    let rank: Int
    let userId: Int
    let nickname: String?
    let completionCount: Int
    let attendanceRate: Double
    let prizeWon: Int
}

struct WorkoutRecordResponse: Codable {
    let success: Bool
    let message: String
    let stats: WorkoutStats
}

struct WorkoutStats: Codable {
    let completionCount: Int
    let attendanceRate: Double
    let totalDays: Int
    let elapsedDays: Int
}

struct Pagination: Codable {
    let page: Int
    let limit: Int
    let total: Int
    let totalPages: Int
}
