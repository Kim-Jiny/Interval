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
                    // 자동 카운트다운 타이머
                    Text(timerInterval: Date()...context.state.endTime, countsDown: true)
                        .font(.system(size: 36, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.attributes.routineName)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
            } compactLeading: {
                Circle()
                    .fill(colorForType(context.state.intervalType))
                    .frame(width: 12, height: 12)
            } compactTrailing: {
                // 자동 카운트다운 타이머
                Text(timerInterval: Date()...context.state.endTime, countsDown: true)
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .foregroundStyle(colorForType(context.state.intervalType))
                    .frame(minWidth: 50)
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
                // 자동 카운트다운 타이머
                Text(timerInterval: Date()...context.state.endTime, countsDown: true)
                    .font(.system(size: 32, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.trailing)

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
}
