//
//  WorkoutDetailSheet.swift
//  IntervalApp
//
//  Created on 1/26/26.
//

import SwiftUI
import HealthKit

struct WorkoutDetailSheet: View {
    let date: Date
    let healthKitWorkouts: [HKWorkout]
    let appRecords: [WorkoutRecord]

    @Environment(\.dismiss) private var dismiss

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 날짜 헤더
                    Text(dateString)
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal)

                    if healthKitWorkouts.isEmpty && appRecords.isEmpty {
                        emptyView
                    } else {
                        // HealthKit 운동
                        if !healthKitWorkouts.isEmpty {
                            healthKitSection
                        }

                        // 앱 운동 기록
                        if !appRecords.isEmpty {
                            appRecordsSection
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle(String(localized: "Workout Details"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    // MARK: - Views

    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.walk")
                .font(.system(size: 50))
                .foregroundStyle(.secondary)

            Text("No workouts recorded", comment: "Message shown when no workouts exist for a date")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text("Start a workout to see it here!", comment: "Encouragement to start a workout")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private var healthKitSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundStyle(.blue)
                Text("Health Workouts", comment: "Section title for HealthKit workouts")
                    .font(.headline)
            }
            .padding(.horizontal)

            ForEach(healthKitWorkouts, id: \.uuid) { workout in
                healthKitWorkoutRow(workout)
            }
        }
    }

    private func healthKitWorkoutRow(_ workout: HKWorkout) -> some View {
        HStack(spacing: 12) {
            Image(systemName: workout.symbolName)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 44, height: 44)
                .background(.blue.opacity(0.1))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(workout.workoutTypeName)
                    .font(.headline)

                HStack(spacing: 16) {
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
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }

    private var appRecordsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "timer")
                    .foregroundStyle(.orange)
                Text("IntervalMate Workouts", comment: "Section title for app workout records")
                    .font(.headline)
            }
            .padding(.horizontal)

            ForEach(appRecords) { record in
                appRecordRow(record)
            }
        }
    }

    private func appRecordRow(_ record: WorkoutRecord) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "timer")
                .font(.title2)
                .foregroundStyle(.orange)
                .frame(width: 44, height: 44)
                .background(.orange.opacity(0.1))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(record.routineName)
                    .font(.headline)

                HStack(spacing: 16) {
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
                Text(timeString(from: createdAt))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }

    // MARK: - Helpers

    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func timeString(from string: String) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        if let date = inputFormatter.date(from: string) {
            let outputFormatter = DateFormatter()
            outputFormatter.timeStyle = .short
            return outputFormatter.string(from: date)
        }

        return ""
    }
}

#Preview {
    WorkoutDetailSheet(
        date: Date(),
        healthKitWorkouts: [],
        appRecords: []
    )
}
