//
//  WatchContentView.swift
//  IntervalApp Watch App
//
//  Created by Claude on 1/15/26.
//

import SwiftUI

struct WatchContentView: View {
    @EnvironmentObject var connectivityManager: WatchConnectivityManager
    @EnvironmentObject var routineStore: WatchRoutineStore
    @State private var selectedRoutine: WatchRoutine?

    var body: some View {
        NavigationStack {
            Group {
                if routineStore.routines.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "iphone.and.arrow.forward")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("Sync routines\nfrom iPhone")
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    List {
                        // iPhone에서 타이머 실행 중이면 상단에 표시
                        if connectivityManager.isReceivingFromiPhone,
                           let activeRoutine = connectivityManager.activeRoutine {
                            Button {
                                selectedRoutine = activeRoutine
                            } label: {
                                ActiveTimerRow(connectivityManager: connectivityManager)
                            }
                            .listRowBackground(timerRowBackground)
                        }

                        // 루틴 목록
                        ForEach(routineStore.routines) { routine in
                            Button {
                                // Watch에서 직접 시작 시 항상 독립 모드로 전환
                                connectivityManager.startStandaloneMode()
                                selectedRoutine = routine
                            } label: {
                                WatchRoutineRow(routine: routine)
                            }
                            // iPhone 연동 중이면 다른 루틴 비활성화
                            .disabled(connectivityManager.isReceivingFromiPhone)
                            .opacity(connectivityManager.isReceivingFromiPhone ? 0.5 : 1.0)
                        }
                    }
                }
            }
            .navigationTitle("Interval")
            .fullScreenCover(item: $selectedRoutine) { routine in
                WatchTimerView(routine: routine)
                    .environmentObject(connectivityManager)
            }
        }
        // iPhone에서 타이머 시작 메시지 받으면 자동으로 타이머 화면 표시
        .onChange(of: connectivityManager.activeRoutine) { _, newRoutine in
            if let routine = newRoutine {
                selectedRoutine = routine
            }
        }
        // 백그라운드에서 타이머 시작 알림 받은 후 앱 열릴 때 자동 이동
        .onChange(of: connectivityManager.pendingTimerStart) { _, isPending in
            if isPending, let routine = connectivityManager.activeRoutine {
                selectedRoutine = routine
                connectivityManager.clearPendingTimerStart()
            }
        }
        .onAppear {
            // 앱이 열릴 때 대기 중인 타이머가 있으면 바로 이동
            if connectivityManager.pendingTimerStart, let routine = connectivityManager.activeRoutine {
                selectedRoutine = routine
                connectivityManager.clearPendingTimerStart()
            }
        }
    }

    // 타이머 행 배경색
    private var timerRowBackground: Color {
        switch connectivityManager.intervalType {
        case "workout": return .red.opacity(0.6)
        case "rest": return .green.opacity(0.6)
        case "warmup": return .orange.opacity(0.6)
        case "cooldown": return .blue.opacity(0.6)
        default: return .gray.opacity(0.6)
        }
    }
}

// MARK: - 실행 중인 타이머 셀
struct ActiveTimerRow: View {
    @ObservedObject var connectivityManager: WatchConnectivityManager

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: "iphone")
                        .font(.caption2)
                    Text(connectivityManager.currentIntervalName)
                        .font(.caption)
                        .fontWeight(.semibold)
                }

                Text("R\(connectivityManager.currentRound)/\(connectivityManager.totalRounds)")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.8))
            }

            Spacer()

            Text(formatTime(connectivityManager.timeRemaining))
                .font(.system(size: 20, weight: .bold, design: .monospaced))
        }
        .foregroundStyle(.white)
        .padding(.vertical, 4)
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct WatchRoutineRow: View {
    let routine: WatchRoutine

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(routine.name)
                .font(.headline)
                .lineLimit(1)

            HStack {
                Label("\(routine.intervals.count)", systemImage: "list.bullet")
                Label("\(routine.rounds)R", systemImage: "repeat")
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    WatchContentView()
        .environmentObject(WatchConnectivityManager.shared)
        .environmentObject(WatchRoutineStore())
}
