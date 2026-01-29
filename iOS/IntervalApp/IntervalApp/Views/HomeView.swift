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
    @State private var selectedChallengeForDetail: ChallengeListItem?

    var body: some View {
        NavigationStack {
            Group {
                if routineStore.routines.isEmpty && challengeManager.activeChallenges.isEmpty {
                    emptyStateView
                } else {
                    routineListView
                }
            }
            .background(
                LinearGradient(
                    colors: [
                        Color.blue.opacity(0.05),
                        Color(.systemGroupedBackground)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationTitle(greetingText)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingTemplateSelection = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.blue)
                    }
                }
            }
            .refreshable {
                if AuthManager.shared.isLoggedIn {
                    try? await challengeManager.fetchMyChallenges()
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
            .sheet(item: $selectedChallengeForDetail) { challenge in
                NavigationStack {
                    ChallengeDetailView(challengeId: challenge.id)
                }
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

    // MARK: - Greeting

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())

        if hour < 12 {
            return String(localized: "Good Morning ☕", comment: "Morning greeting shown in home screen title")
        } else if hour < 17 {
            return String(localized: "Good Afternoon ☀️", comment: "Afternoon greeting shown in home screen title")
        } else {
            return String(localized: "Good Evening 🌙", comment: "Evening greeting shown in home screen title")
        }
    }

    // MARK: - Empty State View

    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 120, height: 120)

                Image(systemName: "timer")
                    .font(.system(size: 50))
                    .foregroundStyle(.blue)
            }

            VStack(spacing: 8) {
                Text("No Routines Yet")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Create your first interval routine to get started!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Button {
                showingTemplateSelection = true
            } label: {
                HStack {
                    Image(systemName: "plus")
                    Text("Create Routine")
                }
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.blue)
                .clipShape(Capsule())
            }

            Spacer()
        }
    }

    // MARK: - Routine List View

    private var routineListView: some View {
        List {
            // 참여 중인 챌린지 섹션
            if !challengeManager.activeChallenges.isEmpty {
                Section {
                    ForEach(challengeManager.activeChallenges) { challenge in
                        challengeRoutineRow(challenge)
                    }
                } header: {
                    HStack(spacing: 6) {
                        Image(systemName: "trophy.fill")
                            .foregroundStyle(.orange)
                        Text(String(localized: "Active Challenges"))
                            .foregroundStyle(.orange)
                            .fontWeight(.semibold)
                    }
                    .textCase(nil)
                }
            }

            // 즐겨찾기 섹션
            if !routineStore.favoriteRoutines.isEmpty {
                Section {
                    ForEach(routineStore.favoriteRoutines) { routine in
                        routineRow(routine)
                    }
                } header: {
                    HStack(spacing: 6) {
                        Image(systemName: "star.fill")
                            .foregroundStyle(.yellow)
                        Text("Favorites")
                            .fontWeight(.semibold)
                    }
                    .textCase(nil)
                }
            }

            // 모든 루틴 섹션
            if !routineStore.regularRoutines.isEmpty {
                Section {
                    ForEach(routineStore.regularRoutines) { routine in
                        routineRow(routine)
                    }
                } header: {
                    if !routineStore.favoriteRoutines.isEmpty || !challengeManager.activeChallenges.isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "list.bullet")
                                .foregroundStyle(.blue)
                            Text("Routines")
                                .fontWeight(.semibold)
                        }
                        .textCase(nil)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }

    // 챌린지 운동 시작
    private func startChallengeWorkout(_ challenge: ChallengeListItem) {
        guard let routine = challenge.toRoutine() else {
            #if DEBUG
            print("❌ startChallengeWorkout - Failed to create routine from challenge: \(challenge.title)")
            #endif
            return
        }
        #if DEBUG
        print("🏃 startChallengeWorkout - Starting workout: \(routine.name), intervals: \(routine.intervals.count), rounds: \(routine.rounds)")
        #endif
        selectedChallengeForWorkout = challenge
        challengeRoutine = routine
    }

    // 챌린지 루틴 행 뷰
    @ViewBuilder
    private func challengeRoutineRow(_ challenge: ChallengeListItem) -> some View {
        HStack(spacing: 12) {
            // Challenge Icon
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.orange.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: "trophy.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.orange)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(challenge.title)
                    .font(.headline)

                if let routineData = challenge.routineData {
                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image(systemName: "list.bullet")
                                .font(.caption2)
                                .foregroundStyle(.blue)
                            Text("\(routineData.intervals.count)")
                                .font(.caption)
                        }
                        HStack(spacing: 4) {
                            Image(systemName: "repeat")
                                .font(.caption2)
                                .foregroundStyle(.green)
                            Text("\(routineData.rounds)")
                                .font(.caption)
                        }

                        // 총 시간
                        let totalSeconds = routineData.intervals.reduce(0) { $0 + $1.duration } * routineData.rounds
                        let minutes = totalSeconds / 60
                        let seconds = totalSeconds % 60
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.caption2)
                                .foregroundStyle(.purple)
                            if minutes > 0 {
                                Text("\(minutes)m \(seconds)s")
                                    .font(.caption)
                            } else {
                                Text("\(seconds)s")
                                    .font(.caption)
                            }
                        }
                    }
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
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.orange)
                            .clipShape(Capsule())
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
        // 왼쪽 스와이프 → 챌린지 상세 보기
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button {
                selectedChallengeForDetail = challenge
            } label: {
                Label("Detail", systemImage: "info.circle")
            }
            .tint(.orange)
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
        HStack(spacing: 12) {
            // Routine Icon
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: "timer")
                    .font(.system(size: 20))
                    .foregroundStyle(.blue)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(routine.name)
                    .font(.headline)

                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "list.bullet")
                            .font(.caption2)
                            .foregroundStyle(.blue)
                        Text("\(routine.intervals.count)")
                            .font(.caption)
                    }
                    HStack(spacing: 4) {
                        Image(systemName: "repeat")
                            .font(.caption2)
                            .foregroundStyle(.green)
                        Text("\(routine.rounds)")
                            .font(.caption)
                    }
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption2)
                            .foregroundStyle(.purple)
                        Text(routine.formattedTotalDuration)
                            .font(.caption)
                    }
                }
                .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    HomeView()
        .environmentObject(RoutineStore())
}
