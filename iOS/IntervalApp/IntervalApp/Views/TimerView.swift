//
//  TimerView.swift
//  IntervalApp
//
//  Created by 김미진 on 1/14/26.
//

import SwiftUI
import AVFoundation
import ActivityKit

struct TimerView: View {
    let routine: Routine
    @Environment(\.dismiss) private var dismiss
    @StateObject private var timerManager: TimerManager
    @State private var showingExitConfirmation = false

    init(routine: Routine) {
        self.routine = routine
        _timerManager = StateObject(wrappedValue: TimerManager(routine: routine))
    }

    var body: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()

            VStack(spacing: 0) {
                headerView

                // 전체 진행 상황
                overallProgressView
                    .padding(.top, 16)

                Spacer()

                timerDisplay

                Spacer()

                // 구간 인디케이터
                intervalIndicator
                    .padding(.vertical, 16)

                intervalInfo

                Spacer()

                controlButtons
            }
            .padding()
        }
        .alert(String(localized: "End Workout"), isPresented: $showingExitConfirmation) {
            Button(String(localized: "No"), role: .cancel) { }
            Button(String(localized: "Yes"), role: .destructive) {
                timerManager.stop()
                dismiss()
            }
        } message: {
            Text("Do you want to end this workout?")
        }
        .onDisappear {
            timerManager.stop()
        }
    }

    private var backgroundColor: Color {
        switch timerManager.currentInterval?.type {
        case .workout:
            return .red.opacity(0.8)
        case .rest:
            return .green.opacity(0.8)
        case .warmup:
            return .orange.opacity(0.8)
        case .cooldown:
            return .blue.opacity(0.8)
        case .none:
            return .gray.opacity(0.8)
        }
    }

    private var headerView: some View {
        HStack {
            Button {
                showingExitConfirmation = true
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .foregroundStyle(.white.opacity(0.8))
            }

            Spacer()

            VStack(alignment: .trailing) {
                Text(routine.name)
                    .font(.headline)
                Text("Round \(timerManager.currentRound)/\(routine.rounds)")
                    .font(.subheadline)
            }
            .foregroundStyle(.white)

            // Live Activity 버튼
            if !timerManager.isCompleted {
                Button {
                    timerManager.restartLiveActivity()
                } label: {
                    Image(systemName: timerManager.isLiveActivityActive ? "bell.fill" : "bell.slash.fill")
                        .font(.title2)
                        .foregroundStyle(.white.opacity(0.8))
                }
                .padding(.leading, 12)
            }
        }
    }

    // 전체 진행률 표시
    private var overallProgressView: some View {
        VStack(spacing: 8) {
            // 전체 진행률 바
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.white.opacity(0.2))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(.white.opacity(0.8))
                        .frame(width: geometry.size.width * timerManager.overallProgress, height: 8)
                }
            }
            .frame(height: 8)

            // 진행 정보
            HStack {
                // 현재 구간 / 전체 구간
                Text("Interval \(timerManager.currentIntervalIndex + 1)/\(routine.intervals.count)")
                    .font(.caption)

                Spacer()

                // 남은 총 시간
                Text("\(timerManager.formattedRemainingTotalTime) left")
                    .font(.caption)
            }
            .foregroundStyle(.white.opacity(0.8))
        }
    }

    // 구간 인디케이터 (점으로 표시)
    private var intervalIndicator: some View {
        GeometryReader { geometry in
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(routine.intervals.enumerated()), id: \.offset) { index, interval in
                            VStack(spacing: 4) {
                                // 구간 점
                                Circle()
                                    .fill(indicatorColor(for: index, interval: interval))
                                    .frame(width: index == timerManager.currentIntervalIndex ? 16 : 10,
                                           height: index == timerManager.currentIntervalIndex ? 16 : 10)
                                    .overlay {
                                        if index == timerManager.currentIntervalIndex {
                                            Circle()
                                                .stroke(.white, lineWidth: 2)
                                        }
                                    }
                                    .animation(.easeInOut(duration: 0.2), value: timerManager.currentIntervalIndex)

                                // 현재 구간이면 이름 표시
                                if index == timerManager.currentIntervalIndex {
                                    Text(interval.name)
                                        .font(.caption2)
                                        .foregroundStyle(.white)
                                        .lineLimit(1)
                                }
                            }
                            .id(index)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .frame(minWidth: geometry.size.width)
                }
                .onChange(of: timerManager.currentIntervalIndex) { _, newIndex in
                    withAnimation {
                        proxy.scrollTo(newIndex, anchor: .center)
                    }
                }
            }
        }
        .frame(height: 60)
    }

    private func indicatorColor(for index: Int, interval: WorkoutInterval) -> Color {
        if index < timerManager.currentIntervalIndex ||
           (index == 0 && timerManager.currentRound > 1) {
            // 완료된 구간
            return .white.opacity(0.5)
        } else if index == timerManager.currentIntervalIndex {
            // 현재 구간
            return .white
        } else {
            // 미완료 구간 - 타입에 따른 색상
            switch interval.type {
            case .workout: return .red.opacity(0.6)
            case .rest: return .green.opacity(0.6)
            case .warmup: return .orange.opacity(0.6)
            case .cooldown: return .blue.opacity(0.6)
            }
        }
    }

    private var timerDisplay: some View {
        VStack(spacing: 16) {
            Text(timerManager.currentInterval?.name ?? String(localized: "Done"))
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(.white)

            Text(timerManager.formattedTimeRemaining)
                .font(.system(size: 100, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.5)

            // 현재 구간 진행률
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.white.opacity(0.3))
                        .frame(height: 12)

                    RoundedRectangle(cornerRadius: 8)
                        .fill(.white)
                        .frame(width: geometry.size.width * timerManager.progress, height: 12)
                }
            }
            .frame(height: 12)
        }
    }

    private var intervalInfo: some View {
        VStack(spacing: 8) {
            if let nextInterval = timerManager.nextInterval {
                Text("Next")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
                Text("\(nextInterval.name) - \(nextInterval.formattedDuration)")
                    .font(.title3)
                    .foregroundStyle(.white)
            } else if timerManager.isCompleted {
                Text("Completed!")
                    .font(.title)
                    .foregroundStyle(.white)
            }
        }
    }

    private var controlButtons: some View {
        HStack(spacing: 40) {
            Button {
                timerManager.previousInterval()
            } label: {
                Image(systemName: "backward.fill")
                    .font(.title)
                    .foregroundStyle(.white)
                    .frame(width: 60, height: 60)
            }
            .disabled(timerManager.currentIntervalIndex == 0 && timerManager.currentRound == 1)

            Button {
                if timerManager.isRunning {
                    timerManager.pause()
                } else {
                    timerManager.start()
                }
            } label: {
                Image(systemName: timerManager.isRunning ? "pause.fill" : "play.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(.white)
                    .frame(width: 100, height: 100)
                    .background(.white.opacity(0.2))
                    .clipShape(Circle())
            }

            Button {
                timerManager.nextIntervalAction()
            } label: {
                Image(systemName: "forward.fill")
                    .font(.title)
                    .foregroundStyle(.white)
                    .frame(width: 60, height: 60)
            }
            .disabled(timerManager.isCompleted)
        }
    }
}

