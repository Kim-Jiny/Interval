//
//  ChallengeDetailView.swift
//  IntervalApp
//
//  Created by Claude on 2024.
//

import SwiftUI

struct ChallengeDetailView: View {
    let challengeId: Int

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var routineStore: RoutineStore
    @ObservedObject private var challengeManager = ChallengeManager.shared
    @ObservedObject private var authManager = AuthManager.shared

    @State private var showingJoinAlert = false
    @State private var showingLeaveAlert = false
    @State private var showingLoginPrompt = false
    @State private var showingShareSheet = false
    @State private var errorMessage: String?
    @State private var showingError = false
    @State private var selectedRoutine: Routine?
    @State private var showingFinalizeAlert = false
    @State private var showingFinalizeResult = false
    @State private var finalizeRankings: [FinalRanking] = []

    var body: some View {
        Group {
            if challengeManager.isLoading && challengeManager.currentChallenge == nil {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                        .tint(.orange)
                    Text("Loading...")
                        .foregroundStyle(.secondary)
                }
            } else if let challenge = challengeManager.currentChallenge {
                ScrollView {
                    VStack(spacing: 16) {
                        // Header Card
                        headerCard(challenge)

                        // Stats Cards
                        statsCards(challenge)

                        // Prize Distribution
                        prizeDistributionCard(challenge)

                        // Routine Info
                        routineCard(challenge)

                        // Dates Info
                        datesCard(challenge)

                        // Participants Leaderboard
                        participantsSection

                        // Action Buttons
                        actionButtons(challenge)
                    }
                    .padding()
                }
                .background(
                    LinearGradient(
                        colors: [
                            statusColor(challenge).opacity(0.05),
                            Color(.systemGroupedBackground)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            } else {
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.red.opacity(0.1))
                            .frame(width: 80, height: 80)
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(.red)
                    }
                    Text("Challenge not found")
                        .font(.headline)
                    Text("This challenge may have been deleted")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle(challengeManager.currentChallenge?.title ?? "Challenge")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if let _ = challengeManager.currentChallenge {
                    Button {
                        showingShareSheet = true
                    } label: {
                        Image(systemName: "square.and.arrow.up.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.orange)
                    }
                }
            }
        }
        .task {
            await challengeManager.fetchChallengeDetail(id: challengeId)
        }
        .alert(String(localized: "Join Challenge"), isPresented: $showingJoinAlert) {
            Button(String(localized: "Cancel"), role: .cancel) {}
            Button(String(localized: "Join")) {
                Task {
                    await joinChallenge()
                }
            }
        } message: {
            if let challenge = challengeManager.currentChallenge {
                Text("Entry fee: \(challenge.formattedEntryFee)\n\nNote: Entry fee is non-refundable if you leave.")
            }
        }
        .alert(String(localized: "Leave Challenge"), isPresented: $showingLeaveAlert) {
            Button(String(localized: "Cancel"), role: .cancel) {}
            Button(String(localized: "Leave"), role: .destructive) {
                Task {
                    await leaveChallenge()
                }
            }
        } message: {
            Text("Entry fee will NOT be refunded. Are you sure you want to leave?")
        }
        .alert(String(localized: "Error"), isPresented: $showingError) {
            Button(String(localized: "OK"), role: .cancel) {}
        } message: {
            Text(errorMessage ?? "An error occurred")
        }
        .alert(String(localized: "Distribute Prizes"), isPresented: $showingFinalizeAlert) {
            Button(String(localized: "Cancel"), role: .cancel) {}
            Button(String(localized: "Distribute")) {
                Task {
                    await finalizeChallenge()
                }
            }
        } message: {
            Text("Challenge has ended. Distribute prizes based on final rankings?")
        }
        .sheet(isPresented: $showingFinalizeResult) {
            NavigationStack {
                finalizeResultView
            }
        }
        .sheet(isPresented: $showingLoginPrompt) {
            LoginView()
        }
        .sheet(isPresented: $showingShareSheet) {
            if let challenge = challengeManager.currentChallenge {
                let shareUrl = "\(ConfigManager.challengeShareURL)\(challenge.shareCode)"
                ShareSheet(items: [URL(string: shareUrl)!])
            }
        }
        .fullScreenCover(item: $selectedRoutine) { routine in
            TimerView(routine: routine, isChallengeMode: true) {
                // 챌린지 운동 완료 시 기록
                if let challenge = challengeManager.currentChallenge {
                    Task {
                        try? await challengeManager.recordWorkout(
                            challengeId: challenge.id,
                            totalDuration: Int(routine.totalDuration),
                            roundsCompleted: routine.rounds
                        )
                        // 상세 정보 새로고침
                        await challengeManager.fetchChallengeDetail(id: challengeId)
                    }
                }
            }
        }
    }

    // MARK: - Header Card

    private func headerCard(_ challenge: Challenge) -> some View {
        VStack(spacing: 16) {
            // Status & Participation Badge
            HStack {
                HStack(spacing: 6) {
                    Circle()
                        .fill(statusColor(challenge))
                        .frame(width: 8, height: 8)
                    Text(challenge.computedStatus.displayName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(statusColor(challenge).opacity(0.15))
                .foregroundStyle(statusColor(challenge))
                .clipShape(Capsule())

                Spacer()

                if challenge.isParticipating == true {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                        Text("Participating")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(.green)
                }
            }

            // Title & Description
            VStack(alignment: .leading, spacing: 8) {
                Text(challenge.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if let description = challenge.description, !description.isEmpty {
                    Text(description)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            // Creator info
            if let creator = challenge.creatorNickname {
                HStack(spacing: 6) {
                    Image(systemName: "person.circle.fill")
                        .foregroundStyle(.secondary)
                    Text("Created by \(creator)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: statusColor(challenge).opacity(0.2), radius: 10, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(statusColor(challenge).opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Stats Cards

    private func statsCards(_ challenge: Challenge) -> some View {
        HStack(spacing: 12) {
            // Participants Card
            statCard(
                icon: "person.2.fill",
                iconColor: .blue,
                value: "\(challenge.participantCount)",
                label: "Participants",
                maxValue: challenge.maxParticipants.map { "/\($0)" }
            )

            // Entry Fee Card
            statCard(
                icon: "ticket.fill",
                iconColor: .purple,
                value: challenge.formattedEntryFee,
                label: "Entry Fee",
                maxValue: nil
            )

            // Prize Pool Card
            statCard(
                icon: "trophy.fill",
                iconColor: .orange,
                value: challenge.formattedPrizePool,
                label: "Prize Pool",
                maxValue: nil,
                isHighlighted: true
            )
        }
    }

    private func statCard(icon: String, iconColor: Color, value: String, label: String, maxValue: String?, isHighlighted: Bool = false) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(iconColor)
            }

            HStack(spacing: 2) {
                Text(value)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(isHighlighted ? .orange : .primary)
                if let max = maxValue {
                    Text(max)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: iconColor.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }

    // MARK: - Prize Distribution Card

    private func prizeDistributionCard(_ challenge: Challenge) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "gift.fill")
                    .foregroundStyle(.orange)
                Text("Prize Distribution")
                    .font(.headline)
            }

            let prizePool = challenge.totalPrizePool
            let participantCount = challenge.participantCount

            VStack(spacing: 8) {
                prizeRow(rank: 1, percentage: participantCount >= 3 ? 60 : (participantCount == 2 ? 70 : 100), prizePool: prizePool)
                if participantCount >= 2 {
                    prizeRow(rank: 2, percentage: participantCount >= 3 ? 30 : 30, prizePool: prizePool)
                }
                if participantCount >= 3 {
                    prizeRow(rank: 3, percentage: 10, prizePool: prizePool)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .orange.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.orange.opacity(0.2), lineWidth: 1)
        )
    }

    private func prizeRow(rank: Int, percentage: Int, prizePool: Int) -> some View {
        HStack {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(rankColor(rank).opacity(0.2))
                        .frame(width: 32, height: 32)
                    Image(systemName: rank == 1 ? "trophy.fill" : "medal.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(rankColor(rank))
                }

                Text(rankText(rank))
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }

            Spacer()

            Text("\(percentage)%")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(width: 40)

            Text("\((prizePool * percentage / 100).formatted(.number))M")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundStyle(.orange)
                .frame(width: 70, alignment: .trailing)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func rankColor(_ rank: Int) -> Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        default: return .brown
        }
    }

    private func rankText(_ rank: Int) -> String {
        switch rank {
        case 1: return String(localized: "1st")
        case 2: return String(localized: "2nd")
        case 3: return String(localized: "3rd")
        default: return "\(rank)th"
        }
    }

    // MARK: - Routine Card

    private func routineCard(_ challenge: Challenge) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "figure.run")
                    .foregroundStyle(.orange)
                Text("Routine")
                    .font(.headline)
            }

            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(challenge.routineName)
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    if let routineData = challenge.routineData {
                        HStack(spacing: 16) {
                            HStack(spacing: 4) {
                                Image(systemName: "list.bullet")
                                    .font(.caption)
                                    .foregroundStyle(.blue)
                                Text("\(routineData.intervals.count) intervals")
                                    .font(.caption)
                            }
                            HStack(spacing: 4) {
                                Image(systemName: "repeat")
                                    .font(.caption)
                                    .foregroundStyle(.green)
                                Text("\(routineData.rounds) rounds")
                                    .font(.caption)
                            }
                        }
                        .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                if challenge.isParticipating == true, challenge.computedStatus == .active {
                    Button {
                        startWorkout(challenge)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "play.fill")
                            Text("Start")
                        }
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.green)
                        .clipShape(Capsule())
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }

    // MARK: - Dates Card

    private func datesCard(_ challenge: Challenge) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundStyle(.blue)
                Text("Schedule")
                    .font(.headline)
            }

            VStack(spacing: 12) {
                dateRow(
                    title: "Registration Period",
                    icon: "person.badge.plus",
                    iconColor: .blue,
                    startDate: challenge.registrationStartDate,
                    endDate: challenge.registrationEndDate,
                    isActive: challenge.computedStatus == .registration
                )

                dateRow(
                    title: "Challenge Period",
                    icon: "flame.fill",
                    iconColor: .orange,
                    startDate: challenge.challengeStartDate,
                    endDate: challenge.challengeEndDate,
                    isActive: challenge.computedStatus == .active
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }

    private func dateRow(title: String, icon: String, iconColor: Color, startDate: Date?, endDate: Date?, isActive: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(iconColor)
                    .frame(width: 20)

                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(isActive ? .primary : .secondary)

                Spacer()
            }

            if let start = startDate, let end = endDate {
                HStack(spacing: 8) {
                    Spacer()
                        .frame(width: 28)

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            Text(formatDateTime(start))
                                .font(.caption)
                                .foregroundStyle(isActive ? iconColor : .secondary)
                            Text("~")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Text(formatDateTime(end))
                            .font(.caption)
                            .foregroundStyle(isActive ? iconColor : .secondary)
                    }
                }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(isActive ? iconColor.opacity(0.1) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    // MARK: - Participants Section

    private var participantsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundStyle(.purple)
                Text("Leaderboard")
                    .font(.headline)

                Spacer()

                Text("\(challengeManager.currentParticipants.count) participants")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if challengeManager.currentParticipants.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "person.3")
                        .font(.system(size: 32))
                        .foregroundStyle(.secondary)
                    Text("No participants yet")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                VStack(spacing: 8) {
                    ForEach(challengeManager.currentParticipants) { participant in
                        participantRow(participant)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .purple.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }

    private func participantRow(_ participant: ChallengeParticipant) -> some View {
        HStack(spacing: 12) {
            // Rank Badge
            ZStack {
                Circle()
                    .fill(participant.rank <= 3 ? rankColor(participant.rank).opacity(0.2) : Color(.systemGray5))
                    .frame(width: 36, height: 36)

                if participant.rank <= 3 {
                    Image(systemName: participant.rank == 1 ? "trophy.fill" : "medal.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(rankColor(participant.rank))
                } else {
                    Text("\(participant.rank)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)
                }
            }

            // Name
            Text(participant.nickname ?? "Anonymous")
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(1)

            Spacer()

            // Stats
            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption2)
                        .foregroundStyle(.green)
                    Text("\(participant.completionCount)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }

                Text(participant.formattedAttendanceRate)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Action Buttons

    private func actionButtons(_ challenge: Challenge) -> some View {
        VStack(spacing: 12) {
            // Prize Distribution Button (show when challenge ended but not finalized)
            if authManager.isLoggedIn && isChallengeEnded(challenge) && challenge.status != .completed {
                Button {
                    showingFinalizeAlert = true
                } label: {
                    HStack {
                        Image(systemName: "trophy.fill")
                        Text("Distribute Prizes")
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [.orange, .orange.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }

            if !authManager.isLoggedIn {
                Button {
                    showingLoginPrompt = true
                } label: {
                    HStack {
                        Image(systemName: "person.fill")
                        Text("Login to Join")
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            } else if challenge.canJoin == true {
                Button {
                    showingJoinAlert = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Join Challenge (\(challenge.formattedEntryFee))")
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [.blue, .blue.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            } else if challenge.canLeave == true {
                Button {
                    showingLeaveAlert = true
                } label: {
                    HStack {
                        Image(systemName: "xmark.circle")
                        Text("Leave Challenge")
                    }
                    .font(.headline)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.red.opacity(0.3), lineWidth: 1)
                    )
                }
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Finalize Result View

    private var finalizeResultView: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.1))
                    .frame(width: 120, height: 120)
                Image(systemName: "trophy.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(.orange)
            }

            Text("Prizes Distributed!")
                .font(.title)
                .fontWeight(.bold)

            VStack(spacing: 12) {
                ForEach(finalizeRankings) { ranking in
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(rankColor(ranking.rank).opacity(0.2))
                                .frame(width: 40, height: 40)
                            Image(systemName: ranking.rank == 1 ? "trophy.fill" : "medal.fill")
                                .foregroundStyle(rankColor(ranking.rank))
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(ranking.nickname ?? "Anonymous")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text("\(ranking.completionCount) completions")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text(ranking.formattedPrizeWon)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundStyle(.orange)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.horizontal)

            Spacer()

            Button {
                showingFinalizeResult = false
            } label: {
                Text("Done")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
        .navigationTitle("Results")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Helper Functions

    private func statusColor(_ challenge: Challenge) -> Color {
        switch challenge.computedStatus {
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

    private func joinChallenge() async {
        do {
            try await challengeManager.joinChallenge(id: challengeId)
            await challengeManager.fetchChallengeDetail(id: challengeId)
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }

    private func leaveChallenge() async {
        do {
            _ = try await challengeManager.leaveChallenge(id: challengeId)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }

    private func startWorkout(_ challenge: Challenge) {
        guard let routineData = challenge.routineData else { return }
        let routine = routineData.toRoutine(name: challenge.routineName)
        selectedRoutine = routine
    }

    private func isChallengeEnded(_ challenge: Challenge) -> Bool {
        guard let endDate = challenge.challengeEndDate else { return false }
        return Date() > endDate
    }

    private func finalizeChallenge() async {
        do {
            let rankings = try await challengeManager.finalizeChallenge(id: challengeId)
            finalizeRankings = rankings
            showingFinalizeResult = true
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}

#Preview {
    NavigationStack {
        ChallengeDetailView(challengeId: 1)
    }
    .environmentObject(RoutineStore())
}
