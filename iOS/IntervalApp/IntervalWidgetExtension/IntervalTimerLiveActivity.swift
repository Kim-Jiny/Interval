//
//  IntervalTimerLiveActivity.swift
//  IntervalWidgetExtension
//
//  Created by 김미진 on 1/15/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct IntervalTimerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimerActivityAttributes.self) { context in
            // Lock Screen / Banner UI
            LockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI
                DynamicIslandExpandedRegion(.leading) {
                    HStack {
                        Circle()
                            .fill(colorForType(context.state.intervalType))
                            .frame(width: 12, height: 12)
                        Text(context.state.currentIntervalName)
                            .font(.headline)
                            .foregroundStyle(.white)
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    Text("R\(context.state.currentRound)/\(context.state.totalRounds)")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                }

                DynamicIslandExpandedRegion(.center) {
                    Text(formatTime(context.state.timeRemaining))
                        .font(.system(size: 36, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 8) {
                        ProgressView(value: context.state.progress)
                            .tint(colorForType(context.state.intervalType))

                        Text(context.attributes.routineName)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
            } compactLeading: {
                Circle()
                    .fill(colorForType(context.state.intervalType))
                    .frame(width: 12, height: 12)
            } compactTrailing: {
                Text(formatTimeCompact(context.state.timeRemaining))
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .foregroundStyle(colorForType(context.state.intervalType))
            } minimal: {
                Circle()
                    .fill(colorForType(context.state.intervalType))
                    .frame(width: 12, height: 12)
            }
        }
    }

    private func colorForType(_ type: String) -> Color {
        switch type {
        case "workout": return .red
        case "rest": return .green
        case "warmup": return .orange
        case "cooldown": return .blue
        default: return .gray
        }
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private func formatTimeCompact(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        if minutes > 0 {
            return String(format: "%d:%02d", minutes, seconds)
        } else {
            return String(format: ":%02d", seconds)
        }
    }
}

struct LockScreenView: View {
    let context: ActivityViewContext<TimerActivityAttributes>

    var body: some View {
        HStack(spacing: 16) {
            // Left: Interval info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Circle()
                        .fill(colorForType(context.state.intervalType))
                        .frame(width: 10, height: 10)
                    Text(context.state.currentIntervalName)
                        .font(.headline)
                        .foregroundStyle(.white)
                }

                Text(context.attributes.routineName)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }

            Spacer()

            // Right: Timer
            VStack(alignment: .trailing, spacing: 4) {
                Text(formatTime(context.state.timeRemaining))
                    .font(.system(size: 32, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)

                Text("Round \(context.state.currentRound)/\(context.state.totalRounds)")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .padding()
        .background(colorForType(context.state.intervalType).opacity(0.8))
    }

    private func colorForType(_ type: String) -> Color {
        switch type {
        case "workout": return .red
        case "rest": return .green
        case "warmup": return .orange
        case "cooldown": return .blue
        default: return .gray
        }
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
