//
//  ChallengeRowView.swift
//  IntervalApp
//
//  Created by Claude on 2024.
//

import SwiftUI

struct ChallengeRowView: View {
    let challenge: ChallengeListItem

    private var currentStatus: ChallengeStatus {
        challenge.computedStatus
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(challenge.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        Image(systemName: "figure.run")
                            .font(.caption)
                            .foregroundStyle(.orange)
                        Text(challenge.routineName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                Text(currentStatus.displayName)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(statusColor.opacity(0.15))
                    .foregroundStyle(statusColor)
                    .clipShape(Capsule())
            }

            // Info Row
            HStack(spacing: 0) {
                // Participants
                HStack(spacing: 4) {
                    Image(systemName: "person.2.fill")
                        .font(.caption)
                        .foregroundStyle(.blue)
                    Text("\(challenge.participantCount)")
                        .font(.caption)
                        .fontWeight(.medium)
                    if let max = challenge.maxParticipants {
                        Text("/ \(max)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Entry Fee
                HStack(spacing: 4) {
                    Image(systemName: "ticket.fill")
                        .font(.caption)
                        .foregroundStyle(.purple)
                    Text(challenge.formattedEntryFee)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity, alignment: .center)

                // Prize Pool
                HStack(spacing: 4) {
                    Image(systemName: "trophy.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                    Text(challenge.formattedPrizePool)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.orange)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // Footer: Date & Joined Status
            HStack {
                if let startDate = challenge.challengeStartDate {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption2)
                        Text(startDate, style: .date)
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                }

                Spacer()

                if challenge.isParticipating == true {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                        Text("Joined")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(.green)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.systemBackground))
                .shadow(color: statusColor.opacity(0.15), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    challenge.isParticipating == true
                        ? Color.green.opacity(0.3)
                        : statusColor.opacity(0.2),
                    lineWidth: 1
                )
        )
    }

    private var statusColor: Color {
        switch currentStatus {
        case .registration:
            return .blue
        case .active:
            return .green
        case .completed:
            return .gray
        case .cancelled:
            return .red
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        ChallengeRowView(challenge: ChallengeListItem(
            id: 1,
            shareCode: "ABC123",
            title: "7 Days Tabata Challenge",
            description: "Join this intense 7-day Tabata workout challenge!",
            routineName: "Tabata",
            registrationStartAt: "2024-01-01 00:00:00",
            registrationEndAt: "2024-01-07 23:59:59",
            challengeStartAt: "2024-01-08 00:00:00",
            challengeEndAt: "2024-01-14 23:59:59",
            maxParticipants: 10,
            entryFee: 100,
            totalPrizePool: 500,
            participantCount: 5,
            status: .registration,
            creatorNickname: "FitMaster",
            isParticipating: false,
            isCreator: false,
            myStats: nil,
            createdAt: "2024-01-01 00:00:00"
        ))

        ChallengeRowView(challenge: ChallengeListItem(
            id: 2,
            shareCode: "DEF456",
            title: "Morning HIIT Challenge",
            description: nil,
            routineName: "HIIT Workout",
            registrationStartAt: "2024-01-01 00:00:00",
            registrationEndAt: "2024-01-07 23:59:59",
            challengeStartAt: "2024-01-08 00:00:00",
            challengeEndAt: "2024-01-14 23:59:59",
            maxParticipants: nil,
            entryFee: 50,
            totalPrizePool: 200,
            participantCount: 3,
            status: .active,
            creatorNickname: "Runner",
            isParticipating: true,
            isCreator: false,
            myStats: nil,
            createdAt: "2024-01-01 00:00:00"
        ))
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
