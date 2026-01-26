//
//  CalendarGridView.swift
//  IntervalApp
//
//  Created on 1/26/26.
//

import SwiftUI
import HealthKit

struct CalendarGridView: View {
    let currentDate: Date
    @Binding var selectedDate: Date?
    let healthKitWorkouts: [HKWorkout]
    let appRecords: [WorkoutRecord]
    let onDateSelected: (Date) -> Void

    private let calendar = Calendar.current
    private let daysOfWeek = Calendar.current.shortWeekdaySymbols

    var body: some View {
        VStack(spacing: 8) {
            // 요일 헤더
            HStack {
                ForEach(daysOfWeek, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // 날짜 그리드
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(daysInMonth, id: \.self) { date in
                    if let date = date {
                        CalendarDayCell(
                            date: date,
                            isSelected: isSameDay(date, selectedDate),
                            isToday: isSameDay(date, Date()),
                            hasHealthKitWorkout: hasHealthKitWorkout(for: date),
                            hasAppWorkout: hasAppWorkout(for: date)
                        )
                        .onTapGesture {
                            onDateSelected(date)
                        }
                    } else {
                        Color.clear
                            .aspectRatio(1, contentMode: .fit)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
    }

    // MARK: - Computed Properties

    private var daysInMonth: [Date?] {
        var days: [Date?] = []

        // 월의 첫 번째 날
        var components = calendar.dateComponents([.year, .month], from: currentDate)
        components.day = 1
        guard let firstDayOfMonth = calendar.date(from: components) else {
            return days
        }

        // 첫 번째 날의 요일 (1 = Sunday, 7 = Saturday)
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)

        // 빈 셀 추가 (첫 주의 빈 칸)
        let emptyDays = firstWeekday - 1
        for _ in 0..<emptyDays {
            days.append(nil)
        }

        // 월의 일수
        guard let range = calendar.range(of: .day, in: .month, for: currentDate) else {
            return days
        }

        // 날짜 추가
        for day in range {
            components.day = day
            if let date = calendar.date(from: components) {
                days.append(date)
            }
        }

        return days
    }

    // MARK: - Helper Methods

    private func isSameDay(_ date1: Date?, _ date2: Date?) -> Bool {
        guard let date1 = date1, let date2 = date2 else { return false }
        return calendar.isDate(date1, inSameDayAs: date2)
    }

    private func hasHealthKitWorkout(for date: Date) -> Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: date)

        return healthKitWorkouts.contains {
            formatter.string(from: $0.startDate) == dateString
        }
    }

    private func hasAppWorkout(for date: Date) -> Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: date)

        return appRecords.contains { $0.workoutDate == dateString }
    }
}

#Preview {
    CalendarGridView(
        currentDate: Date(),
        selectedDate: .constant(nil),
        healthKitWorkouts: [],
        appRecords: [],
        onDateSelected: { _ in }
    )
}
