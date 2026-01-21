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

    var body: some View {
        NavigationStack {
            List {
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
