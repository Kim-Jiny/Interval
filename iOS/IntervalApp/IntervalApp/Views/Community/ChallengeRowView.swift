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
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(challenge.title)
                        .font(.headline)
                        .lineLimit(1)

                    Text(challenge.routineName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
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
            HStack(spacing: 16) {
                // Participants
                HStack(spacing: 4) {
                    Image(systemName: "person.2.fill")
                        .font(.caption)
                    Text("\(challenge.participantCount)")
                        .font(.caption)
                    if let max = challenge.maxParticipants {
                        Text("/ \(max)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // Entry Fee
                HStack(spacing: 4) {
                    Image(systemName: "ticket.fill")
                        .font(.caption)
                    Text(challenge.formattedEntryFee)
                        .font(.caption)
                }

                // Prize Pool
                HStack(spacing: 4) {
                    Image(systemName: "trophy.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                    Text(challenge.formattedPrizePool)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.orange)
                }

                Spacer()
            }
            .foregroundStyle(.secondary)

            // Date Info
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
                    Text("Joined")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.green)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
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
    VStack {
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
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
