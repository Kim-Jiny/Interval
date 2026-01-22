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

    var icon: String {
        switch self {
        case .upcoming:
            return "calendar.badge.clock"
        case .active:
            return "figure.run"
        case .completed:
            return "trophy.fill"
        }
    }

    var color: Color {
        switch self {
        case .upcoming:
            return .blue
        case .active:
            return .green
        case .completed:
            return .orange
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
            // Custom Tab Bar
            HStack(spacing: 8) {
                ForEach(MyChallengeTab.allCases, id: \.self) { tab in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = tab
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: tab.icon)
                                .font(.caption)
                            Text(tab.localizedName)
                                .font(.subheadline)
                                .fontWeight(selectedTab == tab ? .semibold : .regular)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(selectedTab == tab ? tab.color.opacity(0.15) : Color.clear)
                        )
                        .foregroundStyle(selectedTab == tab ? tab.color : .secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))

            Divider()

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
            .background(
                LinearGradient(
                    colors: [
                        selectedTab.color.opacity(0.03),
                        Color(.systemGroupedBackground)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .navigationTitle("My Challenges")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
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
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(selectedTab.color.opacity(0.1))
                    .frame(width: 80, height: 80)

                Image(systemName: selectedTab.icon)
                    .font(.system(size: 36))
                    .foregroundStyle(selectedTab.color)
            }

            VStack(spacing: 4) {
                Text(emptyStateMessage)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(emptyStateSubtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
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

    private var emptyStateSubtitle: String {
        switch selectedTab {
        case .upcoming:
            return String(localized: "Join Challenges")
        case .active:
            return String(localized: "Start Workout")
        case .completed:
            return String(localized: "Results")
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

                // Status Badge
                statusBadge
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
                }
                .frame(maxWidth: .infinity, alignment: .leading)

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
                .frame(maxWidth: .infinity, alignment: .center)

                // Date info
                dateInfo
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // My Stats (if available)
            if let stats = challenge.myStats {
                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                        Text("\(stats.completionCount) completions")
                            .font(.caption)
                    }

                    HStack(spacing: 4) {
                        Image(systemName: "chart.bar.fill")
                            .font(.caption)
                            .foregroundStyle(.purple)
                        Text(String(format: "%.0f%%", stats.attendanceRate))
                            .font(.caption)
                    }

                    Spacer()
                }
                .foregroundStyle(.secondary)
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
                .stroke(statusColor.opacity(0.2), lineWidth: 1)
        )
        .overlay(alignment: .topTrailing) {
            // 상금 미수령 표시
            if challenge.needsClaimPrize {
                HStack(spacing: 4) {
                    Image(systemName: "gift.fill")
                        .font(.caption2)
                    Text("Claim!")
                        .font(.caption2)
                        .fontWeight(.bold)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color.orange)
                )
                .offset(x: 8, y: -8)
            }
        }
    }

    @ViewBuilder
    private var statusBadge: some View {
        if challenge.needsClaimPrize {
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .font(.caption2)
                Text("Ended")
                    .font(.caption)
                    .fontWeight(.semibold)
            }
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
        Group {
            if challenge.isUpcoming {
                if let days = challenge.daysUntilStart, days > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption2)
                        Text("D-\(days)")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(.blue)
                } else {
                    Text("Starting soon")
                        .font(.caption)
                        .foregroundStyle(.blue)
                }
            } else if challenge.isCurrentlyActive {
                if let days = challenge.daysRemaining, days > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.caption2)
                        Text("\(days)d left")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(.green)
                } else {
                    Text("Ends today")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.red)
                }
            } else if let endDate = challenge.challengeEndDate {
                Text(endDate, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
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
