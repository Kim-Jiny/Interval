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
                ProgressView()
            } else if let challenge = challengeManager.currentChallenge {
                ScrollView {
                    VStack(spacing: 20) {
                        // Header Card
                        headerCard(challenge)

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
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("Challenge not found")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle(challengeManager.currentChallenge?.title ?? "Challenge")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if let challenge = challengeManager.currentChallenge {
                    Button {
                        showingShareSheet = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
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
            HStack {
                Text(challenge.computedStatus.displayName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(statusColor(challenge).opacity(0.15))
                    .foregroundStyle(statusColor(challenge))
                    .clipShape(Capsule())

                Spacer()

                if challenge.isParticipating == true {
                    Text("Participating")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.green)
                }
            }

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

            // Stats Row
            HStack(spacing: 20) {
                VStack {
                    Text("\(challenge.participantCount)")
                        .font(.title3)
                        .fontWeight(.bold)
                    Text("Participants")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Divider()
                    .frame(height: 40)

                VStack {
                    Text(challenge.formattedEntryFee)
                        .font(.title3)
                        .fontWeight(.bold)
                    Text("Entry Fee")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Divider()
                    .frame(height: 40)

                VStack {
                    Text(challenge.formattedPrizePool)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.orange)
                    Text("Prize Pool")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }

    // MARK: - Prize Distribution Card

    private func prizeDistributionCard(_ challenge: Challenge) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Prize Distribution")
                .font(.headline)

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
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }

    private func prizeRow(rank: Int, percentage: Int, prizePool: Int) -> some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: rank == 1 ? "trophy.fill" : (rank == 2 ? "medal.fill" : "medal"))
                    .foregroundStyle(rank == 1 ? .yellow : (rank == 2 ? .gray : .brown))
                Text("\(rank)st")
                    .fontWeight(.semibold)
            }

            Spacer()

            Text("\(percentage)%")
                .foregroundStyle(.secondary)

            Text("\((prizePool * percentage / 100).formatted(.number))M")
                .fontWeight(.bold)
                .foregroundStyle(.orange)
                .frame(width: 80, alignment: .trailing)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Routine Card

    private func routineCard(_ challenge: Challenge) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Routine")
                .font(.headline)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(challenge.routineName)
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    if let routineData = challenge.routineData {
                        HStack(spacing: 12) {
                            Label("\(routineData.intervals.count) intervals", systemImage: "list.bullet")
                            Label("\(routineData.rounds) rounds", systemImage: "repeat")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                if challenge.isParticipating == true, challenge.computedStatus == .active {
                    Button {
                        startWorkout(challenge)
                    } label: {
                        Label("Start", systemImage: "play.fill")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }

    // MARK: - Dates Card

    private func datesCard(_ challenge: Challenge) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Schedule")
                .font(.headline)

            VStack(spacing: 8) {
                dateRow(title: "Registration", startDate: challenge.registrationStartDate, endDate: challenge.registrationEndDate)
                Divider()
                dateRow(title: "Challenge", startDate: challenge.challengeStartDate, endDate: challenge.challengeEndDate)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }

    private func dateRow(title: String, startDate: Date?, endDate: Date?) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            if let start = startDate, let end = endDate {
                Text("\(start, style: .date) - \(end, style: .date)")
                    .font(.subheadline)
            }
        }
    }

    // MARK: - Participants Section

    private var participantsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Leaderboard")
                .font(.headline)

            if challengeManager.currentParticipants.isEmpty {
                Text("No participants yet")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(challengeManager.currentParticipants) { participant in
                        participantRow(participant)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }

    private func participantRow(_ participant: ChallengeParticipant) -> some View {
        HStack {
            // Rank
            Text("#\(participant.rank)")
                .font(.subheadline)
                .fontWeight(.bold)
                .frame(width: 30)

            // Name
            Text(participant.nickname ?? "Anonymous")
                .font(.subheadline)
                .lineLimit(1)

            Spacer()

            // Stats
            VStack(alignment: .trailing) {
                Text("\(participant.completionCount) days")
                    .font(.caption)
                    .fontWeight(.semibold)
                Text(participant.formattedAttendanceRate)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Action Buttons

    private func actionButtons(_ challenge: Challenge) -> some View {
        VStack(spacing: 12) {
            // Prize Distribution Button (show when challenge ended but not finalized)
            if authManager.isLoggedIn && isChallengeEnded(challenge) && challenge.status != .completed {
                Button {
                    showingFinalizeAlert = true
                } label: {
                    Label("Distribute Prizes", systemImage: "trophy.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
            }

            if !authManager.isLoggedIn {
                Button {
                    showingLoginPrompt = true
                } label: {
                    Text("Login to Join")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            } else if challenge.canJoin == true {
                Button {
                    showingJoinAlert = true
                } label: {
                    Text("Join Challenge (\(challenge.formattedEntryFee))")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            } else if challenge.canLeave == true {
                Button(role: .destructive) {
                    showingLeaveAlert = true
                } label: {
                    Text("Leave Challenge")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
    }

    // MARK: - Finalize Result View

    private var finalizeResultView: some View {
        VStack(spacing: 20) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 60))
                .foregroundStyle(.orange)

            Text("Prizes Distributed!")
                .font(.title)
                .fontWeight(.bold)

            VStack(spacing: 12) {
                ForEach(finalizeRankings) { ranking in
                    HStack {
                        HStack(spacing: 8) {
                            Image(systemName: ranking.rank == 1 ? "trophy.fill" : (ranking.rank == 2 ? "medal.fill" : "medal"))
                                .foregroundStyle(ranking.rank == 1 ? .yellow : (ranking.rank == 2 ? .gray : .brown))
                            Text("#\(ranking.rank)")
                                .fontWeight(.bold)
                            Text(ranking.nickname ?? "Anonymous")
                        }

                        Spacer()

                        VStack(alignment: .trailing) {
                            Text(ranking.formattedPrizeWon)
                                .fontWeight(.bold)
                                .foregroundStyle(.orange)
                            Text("\(ranking.completionCount) days")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding()

            Button {
                showingFinalizeResult = false
            } label: {
                Text("Done")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding()
        }
        .padding()
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