class TimerManager: ObservableObject {
    private let routine: Routine
    private var timer: Timer?
    private var audioPlayer: AVAudioPlayer?
    private var liveActivity: Activity<TimerActivityAttributes>?

    // 설정값 (UserDefaults에서 읽기)
    private var vibrationEnabled: Bool {
        UserDefaults.standard.object(forKey: "vibrationEnabled") as? Bool ?? true
    }
    private var soundEnabled: Bool {
        UserDefaults.standard.object(forKey: "soundEnabled") as? Bool ?? true
    }

    @Published var currentRound: Int = 1
    @Published var currentIntervalIndex: Int = 0
    @Published var timeRemaining: TimeInterval = 0
    @Published var isRunning: Bool = false
    @Published var isCompleted: Bool = false
    @Published var isLiveActivityActive: Bool = false

    var currentInterval: WorkoutInterval? {
        guard currentIntervalIndex < routine.intervals.count else { return nil }
        return routine.intervals[currentIntervalIndex]
    }

    var nextInterval: WorkoutInterval? {
        let nextIndex = currentIntervalIndex + 1
        if nextIndex < routine.intervals.count {
            return routine.intervals[nextIndex]
        } else if currentRound < routine.rounds {
            return routine.intervals.first
        }
        return nil
    }

    // 현재 구간 진행률
    var progress: Double {
        guard let current = currentInterval else { return 0 }
        return 1 - (timeRemaining / current.duration)
    }

