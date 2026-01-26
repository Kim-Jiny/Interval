//
//  CalendarDayCell.swift
//  IntervalApp
//
//  Created on 1/26/26.
//

import SwiftUI

struct CalendarDayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let hasHealthKitWorkout: Bool
    let hasAppWorkout: Bool

    private let calendar = Calendar.current

    var body: some View {
        VStack(spacing: 4) {
            // 날짜 숫자
            Text("\(calendar.component(.day, from: date))")
                .font(.system(size: 16, weight: isToday ? .bold : .regular))
                .foregroundStyle(textColor)
                .frame(width: 32, height: 32)
                .background(backgroundColor)
                .clipShape(Circle())

            // 운동 인디케이터
            HStack(spacing: 2) {
                if hasHealthKitWorkout {
                    Circle()
                        .fill(.blue)
                        .frame(width: 6, height: 6)
                }
                if hasAppWorkout {
                    Circle()
                        .fill(.orange)
                        .frame(width: 6, height: 6)
                }
            }
            .frame(height: 6)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
    }

    private var textColor: Color {
        if isSelected {
            return .white
        } else if isToday {
            return .blue
        } else {
            return .primary
        }
    }

    private var backgroundColor: Color {
        if isSelected {
            return .blue
        } else if isToday {
            return .blue.opacity(0.2)
        } else {
            return .clear
        }
    }
}

#Preview {
    HStack {
        CalendarDayCell(
            date: Date(),
            isSelected: false,
            isToday: true,
            hasHealthKitWorkout: true,
            hasAppWorkout: false
        )

        CalendarDayCell(
            date: Date(),
            isSelected: true,
            isToday: false,
            hasHealthKitWorkout: false,
            hasAppWorkout: true
        )

        CalendarDayCell(
            date: Date(),
            isSelected: false,
            isToday: false,
            hasHealthKitWorkout: true,
            hasAppWorkout: true
        )
    }
    .padding()
}
