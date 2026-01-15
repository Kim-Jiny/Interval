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
                    List(routineStore.routines) { routine in
                        Button {
                            // Watch에서 직접 시작 시 항상 독립 모드로 전환
                            connectivityManager.startStandaloneMode()
                            selectedRoutine = routine
                        } label: {
                            WatchRoutineRow(routine: routine)
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