    // 전체 루틴 진행률
    var overallProgress: Double {
        let totalDuration = routine.totalDuration
        guard totalDuration > 0 else { return 0 }

        let completedTime = elapsedTotalTime
        return min(completedTime / totalDuration, 1.0)
    }

    // 경과된 총 시간
    var elapsedTotalTime: TimeInterval {
        // 완료된 라운드의 시간
        let completedRoundsTime = Double(currentRound - 1) * routine.intervals.reduce(0) { $0 + $1.duration }

        // 현재 라운드에서 완료된 구간들의 시간
        var currentRoundCompletedTime: TimeInterval = 0
        for i in 0..<currentIntervalIndex {
            currentRoundCompletedTime += routine.intervals[i].duration
        }

        // 현재 구간에서 경과된 시간
        let currentIntervalElapsed = (currentInterval?.duration ?? 0) - timeRemaining

        return completedRoundsTime + currentRoundCompletedTime + currentIntervalElapsed
    }

    // 남은 총 시간
    var remainingTotalTime: TimeInterval {
        return max(0, routine.totalDuration - elapsedTotalTime)
    }

    // 포맷된 남은 총 시간
    var formattedRemainingTotalTime: String {
        let total = Int(remainingTotalTime)
        let minutes = total / 60
        let seconds = total % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var formattedTimeRemaining: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    init(routine: Routine) {
        self.routine = routine
        if let first = routine.intervals.first {
            self.timeRemaining = first.duration
        }
        setupAudioSession()
    }

    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }

    func start() {
        guard !isCompleted else { return }
        isRunning = true

        if liveActivity == nil {
            startLiveActivity()
        }

        // Watch에 타이머 시작 알림
        if let interval = currentInterval {
            PhoneConnectivityManager.shared.sendTimerStarted(
                routine: routine,
                intervalName: interval.name,
                timeRemaining: timeRemaining,
                currentRound: currentRound,
                intervalType: interval.type.rawValue
            )
        }

        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    func pause() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }

