//
//  CalendarView.swift
//  IntervalApp
//
//  Created on 1/26/26.
//

import SwiftUI
import HealthKit

struct CalendarView: View {
    @StateObject private var healthKitManager = HealthKitManager.shared
    @StateObject private var historyManager = WorkoutHistoryManager.shared
    @ObservedObject private var authManager = AuthManager.shared

    @State private var currentDate = Date()
    @State private var selectedDate: Date?
    @State private var healthKitWorkouts: [HKWorkout] = []
    @State private var appRecords: [WorkoutRecord] = []
    @State private var isLoadingHealthKit = false
    @State private var isLoadingAppRecords = false
    @State private var recordToDelete: WorkoutRecord?
    @State private var showingDeleteAlert = false

    private let calendar = Calendar.current

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 16) {
                        // 월 선택 헤더
                        monthHeader
                            .padding(.top, 8)

                        // 캘린더 그리드
                        CalendarGridView(
                            currentDate: currentDate,
                            selectedDate: $selectedDate,
                            healthKitWorkouts: healthKitWorkouts,
                            appRecords: appRecords,
                            onDateSelected: { date in
                                withAnimation {
                                    selectedDate = date
                                }
                                // 선택된 날짜 상세로 스크롤
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    withAnimation {
                                        proxy.scrollTo("selectedDateDetail", anchor: .top)
                                    }
                                }
                            }
                        )

                        // 이번 달 운동 요약
                        monthSummary

                        // 선택된 날짜의 운동 상세
                        if let date = selectedDate {
                            selectedDateDetailView(date: date)
                                .id("selectedDateDetail")
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }
                    }
                    .padding()
                }
            }
            .background(
                LinearGradient(
                    colors: [
                        Color.orange.opacity(0.1),
                        Color(.secondarySystemBackground)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationBarHidden(true)
            .task {
                await loadData()
            }
            .onChange(of: currentDate) { _, _ in
                Task {
                    await loadData()
                }
            }
            .refreshable {
                await loadData()
            }
            .alert("Delete Workout", isPresented: $showingDeleteAlert, presenting: recordToDelete) { record in
                Button("Cancel", role: .cancel) {
                    recordToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    Task {
                        await deleteRecord(record)
                    }
                }
            } message: { record in
                Text("Are you sure you want to delete '\(record.routineName)'?")
            }
        }
    }

    // MARK: - Views

    private var monthHeader: some View {
        HStack {
            Button {
                withAnimation {
                    currentDate = calendar.date(byAdding: .month, value: -1, to: currentDate) ?? currentDate
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundStyle(.primary)
            }

            Spacer()

            Text(monthYearString)
                .font(.title2)
                .fontWeight(.bold)

            Spacer()

            // 오늘 버튼 (현재 월이 아닐 때만 표시)
            if !isCurrentMonth {
                Button {
                    withAnimation {
                        currentDate = Date()
                        selectedDate = nil
                    }
                } label: {
                    Image(systemName: "calendar.badge.clock")
                        .font(.title2)
                        .foregroundStyle(.blue)
                }
            }

            Button {
                withAnimation {
                    currentDate = calendar.date(byAdding: .month, value: 1, to: currentDate) ?? currentDate
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .foregroundStyle(.primary)
            }
        }
        .padding(.horizontal)
    }

    /// 현재 표시 중인 월이 오늘의 월인지 확인
    private var isCurrentMonth: Bool {
        let now = Date()
        return calendar.component(.year, from: currentDate) == calendar.component(.year, from: now) &&
               calendar.component(.month, from: currentDate) == calendar.component(.month, from: now)
    }

    private var monthSummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This Month", comment: "Section title for monthly workout summary")
                .font(.headline)

            HStack(spacing: 16) {
                // HealthKit 운동
                summaryCard(
                    icon: "heart.fill",
                    color: .blue,
                    value: "\(healthKitWorkouts.count)",
                    label: String(localized: "Health Workouts")
                )

                // 앱 운동
                summaryCard(
                    icon: "timer",
                    color: .orange,
                    value: "\(appRecords.count)",
                    label: String(localized: "App Workouts")
                )
            }

            // 운동 일수 & 총 시간
            let workoutDays = uniqueWorkoutDays
            HStack(spacing: 16) {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundStyle(.green)
                    Text("\(workoutDays) workout days", comment: "Number of days with workouts this month")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if totalWorkoutDuration > 0 {
                    HStack {
                        Image(systemName: "clock.fill")
                            .foregroundStyle(.purple)
                        Text(formattedTotalDuration)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private func summaryCard(icon: String, color: Color, value: String, label: String) -> some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
            }
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Selected Date Detail View

    private func selectedDateDetailView(date: Date) -> some View {
        let workouts = workoutsForDate(date)
        let records = appRecordsForDate(date)

        return VStack(alignment: .leading, spacing: 12) {
            // 날짜 헤더
            HStack {
                Text(selectedDateString(date))
                    .font(.headline)

                Spacer()

                Button {
                    withAnimation {
                        selectedDate = nil
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }

            if workouts.isEmpty && records.isEmpty {
                // 빈 상태
                VStack(spacing: 8) {
                    Image(systemName: "figure.walk")
                        .font(.title)
                        .foregroundStyle(.secondary)
                    Text("No workouts recorded", comment: "Message shown when no workouts exist for a date")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                // HealthKit 운동
                ForEach(workouts, id: \.uuid) { workout in
                    healthKitWorkoutRow(workout)
                }

                // 앱 운동 기록
                ForEach(records) { record in
                    appRecordRow(record)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private func selectedDateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M월 d일 (E)"
        return formatter.string(from: date)
    }

    private func healthKitWorkoutRow(_ workout: HKWorkout) -> some View {
        HStack(spacing: 12) {
            Image(systemName: workout.symbolName)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 36, height: 36)
                .background(.blue.opacity(0.1))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(workout.workoutTypeName)
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack(spacing: 12) {
                    Label(workout.formattedDuration, systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let calories = workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) {
                        Label("\(Int(calories)) kcal", systemImage: "flame")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            Text(timeString(from: workout.startDate))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func appRecordRow(_ record: WorkoutRecord) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "timer")
                .font(.title3)
                .foregroundStyle(.orange)
                .frame(width: 36, height: 36)
                .background(.orange.opacity(0.1))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(record.routineName)
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack(spacing: 12) {
                    Label(record.formattedDuration, systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Label("\(record.roundsCompleted) rounds", systemImage: "repeat")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if let createdAt = record.createdAt {
                Text(timeStringFromString(createdAt))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // 삭제 버튼
            Button {
                recordToDelete = record
                showingDeleteAlert = true
            } label: {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundStyle(.red.opacity(0.7))
            }
        }
        .padding(12)
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func timeStringFromString(_ string: String) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        if let date = inputFormatter.date(from: string) {
            let outputFormatter = DateFormatter()
            outputFormatter.timeStyle = .short
            return outputFormatter.string(from: date)
        }
        return ""
    }

    // MARK: - Computed Properties

    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentDate)
    }

    private var uniqueWorkoutDays: Int {
        var dates = Set<String>()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        for workout in healthKitWorkouts {
            dates.insert(formatter.string(from: workout.startDate))
        }

        for record in appRecords {
            dates.insert(record.workoutDate)
        }

        return dates.count
    }

    /// 총 운동 시간 (초)
    private var totalWorkoutDuration: Int {
        var total = 0

        // HealthKit 운동 시간
        for workout in healthKitWorkouts {
            total += Int(workout.duration)
        }

        // 앱 운동 시간
        for record in appRecords {
            total += record.totalDuration
        }

        return total
    }

    /// 포맷된 총 운동 시간
    private var formattedTotalDuration: String {
        let hours = totalWorkoutDuration / 3600
        let minutes = (totalWorkoutDuration % 3600) / 60

        if hours > 0 {
            return String(format: "%dh %dm", hours, minutes)
        } else {
            return String(format: "%dm", minutes)
        }
    }

    // MARK: - Methods

    private func loadData() async {
        let year = calendar.component(.year, from: currentDate)
        let month = calendar.component(.month, from: currentDate)

        // HealthKit 데이터 로드
        isLoadingHealthKit = true
        if !healthKitManager.isAuthorized {
            _ = await healthKitManager.requestAuthorization()
        }
        healthKitWorkouts = await healthKitManager.fetchWorkoutsForMonth(year: year, month: month)
        isLoadingHealthKit = false

        // 앱 운동 기록 로드 (로그인된 경우만)
        if authManager.isLoggedIn {
            isLoadingAppRecords = true
            do {
                appRecords = try await historyManager.fetchHistory(year: year, month: month)
            } catch {
                print("Failed to load app records: \(error)")
                appRecords = []
            }
            isLoadingAppRecords = false
        } else {
            appRecords = []
        }
    }

    private func deleteRecord(_ record: WorkoutRecord) async {
        let year = calendar.component(.year, from: currentDate)
        let month = calendar.component(.month, from: currentDate)

        do {
            try await historyManager.deleteRecord(id: record.id, year: year, month: month)
            // 로컬 배열에서도 제거
            withAnimation {
                appRecords.removeAll { $0.id == record.id }
            }
        } catch {
            print("Failed to delete record: \(error)")
        }

        recordToDelete = nil
    }

    private func workoutsForDate(_ date: Date) -> [HKWorkout] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: date)

        return healthKitWorkouts.filter {
            formatter.string(from: $0.startDate) == dateString
        }
    }

    private func appRecordsForDate(_ date: Date) -> [WorkoutRecord] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: date)

        return appRecords.filter { $0.workoutDate == dateString }
    }
}

#Preview {
    CalendarView()
}
