//
//  ActiveChallengeCard.swift
//  IntervalApp
//
//  Created by Claude on 2024.
//

import SwiftUI

struct ActiveChallengeCard: View {
    let challenge: ChallengeListItem
    let onStart: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with title and completion status
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(challenge.title)
                        .font(.headline)
                        .lineLimit(1)

                    Text(challenge.routineName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Status badge
                if challenge.status == .registration {
                    // 모집 중 - 시작 버튼 없음
                    Label(String(localized: "Recruiting"), systemImage: "person.badge.clock")
                        .font(.caption)
                        .foregroundStyle(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Capsule())
                } else if challenge.todayCompleted == true {
                    // 오늘 완료
                    Label(String(localized: "Completed"), systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.1))
                        .clipShape(Capsule())
                } else {
                    // 진행 중 - 시작 가능
                    Button {
                        onStart()
                    } label: {
                        Label(String(localized: "Start"), systemImage: "play.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.orange)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }

            // Progress info
            HStack(spacing: 16) {
                if challenge.status == .registration {
                    // 모집 중 - 시작까지 남은 시간
                    if let daysUntilStart = challenge.daysUntilStart {
                        if daysUntilStart == 0 {
                            Label(String(localized: "Starts today"), systemImage: "clock")
                                .font(.caption)
                                .foregroundStyle(.blue)
                        } else {
                            Label(String(localized: "Starts in \(daysUntilStart) days"), systemImage: "clock")
                                .font(.caption)
                                .foregroundStyle(.blue)
                        }
                    }

                    // 참가자 수
                    Label(String(localized: "\(challenge.participantCount) joined"), systemImage: "person.2")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    // 진행 중 - 남은 일수
                    if let daysRemaining = challenge.daysRemaining {
                        Label(String(localized: "\(daysRemaining) days left"), systemImage: "calendar")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    // Completion count
                    if let stats = challenge.myStats {
                        Label(String(localized: "\(stats.completionCount) completions"), systemImage: "flame.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }

                    // Attendance rate
                    if let stats = challenge.myStats, stats.attendanceRate > 0 {
                        Label(stats.formattedAttendanceRate, systemImage: "chart.bar.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Routine info
            if let routineData = challenge.routineData {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 12) {
                        Label(String(localized: "\(routineData.intervals.count) intervals"), systemImage: "list.bullet")
                        Label(String(localized: "\(routineData.rounds) rounds"), systemImage: "repeat")

                        Spacer()

                        // 총 시간 표시
                        let totalSeconds = routineData.intervals.reduce(0) { $0 + $1.duration } * routineData.rounds
                        let minutes = totalSeconds / 60
                        let seconds = totalSeconds % 60
                        if minutes > 0 {
                            Label(String(localized: "\(minutes)m \(seconds)s"), systemImage: "clock")
                        } else {
                            Label(String(localized: "\(seconds)s"), systemImage: "clock")
                        }
                    }
                    .font(.caption2)
                    .foregroundStyle(.tertiary)

                    // 구간 미리보기
                    HStack(spacing: 4) {
                        ForEach(Array(routineData.intervals.prefix(4).enumerated()), id: \.offset) { index, interval in
                            Text(interval.name)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(intervalColor(for: interval.type).opacity(0.2))
                                .foregroundStyle(intervalColor(for: interval.type))
                                .clipShape(Capsule())
                        }
                        if routineData.intervals.count > 4 {
                            Text("+\(routineData.intervals.count - 4)")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            }
        }
    }

    private func intervalColor(for type: String) -> Color {
        switch type {
        case "workout":
            return .red
        case "rest":
            return .green
        case "warmup":
            return .orange
        case "cooldown":
            return .blue
        default:
            return .gray
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        ActiveChallengeCard(
            challenge: ChallengeListItem(
                id: 1,
                shareCode: "ABC123",
                title: "Morning Workout Challenge",
                description: nil,
                routineName: "HIIT Workout",
                routineData: RoutineData(
                    intervals: [
                        ChallengeInterval(name: "Workout", duration: 30, type: "workout"),
                        ChallengeInterval(name: "Rest", duration: 10, type: "rest")
                    ],
                    rounds: 8
                ),
                registrationStartAt: "2024-01-01T00:00:00Z",
                registrationEndAt: "2024-01-05T00:00:00Z",
                challengeStartAt: "2024-01-06T00:00:00Z",
                challengeEndAt: "2024-01-20T00:00:00Z",
                maxParticipants: nil,
                entryFee: 100,
                totalPrizePool: 500,
                participantCount: 5,
                status: .active,
                creatorNickname: "User1",
                isParticipating: true,
                isCreator: false,
                todayCompleted: false,
                myStats: ParticipationStats(
                    completionCount: 3,
                    attendanceRate: 75.0,
                    finalRank: nil,
                    prizeWon: 0,
                    entryFeePaid: 100,
                    joinedAt: nil
                ),
                createdAt: "2024-01-01T00:00:00Z"
            ),
            onStart: {}
        )

        ActiveChallengeCard(
            challenge: ChallengeListItem(
                id: 2,
                shareCode: "DEF456",
                title: "Evening Stretch",
                description: nil,
                routineName: "Relaxing Stretch",
                routineData: nil,
                registrationStartAt: "2024-01-01T00:00:00Z",
                registrationEndAt: "2024-01-05T00:00:00Z",
                challengeStartAt: "2024-01-06T00:00:00Z",
                challengeEndAt: "2024-01-20T00:00:00Z",
                maxParticipants: nil,
                entryFee: 50,
                totalPrizePool: 200,
                participantCount: 4,
                status: .active,
                creatorNickname: "User2",
                isParticipating: true,
                isCreator: true,
                todayCompleted: true,
                myStats: ParticipationStats(
                    completionCount: 5,
                    attendanceRate: 100.0,
                    finalRank: nil,
                    prizeWon: 0,
                    entryFeePaid: 50,
                    joinedAt: nil
                ),
                createdAt: "2024-01-01T00:00:00Z"
            ),
            onStart: {}
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