    func stop() {
        pause()
        endLiveActivity()

        // Watch에 타이머 중지 알림
        PhoneConnectivityManager.shared.sendTimerStopped()

        currentRound = 1
        currentIntervalIndex = 0
        if let first = routine.intervals.first {
            timeRemaining = first.duration
        }
        isCompleted = false
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

    private var lastLiveActivityUpdate: TimeInterval = 0

    private func tick() {
        timeRemaining -= 0.1

        // Update Live Activity every second
        let currentSecond = floor(timeRemaining)
        if currentSecond != lastLiveActivityUpdate {
            lastLiveActivityUpdate = currentSecond
            updateLiveActivity()

            // Watch에 매초 시간 업데이트
            PhoneConnectivityManager.shared.sendTimerUpdate(timeRemaining: timeRemaining)
        }

        // 카운트다운 (3, 2, 1) - Watch에도 알림
        if timeRemaining <= 3 && timeRemaining > 2.9 {
            playCountdownSound()
            PhoneConnectivityManager.shared.sendCountdown(timeRemaining: timeRemaining)
        } else if timeRemaining <= 2 && timeRemaining > 1.9 {
            PhoneConnectivityManager.shared.sendCountdown(timeRemaining: timeRemaining)
        } else if timeRemaining <= 1 && timeRemaining > 0.9 {
            PhoneConnectivityManager.shared.sendCountdown(timeRemaining: timeRemaining)
        }

        if timeRemaining <= 0 {
            playIntervalEndSound()
            moveToNextInterval()
        }
    }

    private func moveToNextInterval() {
        let nextIndex = currentIntervalIndex + 1

        if nextIndex < routine.intervals.count {
            currentIntervalIndex = nextIndex
            timeRemaining = routine.intervals[nextIndex].duration
            updateLiveActivity()

            // Watch에 구간 변경 알림
            if let interval = currentInterval {
                PhoneConnectivityManager.shared.sendIntervalChange(
                    intervalName: interval.name,
                    timeRemaining: timeRemaining,
                    currentRound: currentRound,
                    totalRounds: routine.rounds,
                    intervalType: interval.type.rawValue
                )
            }
        } else if currentRound < routine.rounds {
            currentRound += 1
            currentIntervalIndex = 0
            timeRemaining = routine.intervals[0].duration
            updateLiveActivity()

            // Watch에 라운드 변경 알림
            if let interval = currentInterval {
                PhoneConnectivityManager.shared.sendIntervalChange(
                    intervalName: interval.name,
                    timeRemaining: timeRemaining,
                    currentRound: currentRound,
                    totalRounds: routine.rounds,
                    intervalType: interval.type.rawValue
                )
            }
        } else {
            isRunning = false
            isCompleted = true
            timer?.invalidate()
            timer = nil
            endLiveActivity()
            playCompletionSound()

            // Watch에 완료 알림
            PhoneConnectivityManager.shared.sendTimerCompleted()
        }
    }

    private func playCountdownSound() {
        if soundEnabled {
            AudioServicesPlaySystemSound(1057)
        }
        if vibrationEnabled {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }
    }

    private func playIntervalEndSound() {
        if soundEnabled {
            AudioServicesPlaySystemSound(1013)
        }
        if vibrationEnabled {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
        }
    }

    private func playCompletionSound() {
        if soundEnabled {
            AudioServicesPlaySystemSound(1025)
        }
        if vibrationEnabled {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
    }

    // MARK: - Live Activity

    func restartLiveActivity() {
        // 기존 활동 종료
        if let activity = liveActivity {
            Task {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
        liveActivity = nil
        isLiveActivityActive = false

        // 새로운 활동 시작
        startLiveActivity()
    }

    private func startLiveActivity() {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("Live Activities are not enabled")
            return
        }

        let attributes = TimerActivityAttributes(
            routineName: routine.name,
            totalIntervals: routine.intervals.count
        )

        let contentState = createContentState()

        do {
            liveActivity = try Activity.request(
                attributes: attributes,
                content: .init(state: contentState, staleDate: nil),
                pushType: nil
            )
            isLiveActivityActive = true
        } catch {
            print("Failed to start Live Activity: \(error)")
            isLiveActivityActive = false
        }
    }

    private func updateLiveActivity() {
        guard let activity = liveActivity else {
            isLiveActivityActive = false
            return
        }

        // 활동이 종료되었는지 확인
        if activity.activityState == .dismissed || activity.activityState == .ended {
            isLiveActivityActive = false
            liveActivity = nil
            return
        }

        let contentState = createContentState()

        Task {
            await activity.update(.init(state: contentState, staleDate: nil))
        }
    }

    private func endLiveActivity() {
        guard let activity = liveActivity else { return }

        Task {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
        liveActivity = nil
        isLiveActivityActive = false
    }

    private func createContentState() -> TimerActivityAttributes.ContentState {
        TimerActivityAttributes.ContentState(
            currentIntervalName: currentInterval?.name ?? "Done",
            timeRemaining: timeRemaining,
            intervalType: currentInterval?.type.rawValue ?? "workout",
            currentRound: currentRound,
            totalRounds: routine.rounds,
            progress: progress
        )
    }
}

#Preview {
    TimerView(routine: Routine.sample)
}
