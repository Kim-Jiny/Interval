//
//  WatchConnectivityManager.swift
//  IntervalApp Watch App
//
//  Created by Claude on 1/15/26.
//

import Foundation
import WatchConnectivity
import WatchKit
import UserNotifications

class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()

    @Published var activeRoutine: WatchRoutine?
    @Published var isReceivingFromiPhone = false
    @Published var currentIntervalName: String = ""
    @Published var timeRemaining: TimeInterval = 0
    @Published var currentRound: Int = 1
    @Published var totalRounds: Int = 1
    @Published var intervalType: String = "workout"

    // iPhone에서 종료/완료 시 Watch UI 제어
    @Published var shouldDismissTimer = false
    @Published var isWorkoutCompletedFromiPhone = false

    // 백그라운드에서 타이머 시작 알림 수신 시
    @Published var pendingTimerStart = false

    private var session: WCSession?

    override init() {
        super.init()
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }

        // 알림 권한 요청
        requestNotificationPermission()
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Watch notification permission granted")
            } else if let error = error {
                print("Watch notification permission error: \(error)")
            }
        }
    }

    // Watch에서 햅틱 피드백 실행
    func playHaptic(type: WKHapticType = .notification) {
        WKInterfaceDevice.current().play(type)
    }

    // 강한 햅틱 (구간 변경 시)
    func playIntervalChangeHaptic() {
        // 여러 번 진동으로 강조
        WKInterfaceDevice.current().play(.notification)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            WKInterfaceDevice.current().play(.click)
        }
    }

    // 카운트다운 햅틱 (3, 2, 1)
    func playCountdownHaptic() {
        WKInterfaceDevice.current().play(.click)
    }

    // 완료 햅틱
    func playCompletionHaptic() {
        WKInterfaceDevice.current().play(.success)
    }

    // iPhone에 메시지 전송
    func sendMessage(_ message: [String: Any]) {
        guard let session = session, session.isReachable else { return }
        session.sendMessage(message, replyHandler: nil) { error in
            print("Failed to send message: \(error.localizedDescription)")
        }
    }

    // Watch에서 직접 루틴 시작 시 iPhone 연동 모드 해제
    func startStandaloneMode() {
        isReceivingFromiPhone = false
        activeRoutine = nil
        shouldDismissTimer = false
        isWorkoutCompletedFromiPhone = false
    }

    // 완료 화면에서 닫을 때 상태 리셋
    func resetCompletedState() {
        isReceivingFromiPhone = false
        isWorkoutCompletedFromiPhone = false
        shouldDismissTimer = false
        activeRoutine = nil
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("WCSession activation failed: \(error.localizedDescription)")
        } else {
            print("WCSession activated on Watch: \(activationState.rawValue)")

            // 이미 받은 applicationContext 확인
            let context = session.receivedApplicationContext
            if !context.isEmpty {
                DispatchQueue.main.async { [weak self] in
                    self?.handleApplicationContext(context)
                }
            }
        }
    }

    // iPhone에서 메시지 수신
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async { [weak self] in
            self?.handleMessage(message)
        }
    }

    // iPhone에서 앱 컨텍스트 수신 (루틴 동기화)
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        DispatchQueue.main.async { [weak self] in
            self?.handleApplicationContext(applicationContext)
        }
    }

    // iPhone에서 UserInfo 수신 (백그라운드에서도 동작)
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        DispatchQueue.main.async { [weak self] in
            // 타이머 이벤트인지 확인
            if let action = userInfo["action"] as? String {
                self?.handleTimerUserInfo(userInfo, action: action)
            } else {
                // 루틴 동기화 데이터
                self?.handleApplicationContext(userInfo)
            }
        }
    }

    private func handleMessage(_ message: [String: Any]) {
        guard let action = message["action"] as? String else { return }

        switch action {
        case "intervalChange":
            // 구간 변경 - 강한 햅틱
            playIntervalChangeHaptic()

            if let name = message["intervalName"] as? String {
                currentIntervalName = name
            }
            if let time = message["timeRemaining"] as? TimeInterval {
                timeRemaining = time
            }
            if let round = message["currentRound"] as? Int {
                currentRound = round
            }
            if let total = message["totalRounds"] as? Int {
                totalRounds = total
            }
            if let type = message["intervalType"] as? String {
                intervalType = type
            }

        case "countdown":
            // 카운트다운 (3, 2, 1)
            playCountdownHaptic()
            if let time = message["timeRemaining"] as? TimeInterval {
                timeRemaining = time
            }

        case "timerUpdate":
            // 일반 타이머 업데이트 (햅틱 없음)
            if let time = message["timeRemaining"] as? TimeInterval {
                timeRemaining = time
            }

        case "completed":
            // 운동 완료
            playCompletionHaptic()
            isWorkoutCompletedFromiPhone = true
            isReceivingFromiPhone = false

        case "started":
            // iPhone에서 타이머 시작됨
            isReceivingFromiPhone = true
            isWorkoutCompletedFromiPhone = false
            shouldDismissTimer = false
            if let routineData = message["routine"] as? Data,
               let routine = try? JSONDecoder().decode(WatchRoutine.self, from: routineData) {
                activeRoutine = routine
            }
            if let name = message["intervalName"] as? String {
                currentIntervalName = name
            }
            if let time = message["timeRemaining"] as? TimeInterval {
                timeRemaining = time
            }
            if let round = message["currentRound"] as? Int {
                currentRound = round
            }
            if let total = message["totalRounds"] as? Int {
                totalRounds = total
            }
            if let type = message["intervalType"] as? String {
                intervalType = type
            }
            playHaptic(type: .start)

        case "stopped":
            // iPhone에서 타이머 중지됨
            shouldDismissTimer = true
            isReceivingFromiPhone = false
            playHaptic(type: .stop)

        default:
            break
        }
    }

    private func handleApplicationContext(_ context: [String: Any]) {
        // 루틴 데이터 동기화
        if let routinesData = context["routines"] as? Data,
           let routines = try? JSONDecoder().decode([WatchRoutine].self, from: routinesData) {
            DispatchQueue.main.async {
                WatchRoutineStore.shared.updateRoutines(routines)
            }
        }
    }

    // 백그라운드에서 수신된 타이머 이벤트 처리
    private func handleTimerUserInfo(_ userInfo: [String: Any], action: String) {
        switch action {
        case "started":
            // 타이머 데이터 저장
            isReceivingFromiPhone = true
            isWorkoutCompletedFromiPhone = false
            shouldDismissTimer = false

            if let routineData = userInfo["routine"] as? Data,
               let routine = try? JSONDecoder().decode(WatchRoutine.self, from: routineData) {
                activeRoutine = routine
            }
            if let name = userInfo["intervalName"] as? String {
                currentIntervalName = name
            }
            if let time = userInfo["timeRemaining"] as? TimeInterval {
                timeRemaining = time
            }
            if let round = userInfo["currentRound"] as? Int {
                currentRound = round
            }
            if let total = userInfo["totalRounds"] as? Int {
                totalRounds = total
            }
            if let type = userInfo["intervalType"] as? String {
                intervalType = type
            }

            // 로컬 알림 표시 (앱이 백그라운드일 때)
            postTimerStartNotification()

            // 앱이 포그라운드로 오면 타이머 화면을 열도록 플래그 설정
            pendingTimerStart = true
            playHaptic(type: .start)

        default:
            break
        }
    }

    // 타이머 시작 로컬 알림
    private func postTimerStartNotification() {
        let content = UNMutableNotificationContent()
        content.title = activeRoutine?.name ?? "Interval"
        content.body = String(localized: "Workout started on iPhone. Tap to open.")
        content.sound = .default
        content.categoryIdentifier = "TIMER_START"

        let request = UNNotificationRequest(
            identifier: "timer_start_\(UUID().uuidString)",
            content: content,
            trigger: nil // 즉시 표시
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to post notification: \(error)")
            }
        }
    }

    // 대기 중인 타이머 시작 처리 완료
    func clearPendingTimerStart() {
        pendingTimerStart = false
    }
}
