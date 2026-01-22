//
//  CommunityView.swift
//  IntervalApp
//
//  Created by Claude on 2024.
//

import SwiftUI

struct CommunityView: View {
    @EnvironmentObject var routineStore: RoutineStore
    @ObservedObject private var challengeManager = ChallengeManager.shared
    @ObservedObject private var mileageManager = MileageManager.shared
    @ObservedObject private var authManager = AuthManager.shared

    @State private var showingCreateChallenge = false
    @State private var showingMileageView = false
    @State private var showingLoginPrompt = false
    @State private var showingMyChallenges = false
    @State private var selectedChallenge: ChallengeListItem?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Mileage Balance Card
                    mileageCard

                    // My Challenges Section (Horizontal Scroll)
                    if authManager.isLoggedIn && !challengeManager.myChallenges.isEmpty {
                        myChallengesSection
                    }

                    // Joinable Challenges Section
                    joinableChallengesSection
                }
                .padding(.vertical)
            }
            .navigationTitle(String(localized: "Challenge"))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        if authManager.isLoggedIn {
                            showingCreateChallenge = true
                        } else {
                            showingLoginPrompt = true
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .refreshable {
                await refreshData()
            }
            .task {
                await loadInitialData()
            }
            .sheet(isPresented: $showingCreateChallenge, onDismiss: {
                Task {
                    await refreshData()
                }
            }) {
                NavigationStack {
                    ChallengeCreateView()
                }
            }
            .sheet(isPresented: $showingMileageView) {
                NavigationStack {
                    MileageView()
                }
            }
            .sheet(isPresented: $showingLoginPrompt) {
                LoginView()
            }
            .sheet(item: $selectedChallenge) { challenge in
                NavigationStack {
                    ChallengeDetailView(challengeId: challenge.id)
                }
            }
            .sheet(isPresented: $showingMyChallenges) {
                NavigationStack {
                    MyChallengesListView()
                }
            }
        }
    }

    // MARK: - Mileage Card

    private var mileageCard: some View {
        Button {
            if authManager.isLoggedIn {
                showingMileageView = true
            } else {
                showingLoginPrompt = true
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("My Mileage")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if authManager.isLoggedIn {
                        Text(mileageManager.balance?.formattedBalance ?? "0M")
                            .font(.title)
                            .fontWeight(.bold)
                    } else {
                        Text(String(localized: "Login to view"))
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
    }

    // MARK: - My Challenges Section

    /// 정렬된 내 챌린지 (상금 수령 대기 > 진행중 > 대기중 > 완료)
    private var sortedMyChallenges: [ChallengeListItem] {
        challengeManager.myChallenges.sorted { $0.sortPriority < $1.sortPriority }
    }

    private var myChallengesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("My Challenges")
                    .font(.headline)
                Spacer()

                if challengeManager.myChallenges.count > 5 {
                    Button {
                        showingMyChallenges = true
                    } label: {
                        Text("More")
                            .font(.subheadline)
                            .foregroundStyle(.blue)
                    }
                }
            }
            .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(sortedMyChallenges.prefix(5)) { challenge in
                        MyChallengeCard(challenge: challenge)
                            .onTapGesture {
                                selectedChallenge = challenge
                            }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
        }
    }

    // MARK: - Public Challenges Section

    private var joinableChallengesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Public Challenges")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal)

            if challengeManager.joinableChallenges.isEmpty && !challengeManager.isLoading {
                VStack(spacing: 12) {
                    Image(systemName: "trophy")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                    Text("No challenges available")
                        .foregroundStyle(.secondary)
                    Text("Create your own challenge!")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(challengeManager.joinableChallenges) { challenge in
                        ChallengeRowView(challenge: challenge)
                            .onTapGesture {
                                selectedChallenge = challenge
                            }
                    }
                }
                .padding(.horizontal)
            }

            if challengeManager.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            }
        }
    }

    // MARK: - Data Loading

    private func loadInitialData() async {
        await challengeManager.fetchJoinableChallenges()
        if authManager.isLoggedIn {
            await mileageManager.fetchBalance()
            await challengeManager.fetchMyChallenges()
        }
    }

    private func refreshData() async {
        await challengeManager.refreshAll()
        if authManager.isLoggedIn {
            await mileageManager.fetchBalance()
        }
    }
}

// MARK: - My Challenge Card

struct MyChallengeCard: View {
    let challenge: ChallengeListItem

    private var currentStatus: ChallengeStatus {
        challenge.computedStatus
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if challenge.needsClaimPrize {
                    Text("Claim Prize")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.2))
                        .foregroundStyle(.orange)
                        .clipShape(Capsule())
                } else {
                    Text(currentStatus.displayName)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(statusColor.opacity(0.2))
                        .foregroundStyle(statusColor)
                        .clipShape(Capsule())
                }

                Spacer()
            }

            Text(challenge.title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(2)

            Text(challenge.routineName)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Spacer()

            HStack {
                Image(systemName: "person.2.fill")
                    .font(.caption2)
                Text("\(challenge.participantCount)")
                    .font(.caption)

                Spacer()

                Text(challenge.formattedPrizePool)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.orange)
            }
        }
        .padding()
        .frame(width: 160, height: 140)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        .overlay(alignment: .topTrailing) {
            if challenge.needsClaimPrize {
                Circle()
                    .fill(.orange)
                    .frame(width: 12, height: 12)
                    .offset(x: -4, y: 4)
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
    CommunityView()
        .environmentObject(RoutineStore())
}
