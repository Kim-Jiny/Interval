//
//  WatchTimerView.swift
//  IntervalApp Watch App
//
//  Created by Claude on 1/15/26.
//

import SwiftUI
import WatchKit
import WidgetKit

struct WatchTimerView: View {
    let routine: WatchRoutine
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var connectivityManager: WatchConnectivityManager
    @StateObject private var timerManager: WatchTimerManager

    init(routine: WatchRoutine) {
        self.routine = routine
        _timerManager = StateObject(wrappedValue: WatchTimerManager(routine: routine))
    }

    var body: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()

            VStack(spacing: 8) {
                // iPhone에서 운동 완료
                if connectivityManager.isWorkoutCompletedFromiPhone {
                    completedView
                }
                // iPhone 연동 모드 표시
                else if connectivityManager.isReceivingFromiPhone {
                    iPhoneModeView
                }
                // Watch 독립 모드 - 완료
                else if timerManager.isCompleted {
                    completedView
                }
                // Watch 독립 모드
                else {
                    standaloneModeView
                }
            }
            .padding(.horizontal, 8)
        }
        .onAppear {
            // iPhone에서 제어 중이 아니면 타이머 시작
            if !connectivityManager.isReceivingFromiPhone {
                timerManager.start()
            }
        }
        .onDisappear {
            timerManager.stop()
            connectivityManager.resetCompletedState()
        }
        .onChange(of: connectivityManager.isReceivingFromiPhone) { _, isReceiving in
            if isReceiving {
                // iPhone에서 제어 시작 - 로컬 타이머 중지
                timerManager.pause()
            }
        }
        .onChange(of: connectivityManager.shouldDismissTimer) { _, shouldDismiss in
            if shouldDismiss {
                // iPhone에서 운동 종료 시 Watch 화면 닫기
                connectivityManager.resetCompletedState()
                dismiss()
            }
        }
    }

    // 운동 완료 화면
    private var completedView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 50))
                .foregroundStyle(.white)

            Text("Workout Complete!")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.white)

            Text(routine.name)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.8))

            Button {
                connectivityManager.resetCompletedState()
                dismiss()
            } label: {
                Text("OK")
                    .font(.headline)
            }
            .buttonStyle(.bordered)
            .tint(.white)
        }
    }

    // iPhone 연동 모드 UI
    private var iPhoneModeView: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "iphone")
                    .font(.caption2)
                Text("iPhone Sync")
                    .font(.caption2)
            }
            .foregroundStyle(.white.opacity(0.7))

            Text(connectivityManager.currentIntervalName)
                .font(.headline)
                .foregroundStyle(.white)

            Text(formatTime(connectivityManager.timeRemaining))
                .font(.system(size: 48, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.5)

            Text("Round \(connectivityManager.currentRound)/\(connectivityManager.totalRounds)")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.8))

            Button {
                dismiss()
            } label: {
                Text("Close")
                    .font(.caption)
            }
            .buttonStyle(.bordered)
            .tint(.white.opacity(0.3))
        }
    }

    // Watch 독립 모드 UI
    private var standaloneModeView: some View {
        VStack(spacing: 6) {
            // 헤더
            HStack {
                Text("R\(timerManager.currentRound)/\(routine.rounds)")
                    .font(.caption2)
                Spacer()
                Button {
                    timerManager.stop()
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                }
                .buttonStyle(.plain)
            }
            .foregroundStyle(.white.opacity(0.8))

            Spacer()

            // 현재 구간
            Text(timerManager.currentInterval?.name ?? String(localized: "Complete"))
                .font(.headline)
                .foregroundStyle(.white)
                .lineLimit(1)

            // 타이머
            Text(timerManager.formattedTimeRemaining)
                .font(.system(size: 52, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.5)

            // 진행률 바
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.white.opacity(0.3))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(.white)
                        .frame(width: geometry.size.width * timerManager.progress, height: 6)
                }
            }
            .frame(height: 6)

            Spacer()

            // 다음 구간
            if let next = timerManager.nextInterval {
                Text("Next: \(next.name)")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.7))
            } else if timerManager.isCompleted {
                Text("Complete!")
                    .font(.headline)
                    .foregroundStyle(.white)
            }

            // 컨트롤 버튼
            HStack(spacing: 20) {
                Button {
                    timerManager.previousInterval()
                } label: {
                    Image(systemName: "backward.fill")
                        .font(.title3)
                }
                .buttonStyle(.plain)
                .disabled(timerManager.currentIntervalIndex == 0 && timerManager.currentRound == 1)

                Button {
                    if timerManager.isRunning {
                        timerManager.pause()
                    } else {
                        timerManager.start()
                    }
                } label: {
                    Image(systemName: timerManager.isRunning ? "pause.fill" : "play.fill")
                        .font(.title2)
                        .frame(width: 44, height: 44)
                        .background(.white.opacity(0.2))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                Button {
                    timerManager.nextIntervalAction()
                } label: {
                    Image(systemName: "forward.fill")
                        .font(.title3)
                }
                .buttonStyle(.plain)
                .disabled(timerManager.isCompleted)
            }
            .foregroundStyle(.white)
        }
    }

    private var backgroundColor: Color {
        let type = connectivityManager.isReceivingFromiPhone
            ? connectivityManager.intervalType
            : (timerManager.currentInterval?.type.rawValue ?? "workout")

        switch type {
        case "workout": return .red.opacity(0.8)
        case "rest": return .green.opacity(0.8)
        case "warmup": return .orange.opacity(0.8)
        case "cooldown": return .blue.opacity(0.8)
        default: return .gray.opacity(0.8)
        }
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Watch Timer Manager

class WatchTimerManager: NSObject, ObservableObject, WKExtendedRuntimeSessionDelegate {
    private let routine: WatchRoutine
    private var timer: Timer?
    private var extendedSession: WKExtendedRuntimeSession?

    @Published var currentRound: Int = 1
    @Published var currentIntervalIndex: Int = 0
    @Published var timeRemaining: TimeInterval = 0
    @Published var isRunning: Bool = false
    @Published var isCompleted: Bool = false

    var currentInterval: WatchInterval? {
        guard currentIntervalIndex < routine.intervals.count else { return nil }
        return routine.intervals[currentIntervalIndex]
    }

    var nextInterval: WatchInterval? {
        let nextIndex = currentIntervalIndex + 1
        if nextIndex < routine.intervals.count {
            return routine.intervals[nextIndex]
        } else if currentRound < routine.rounds {
            return routine.intervals.first
        }
        return nil
    }

    var progress: Double {
        guard let current = currentInterval else { return 0 }
        return 1 - (timeRemaining / current.duration)
    }

    var formattedTimeRemaining: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    init(routine: WatchRoutine) {
        self.routine = routine
        super.init()
        if let first = routine.intervals.first {
            self.timeRemaining = first.duration
        }
    }

    func start() {
        guard !isCompleted else { return }
        isRunning = true

        // Extended Runtime Session 시작 (화면 꺼져도 계속 실행)
        startExtendedSession()

        // 위젯 업데이트
        updateWidget()

        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    func pause() {
        isRunning = false
        timer?.invalidate()
        timer = nil
        updateWidget()
    }

    func stop() {
        pause()
        stopExtendedSession()
        currentRound = 1
        currentIntervalIndex = 0
        if let first = routine.intervals.first {
            timeRemaining = first.duration
        }
        isCompleted = false
        clearWidget()
    }

    // MARK: - Widget Update

    private func updateWidget() {
        let defaults = UserDefaults.standard
        defaults.set(isRunning, forKey: "widgetTimerRunning")
        defaults.set(currentInterval?.name ?? "", forKey: "widgetIntervalName")
        defaults.set(timeRemaining, forKey: "widgetTimeRemaining")
        defaults.set(currentRound, forKey: "widgetCurrentRound")
        defaults.set(routine.rounds, forKey: "widgetTotalRounds")

        WidgetCenter.shared.reloadAllTimelines()
    }

    private func clearWidget() {
        let defaults = UserDefaults.standard
        defaults.set(false, forKey: "widgetTimerRunning")
        defaults.removeObject(forKey: "widgetIntervalName")
        defaults.removeObject(forKey: "widgetTimeRemaining")
        defaults.removeObject(forKey: "widgetCurrentRound")
        defaults.removeObject(forKey: "widgetTotalRounds")

        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Extended Runtime Session

    private func startExtendedSession() {
        guard extendedSession == nil else { return }
        extendedSession = WKExtendedRuntimeSession()
        extendedSession?.delegate = self
        extendedSession?.start()
    }

    private func stopExtendedSession() {
        extendedSession?.invalidate()
        extendedSession = nil
    }

    func extendedRuntimeSessionDidStart(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
        print("Extended session started")
    }

    func extendedRuntimeSessionWillExpire(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
        print("Extended session will expire")
    }

    func extendedRuntimeSession(_ extendedRuntimeSession: WKExtendedRuntimeSession, didInvalidateWith reason: WKExtendedRuntimeSessionInvalidationReason, error: Error?) {
        print("Extended session invalidated: \(reason)")
        extendedSession = nil
    }

    func nextIntervalAction() {
        moveToNextInterval()
    }

    func previousInterval() {
        if currentIntervalIndex > 0 {
            currentIntervalIndex -= 1
        } else if currentRound > 1 {
            currentRound -= 1
            currentIntervalIndex = routine.intervals.count - 1
        }

        if let interval = currentInterval {
            timeRemaining = interval.duration
        }
    }

    private func tick() {
        timeRemaining -= 0.1

        // 카운트다운 햅틱 (3, 2, 1)
        if timeRemaining <= 3 && timeRemaining > 2.9 {
            WKInterfaceDevice.current().play(.click)
        } else if timeRemaining <= 2 && timeRemaining > 1.9 {
            WKInterfaceDevice.current().play(.click)
        } else if timeRemaining <= 1 && timeRemaining > 0.9 {
            WKInterfaceDevice.current().play(.click)
        }

        if timeRemaining <= 0 {
            moveToNextInterval()
        }
    }

    private func moveToNextInterval() {
        let nextIndex = currentIntervalIndex + 1

        if nextIndex < routine.intervals.count {
            currentIntervalIndex = nextIndex
            timeRemaining = routine.intervals[nextIndex].duration
            // 구간 변경 햅틱
            WKInterfaceDevice.current().play(.notification)
            updateWidget()
        } else if currentRound < routine.rounds {
            currentRound += 1
            currentIntervalIndex = 0
            timeRemaining = routine.intervals[0].duration
            // 라운드 변경 햅틱
            WKInterfaceDevice.current().play(.notification)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                WKInterfaceDevice.current().play(.click)
            }
            updateWidget()
        } else {
            isRunning = false
            isCompleted = true
            timer?.invalidate()
            timer = nil
            stopExtendedSession()
            clearWidget()
            // 완료 햅틱
            WKInterfaceDevice.current().play(.success)
        }
    }
}

#Preview {
    let sampleRoutine = WatchRoutine(
        id: UUID(),
        name: "Sample",
        intervals: [
            WatchInterval(id: UUID(), name: String(localized: "Workout"), duration: 30, type: .workout),
            WatchInterval(id: UUID(), name: String(localized: "Rest"), duration: 10, type: .rest)
        ],
        rounds: 3
    )
    return WatchTimerView(routine: sampleRoutine)
        .environmentObject(WatchConnectivityManager.shared)
}
