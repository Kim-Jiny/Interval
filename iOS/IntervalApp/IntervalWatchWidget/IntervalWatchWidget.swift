//
//  IntervalWatchWidget.swift
//  IntervalWatchWidget
//
//  Created by Claude on 1/15/26.
//

import WidgetKit
import SwiftUI

// MARK: - Timer Widget (현재 타이머 상태)

struct TimerWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> TimerWidgetEntry {
        TimerWidgetEntry(date: Date(), isRunning: false, intervalName: String(localized: "Workout"), timeRemaining: 30, currentRound: 1, totalRounds: 3)
    }

    func getSnapshot(in context: Context, completion: @escaping (TimerWidgetEntry) -> Void) {
        let entry = TimerWidgetEntry(date: Date(), isRunning: false, intervalName: String(localized: "Workout"), timeRemaining: 30, currentRound: 1, totalRounds: 3)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TimerWidgetEntry>) -> Void) {
        // 현재 타이머 상태 가져오기 (UserDefaults에서)
        let defaults = UserDefaults.standard
        let isRunning = defaults.bool(forKey: "widgetTimerRunning")
        let intervalName = defaults.string(forKey: "widgetIntervalName") ?? String(localized: "Standby")
        let timeRemaining = defaults.double(forKey: "widgetTimeRemaining")
        let currentRound = defaults.integer(forKey: "widgetCurrentRound")
        let totalRounds = defaults.integer(forKey: "widgetTotalRounds")

        let entry = TimerWidgetEntry(
            date: Date(),
            isRunning: isRunning,
            intervalName: intervalName,
            timeRemaining: timeRemaining,
            currentRound: max(1, currentRound),
            totalRounds: max(1, totalRounds)
        )

        // 1분마다 업데이트
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 1, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

struct TimerWidgetEntry: TimelineEntry {
    let date: Date
    let isRunning: Bool
    let intervalName: String
    let timeRemaining: TimeInterval
    let currentRound: Int
    let totalRounds: Int

    var formattedTime: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct TimerWidgetView: View {
    @Environment(\.widgetFamily) var family
    var entry: TimerWidgetEntry

    var body: some View {
        switch family {
        case .accessoryCircular:
            circularView
        case .accessoryRectangular:
            rectangularView
        case .accessoryInline:
            inlineView
        case .accessoryCorner:
            cornerView
        default:
            circularView
        }
    }

    private var circularView: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 2) {
                if entry.isRunning {
                    Text(entry.formattedTime)
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                    Text(entry.intervalName)
                        .font(.system(size: 8))
                        .lineLimit(1)
                } else {
                    Image(systemName: "timer")
                        .font(.title2)
                    Text("Interval")
                        .font(.system(size: 8))
                }
            }
        }
    }

    private var rectangularView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                if entry.isRunning {
                    Text(entry.intervalName)
                        .font(.headline)
                        .lineLimit(1)
                    Text(entry.formattedTime)
                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                    Text("R\(entry.currentRound)/\(entry.totalRounds)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Interval Timer")
                        .font(.headline)
                    Text("Tap to start")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
    }

    private var inlineView: some View {
        Group {
            if entry.isRunning {
                Text("\(entry.intervalName) \(entry.formattedTime)")
            } else {
                Text("Interval Timer")
            }
        }
    }

    private var cornerView: some View {
        ZStack {
            AccessoryWidgetBackground()
            if entry.isRunning {
                Text(entry.formattedTime)
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
            } else {
                Image(systemName: "timer")
            }
        }
    }
}

// MARK: - Routine Quick Start Widget (루틴 바로가기)

struct RoutineWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> RoutineWidgetEntry {
        RoutineWidgetEntry(date: Date(), routineName: String(localized: "Tabata"), routineId: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (RoutineWidgetEntry) -> Void) {
        let entry = RoutineWidgetEntry(date: Date(), routineName: String(localized: "Tabata"), routineId: nil)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RoutineWidgetEntry>) -> Void) {
        // 첫 번째 루틴 가져오기 (UserDefaults에서)
        var firstRoutineName = String(localized: "No routines")
        var firstRoutineId: UUID? = nil

        if let data = UserDefaults.standard.data(forKey: "watchRoutines"),
           let routines = try? JSONDecoder().decode([WidgetRoutine].self, from: data),
           let first = routines.first {
            firstRoutineName = first.name
            firstRoutineId = first.id
        }

        let entry = RoutineWidgetEntry(
            date: Date(),
            routineName: firstRoutineName,
            routineId: firstRoutineId
        )

        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// 위젯용 간단한 루틴 모델
struct WidgetRoutine: Codable {
    let id: UUID
    let name: String
}

struct RoutineWidgetEntry: TimelineEntry {
    let date: Date
    let routineName: String
    let routineId: UUID?
}

struct RoutineWidgetView: View {
    @Environment(\.widgetFamily) var family
    var entry: RoutineWidgetEntry

    var body: some View {
        switch family {
        case .accessoryCircular:
            circularView
        case .accessoryRectangular:
            rectangularView
        case .accessoryInline:
            inlineView
        case .accessoryCorner:
            cornerView
        default:
            circularView
        }
    }

    private var circularView: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 2) {
                Image(systemName: "play.circle.fill")
                    .font(.title2)
                Text(entry.routineName)
                    .font(.system(size: 8))
                    .lineLimit(1)
            }
        }
    }

    private var rectangularView: some View {
        HStack {
            Image(systemName: "figure.run")
                .font(.title2)
                .foregroundStyle(.green)

            VStack(alignment: .leading, spacing: 2) {
                Text("Quick Start")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(entry.routineName)
                    .font(.headline)
                    .lineLimit(1)
            }
            Spacer()
        }
    }

    private var inlineView: some View {
        Text("▶ \(entry.routineName)")
    }

    private var cornerView: some View {
        ZStack {
            AccessoryWidgetBackground()
            Image(systemName: "play.fill")
        }
    }
}

// MARK: - Widgets

@main
struct IntervalWatchWidgets: WidgetBundle {
    var body: some Widget {
        TimerStatusWidget()
        RoutineQuickStartWidget()
    }
}

struct TimerStatusWidget: Widget {
    let kind: String = "TimerStatusWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TimerWidgetProvider()) { entry in
            TimerWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Timer Status")
        .description("Shows the current timer status")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline, .accessoryCorner])
    }
}

struct RoutineQuickStartWidget: Widget {
    let kind: String = "RoutineQuickStartWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RoutineWidgetProvider()) { entry in
            RoutineWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Routine Shortcut")
        .description("Tap to start a routine")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline, .accessoryCorner])
    }
}

#Preview(as: .accessoryRectangular) {
    TimerStatusWidget()
} timeline: {
    TimerWidgetEntry(date: Date(), isRunning: true, intervalName: "Workout", timeRemaining: 25, currentRound: 2, totalRounds: 4)
    TimerWidgetEntry(date: Date(), isRunning: false, intervalName: "", timeRemaining: 0, currentRound: 1, totalRounds: 1)
}
