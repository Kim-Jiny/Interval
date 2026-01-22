//
//  HomeView.swift
//  IntervalApp
//
//  Created by 김미진 on 1/14/26.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var routineStore: RoutineStore
    @ObservedObject private var shareManager = RoutineShareManager.shared
    @ObservedObject private var challengeManager = ChallengeManager.shared
    @State private var showingTemplateSelection = false
    @State private var pendingTemplate: Routine?
    @State private var templateForEditing: Routine?
    @State private var routineToEdit: Routine?
    @State private var selectedRoutine: Routine?
    @State private var routineToShare: Routine?
    @State private var shareUrl: String?
    @State private var showingShareSheet = false
    @State private var showingLoginPrompt = false
    @State private var shareError: String?
    @State private var showingShareError = false

    // Challenge workout state
    @State private var selectedChallengeForWorkout: ChallengeListItem?
    @State private var challengeRoutine: Routine?

    var body: some View {
        NavigationStack {
            List {
                // 참여 중인 챌린지 섹션
                if !challengeManager.activeChallenges.isEmpty {
                    Section {
                        ForEach(challengeManager.activeChallenges) { challenge in
                            challengeRoutineRow(challenge)
                        }
                    } header: {
                        Label(String(localized: "Active Challenges"), systemImage: "trophy.fill")
                            .foregroundStyle(.orange)
                    }
                }

                // 즐겨찾기 섹션
                if !routineStore.favoriteRoutines.isEmpty {
                    Section {
                        ForEach(routineStore.favoriteRoutines) { routine in
                            routineRow(routine)
                        }
                    } header: {
                        Label("Favorites", systemImage: "star.fill")
                            .foregroundStyle(.yellow)
                    }
                }

                // 모든 루틴 섹션
                Section {
                    ForEach(routineStore.regularRoutines) { routine in
                        routineRow(routine)
                    }
                } header: {
                    if !routineStore.favoriteRoutines.isEmpty {
                        Label("Routines", systemImage: "list.bullet")
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(String(localized: "IntervalMate"))
            .refreshable {
                if AuthManager.shared.isLoggedIn {
                    try? await challengeManager.fetchMyChallenges()
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingTemplateSelection = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingTemplateSelection, onDismiss: {
                if let template = pendingTemplate {
                    pendingTemplate = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        templateForEditing = template
                    }
                }
            }) {
                TemplateSelectionView { routine in
                    pendingTemplate = routine
                }
            }
            .sheet(item: $templateForEditing) { routine in
                NavigationStack {
                    RoutineEditorView(routine: routine, isNew: true)
                }
            }
            .sheet(item: $routineToEdit) { routine in
                NavigationStack {
                    RoutineEditorView(routine: routine, isNew: false)
                }
            }
            .fullScreenCover(item: $selectedRoutine) { routine in
                TimerView(routine: routine)
            }
            .fullScreenCover(item: $challengeRoutine) { routine in
                TimerView(routine: routine, isChallengeMode: true) {
                    // 챌린지 운동 완료 시 기록
                    if let challenge = selectedChallengeForWorkout {
                        Task {
                            try? await challengeManager.recordWorkout(
                                challengeId: challenge.id,
                                totalDuration: Int(routine.totalDuration),
                                roundsCompleted: routine.rounds
                            )
                        }
                    }
                    selectedChallengeForWorkout = nil
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let url = shareUrl {
                    ShareSheet(items: [URL(string: url)!])
                }
            }
            .sheet(isPresented: $showingLoginPrompt) {
                LoginView()
            }
            .alert(String(localized: "Share Error", comment: "Share error alert title"), isPresented: $showingShareError) {
                Button(String(localized: "OK", comment: "OK button"), role: .cancel) {}
            } message: {
                Text(shareError ?? "")
            }
            .onChange(of: AuthManager.shared.isLoggedIn) { _, isLoggedIn in
                // 로그인 후 공유 재시도
                if isLoggedIn, let routine = routineToShare {
                    routineToShare = nil
                    shareRoutine(routine)
                }
            }
            .task {
                // 로그인 상태면 챌린지 목록 가져오기
                if AuthManager.shared.isLoggedIn {
                    try? await challengeManager.fetchMyChallenges()
                }
            }
        }
    }

    // 챌린지 운동 시작
    private func startChallengeWorkout(_ challenge: ChallengeListItem) {
        guard let routine = challenge.toRoutine() else { return }
        selectedChallengeForWorkout = challenge
        challengeRoutine = routine
    }

    // 챌린지 루틴 행 뷰 (일반 루틴과 동일한 스타일)
    @ViewBuilder
    private func challengeRoutineRow(_ challenge: ChallengeListItem) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(challenge.title)
                    .font(.headline)

                if let routineData = challenge.routineData {
                    HStack(spacing: 16) {
                        Label("\(routineData.intervals.count) intervals", systemImage: "list.bullet")
                        Label("\(routineData.rounds) rounds", systemImage: "repeat")

                        // 총 시간
                        let totalSeconds = routineData.intervals.reduce(0) { $0 + $1.duration } * routineData.rounds
                        let minutes = totalSeconds / 60
                        let seconds = totalSeconds % 60
                        if minutes > 0 {
                            Label("\(minutes)m \(seconds)s", systemImage: "clock")
                        } else {
                            Label("\(seconds)s", systemImage: "clock")
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                } else {
                    Text(challenge.routineName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                // 오늘 완료 표시
                if challenge.todayCompleted == true {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.title2)
                }

                // 남은 일수 표시
                if let days = challenge.daysRemaining {
                    if days == 0 {
                        Text("D-Day")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.orange)
                    } else {
                        Text("D-\(days)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            startChallengeWorkout(challenge)
        }
    }

    // 루틴 행 뷰 (스와이프 액션 포함)
    @ViewBuilder
    private func routineRow(_ routine: Routine) -> some View {
        RoutineRowView(routine: routine)
            .contentShape(Rectangle())
            .onTapGesture {
                selectedRoutine = routine
            }
            // 왼쪽 스와이프 → 즐겨찾기
            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                Button {
                    withAnimation {
                        routineStore.toggleFavorite(routine)
                    }
                } label: {
                    Label(
                        routine.isFavorite ? "Unfavorite" : "Favorite",
                        systemImage: routine.isFavorite ? "star.slash" : "star.fill"
                    )
                }
                .tint(.yellow)
            }
            // 오른쪽 스와이프 → 공유, 편집, 삭제
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                Button(role: .destructive) {
                    routineStore.deleteRoutine(routine)
                } label: {
                    Label("Delete", systemImage: "trash")
                }

                Button {
                    routineToEdit = routine
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
                .tint(.blue)

                Button {
                    shareRoutine(routine)
                } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
                .tint(.green)
            }
    }

    private func shareRoutine(_ routine: Routine) {
        // 로그인 체크
        guard AuthManager.shared.isLoggedIn else {
            routineToShare = routine
            showingLoginPrompt = true
            return
        }

        routineToShare = routine
        Task {
            do {
                let url = try await shareManager.shareRoutine(routine)
                shareUrl = url
                showingShareSheet = true
            } catch {
                shareError = error.localizedDescription
                showingShareError = true
            }
        }
    }
}

struct RoutineRowView: View {
    let routine: Routine

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(routine.name)
                .font(.headline)

            HStack(spacing: 16) {
                Label("\(routine.intervals.count) intervals", systemImage: "list.bullet")
                Label("\(routine.rounds) rounds", systemImage: "repeat")
                Label(routine.formattedTotalDuration, systemImage: "clock")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    HomeView()
        .environmentObject(RoutineStore())
}
