//
//  MyChallengesListView.swift
//  IntervalApp
//
//  Created by Claude on 2024.
//

import SwiftUI

enum MyChallengeTab: String, CaseIterable {
    case upcoming = "Upcoming"
    case active = "In Progress"
    case completed = "Completed"

    var localizedName: String {
        switch self {
        case .upcoming:
            return String(localized: "Upcoming")
        case .active:
            return String(localized: "In Progress")
        case .completed:
            return String(localized: "Completed")
        }
    }
}

struct MyChallengesListView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var challengeManager = ChallengeManager.shared

    @State private var selectedTab: MyChallengeTab = .upcoming
    @State private var selectedChallenge: ChallengeListItem?

    var body: some View {
        VStack(spacing: 0) {
            // Tab Picker
            Picker("Tab", selection: $selectedTab) {
                ForEach(MyChallengeTab.allCases, id: \.self) { tab in
                    Text(tab.localizedName)
                        .tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding()

            // Challenge List
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(filteredChallenges) { challenge in
                        MyChallengeRowView(challenge: challenge)
                            .onTapGesture {
                                selectedChallenge = challenge
                            }
                    }

                    if filteredChallenges.isEmpty {
                        emptyStateView
                    }
                }
                .padding()
            }
        }
        .navigationTitle("My Challenges")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                }
            }
        }
        .sheet(item: $selectedChallenge) { challenge in
            NavigationStack {
                ChallengeDetailView(challengeId: challenge.id)
            }
        }
        .task {
            await challengeManager.fetchMyChallenges()
        }
    }

    // MARK: - Filtered Challenges

    private var filteredChallenges: [ChallengeListItem] {
        let challenges = challengeManager.myChallenges

        switch selectedTab {
        case .upcoming:
            // 모집 중이거나 시작 전인 챌린지
            return challenges
                .filter { $0.isUpcoming }
                .sorted { ($0.challengeStartDate ?? .distantFuture) < ($1.challengeStartDate ?? .distantFuture) }
                .prefix(30)
                .map { $0 }

        case .active:
            // 진행 중인 챌린지
            return challenges
                .filter { $0.isCurrentlyActive }
                .sorted { ($0.challengeEndDate ?? .distantFuture) < ($1.challengeEndDate ?? .distantFuture) }
                .prefix(30)
                .map { $0 }

        case .completed:
            // 완료된 챌린지 (상금 분배 대기 포함)
            return challenges
                .filter { $0.computedStatus == .completed || $0.needsClaimPrize }
                .sorted { ($0.challengeEndDate ?? .distantPast) > ($1.challengeEndDate ?? .distantPast) }
                .prefix(30)
                .map { $0 }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: emptyStateIcon)
                .font(.system(size: 40))
                .foregroundStyle(.secondary)

            Text(emptyStateMessage)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    private var emptyStateIcon: String {
        switch selectedTab {
        case .upcoming:
            return "calendar.badge.clock"
        case .active:
            return "figure.run"
        case .completed:
            return "trophy"
        }
    }

    private var emptyStateMessage: String {
        switch selectedTab {
        case .upcoming:
            return String(localized: "No upcoming challenges")
        case .active:
            return String(localized: "No active challenges")
        case .completed:
            return String(localized: "No completed challenges")
        }
    }
}

// MARK: - My Challenge Row View

struct MyChallengeRowView: View {
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

                // Status Badge
                statusBadge
            }

            // Info Row
            HStack(spacing: 16) {
                // Participants
                HStack(spacing: 4) {
                    Image(systemName: "person.2.fill")
                        .font(.caption)
                    Text("\(challenge.participantCount)")
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

                // Date info
                dateInfo
            }
            .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        .overlay(alignment: .topLeading) {
            // 상금 미수령 표시 띠
            if challenge.needsClaimPrize {
                Text("Claim Prize!")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .offset(x: -4, y: -8)
            }
        }
    }

    @ViewBuilder
    private var statusBadge: some View {
        if challenge.needsClaimPrize {
            Text("Ended")
                .font(.caption)
                .fontWeight(.semibold)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.orange.opacity(0.15))
                .foregroundStyle(.orange)
                .clipShape(Capsule())
        } else {
            Text(currentStatus.displayName)
                .font(.caption)
                .fontWeight(.semibold)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(statusColor.opacity(0.15))
                .foregroundStyle(statusColor)
                .clipShape(Capsule())
        }
    }

    @ViewBuilder
    private var dateInfo: some View {
        if challenge.isUpcoming {
            if let days = challenge.daysUntilStart, days > 0 {
                Text("Starts in \(days) days")
                    .font(.caption)
            } else {
                Text("Starting soon")
                    .font(.caption)
            }
        } else if challenge.isCurrentlyActive {
            if let days = challenge.daysRemaining, days > 0 {
                Text("\(days) days left")
                    .font(.caption)
            } else {
                Text("Ends today")
                    .font(.caption)
            }
        } else if let endDate = challenge.challengeEndDate {
            Text("Ended \(endDate, style: .date)")
                .font(.caption)
        }
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
    NavigationStack {
        MyChallengesListView()
    }
}
