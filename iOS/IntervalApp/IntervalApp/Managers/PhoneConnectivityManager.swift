//
//  PhoneConnectivityManager.swift
//  IntervalApp
//
//  Created by Claude on 1/15/26.
//

import Foundation
import WatchConnectivity

class PhoneConnectivityManager: NSObject, ObservableObject {
    static let shared = PhoneConnectivityManager()

    @Published var isWatchAppInstalled = false
    @Published var isWatchReachable = false

    private var session: WCSession?

    override init() {
        super.init()
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
    }

    // MARK: - 루틴 데이터 동기화

    enum SyncResult {
        case success
        case watchAppNotInstalled
        case sessionNotActivated
        case encodingFailed
        case syncFailed(String)
    }

    func syncRoutines(_ routines: [Routine]) -> SyncResult {
        guard let session = session, session.activationState == .activated else {
            return .sessionNotActivated
        }

        guard session.isWatchAppInstalled else {
            return .watchAppNotInstalled
        }

        // WatchRoutine 형태로 변환
        let watchRoutines = routines.map { routine in
            WatchRoutineData(
                id: routine.id,
                name: routine.name,
                intervals: routine.intervals.map { interval in
                    WatchIntervalData(
                        id: interval.id,
                        name: interval.name,
                        duration: interval.duration,
                        type: interval.type.rawValue
                    )
                },
                rounds: routine.rounds
            )
        }

        guard let data = try? JSONEncoder().encode(watchRoutines) else {
            return .encodingFailed
        }

        do {
            try session.updateApplicationContext(["routines": data])
            print("Routines synced to Watch")
            return .success
        } catch {
            print("Failed to sync routines: \(error.localizedDescription)")
            return .syncFailed(error.localizedDescription)
        }
    }

    // MARK: - 타이머 이벤트 전송

    func sendTimerStarted(routine: Routine, intervalName: String, timeRemaining: TimeInterval, currentRound: Int, intervalType: String) {
        guard let session = session, session.activationState == .activated else { return }

        let watchRoutine = WatchRoutineData(
            id: routine.id,
            name: routine.name,
            intervals: routine.intervals.map { interval in
                WatchIntervalData(
                    id: interval.id,
                    name: interval.name,
                    duration: interval.duration,
                    type: interval.type.rawValue
                )
            },
            rounds: routine.rounds
        )

        var message: [String: Any] = [
            "action": "started",
            "intervalName": intervalName,
            "timeRemaining": timeRemaining,
            "currentRound": currentRound,
            "totalRounds": routine.rounds,
            "intervalType": intervalType
        ]

        if let routineData = try? JSONEncoder().encode(watchRoutine) {
            message["routine"] = routineData
        }

        guard session.isWatchAppInstalled else { return }

        // 항상 transferUserInfo로 먼저 전송 (신뢰성 보장)
        session.transferUserInfo(message)
        print("Timer start info transferred to Watch")

        // Watch가 활성화되어 있으면 sendMessage도 시도 (즉시 전달용)
        if session.isReachable {
            session.sendMessage(message, replyHandler: nil) { _ in
                // 실패해도 transferUserInfo로 이미 전송됨
            }
        }
    }

    func sendIntervalChange(intervalName: String, timeRemaining: TimeInterval, currentRound: Int, totalRounds: Int, intervalType: String) {
        guard let session = session, session.activationState == .activated else { return }
        guard session.isWatchAppInstalled else { return }

        let message: [String: Any] = [
            "action": "intervalChange",
            "intervalName": intervalName,
            "timeRemaining": timeRemaining,
            "currentRound": currentRound,
            "totalRounds": totalRounds,
            "intervalType": intervalType
        ]

        // 항상 transferUserInfo로 먼저 전송 (신뢰성 보장)
        session.transferUserInfo(message)

        // Watch가 활성화되어 있으면 sendMessage도 시도 (즉시 전달용)
        if session.isReachable {
            session.sendMessage(message, replyHandler: nil) { _ in }
        }
    }

    func sendCountdown(timeRemaining: TimeInterval) {
        guard let session = session, session.isReachable else { return }

        let message: [String: Any] = [
            "action": "countdown",
            "timeRemaining": timeRemaining
        ]

        // 실시간 업데이트는 sendMessage만 사용 (transferUserInfo는 큐에 쌓임)
        session.sendMessage(message, replyHandler: nil) { _ in }
    }

    func sendTimerUpdate(timeRemaining: TimeInterval) {
        guard let session = session, session.isReachable else { return }

        let message: [String: Any] = [
            "action": "timerUpdate",
            "timeRemaining": timeRemaining
        ]

        // 실시간 업데이트는 sendMessage만 사용 (transferUserInfo는 큐에 쌓임)
        session.sendMessage(message, replyHandler: nil) { _ in }
    }

    func sendTimerStopped() {
        guard let session = session, session.activationState == .activated else { return }
        guard session.isWatchAppInstalled else { return }

        let message: [String: Any] = [
            "action": "stopped"
        ]

        // 항상 transferUserInfo로 먼저 전송 (신뢰성 보장)
        session.transferUserInfo(message)

        // Watch가 활성화되어 있으면 sendMessage도 시도 (즉시 전달용)
        if session.isReachable {
            session.sendMessage(message, replyHandler: nil) { _ in }
        }
    }

    func sendTimerCompleted() {
        guard let session = session, session.activationState == .activated else { return }
        guard session.isWatchAppInstalled else { return }

        let message: [String: Any] = [
            "action": "completed"
        ]

        // 항상 transferUserInfo로 먼저 전송 (신뢰성 보장)
        session.transferUserInfo(message)

        // Watch가 활성화되어 있으면 sendMessage도 시도 (즉시 전달용)
        if session.isReachable {
            session.sendMessage(message, replyHandler: nil) { _ in }
        }
    }
}

// MARK: - WCSessionDelegate

extension PhoneConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            if activationState == .activated {
                self.isWatchAppInstalled = session.isWatchAppInstalled
                self.isWatchReachable = session.isReachable
            }
        }

        if let error = error {
            print("WCSession activation failed: \(error.localizedDescription)")
        } else {
            print("WCSession activated on iPhone: \(activationState.rawValue)")
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {
        print("WCSession became inactive")
    }

    func sessionDidDeactivate(_ session: WCSession) {
        print("WCSession deactivated")
        // 필요시 재활성화
        session.activate()
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isWatchReachable = session.isReachable
        }
        print("Watch reachability changed: \(session.isReachable)")
    }

    func sessionWatchStateDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isWatchAppInstalled = session.isWatchAppInstalled
        }
    }

    // Watch에서 메시지 수신
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        // 필요시 Watch에서 온 메시지 처리
        print("Received message from Watch: \(message)")
    }
}

// MARK: - Watch용 데이터 구조체 (Codable)

struct WatchRoutineData: Codable {
    let id: UUID
    let name: String
    let intervals: [WatchIntervalData]
    let rounds: Int
}

struct WatchIntervalData: Codable {
    let id: UUID
    let name: String
    let duration: TimeInterval
    let type: String
}
