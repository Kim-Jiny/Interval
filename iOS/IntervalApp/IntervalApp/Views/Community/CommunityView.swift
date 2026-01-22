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
            .background(
                LinearGradient(
                    colors: [
                        Color.orange.opacity(0.05),
                        Color(.systemGroupedBackground)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
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
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.orange)
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
            HStack(spacing: 16) {
                // Mileage Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.orange, .orange.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)

                    Text("M")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("My Mileage")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if authManager.isLoggedIn {
                        Text(mileageManager.balance?.formattedBalance ?? "0M")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)
                    } else {
                        Text(String(localized: "Login to view"))
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.orange.opacity(0.3))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .orange.opacity(0.15), radius: 10, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.orange.opacity(0.2), lineWidth: 1)
            )
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
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(.orange)
                    Text("My Challenges")
                        .font(.headline)
                }
                Spacer()

                if challengeManager.myChallenges.count > 5 {
                    Button {
                        showingMyChallenges = true
                    } label: {
                        HStack(spacing: 4) {
                            Text("More")
                                .font(.subheadline)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                        }
                        .foregroundStyle(.orange)
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
                .padding(.vertical, 4)
            }
        }
    }

    // MARK: - Public Challenges Section

    private var joinableChallengesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "globe")
                        .foregroundStyle(.blue)
                    Text("Public Challenges")
                        .font(.headline)
                }
                Spacer()
            }
            .padding(.horizontal)

            if challengeManager.joinableChallenges.isEmpty && !challengeManager.isLoading {
                // Empty State
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.orange.opacity(0.1))
                            .frame(width: 80, height: 80)

                        Image(systemName: "trophy.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(.orange)
                    }

                    VStack(spacing: 4) {
                        Text("No challenges available")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text("Create your own challenge!")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Button {
                        if authManager.isLoggedIn {
                            showingCreateChallenge = true
                        } else {
                            showingLoginPrompt = true
                        }
                    } label: {
                        HStack {
                            Image(systemName: "plus")
                            Text("Create Challenge")
                        }
                        .font(.callout)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.orange)
                        .clipShape(Capsule())
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground))
                )
                .padding(.horizontal)
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
                HStack {
                    Spacer()
                    ProgressView()
                        .tint(.orange)
                    Spacer()
                }
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
                    HStack(spacing: 4) {
                        Image(systemName: "gift.fill")
                            .font(.caption2)
                        Text("Claim Prize")
                            .font(.caption2)
                            .fontWeight(.semibold)
                    }
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
                        .background(statusColor.opacity(0.15))
                        .foregroundStyle(statusColor)
                        .clipShape(Capsule())
                }

                Spacer()
            }

            Text(challenge.title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(2)
                .foregroundStyle(.primary)

            Text(challenge.routineName)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Spacer()

            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "person.2.fill")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("\(challenge.participantCount)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                HStack(spacing: 2) {
                    Image(systemName: "trophy.fill")
                        .font(.caption2)
                    Text(challenge.formattedPrizePool)
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(.orange)
            }
        }
        .padding()
        .frame(width: 165, height: 145)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.systemBackground))
                .shadow(color: statusColor.opacity(0.2), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(statusColor.opacity(0.3), lineWidth: 1)
        )
        .overlay(alignment: .topTrailing) {
            if challenge.needsClaimPrize {
                Circle()
                    .fill(.orange)
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle()
                            .stroke(.white, lineWidth: 2)
                    )
                    .offset(x: 4, y: -4)
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
