//
//  RoutineStore.swift
//  IntervalApp
//
//  Created by 김미진 on 1/14/26.
//

import Foundation
import SwiftUI

class RoutineStore: ObservableObject {
    @Published var routines: [Routine] = []

    private let storageKey = "savedRoutines"

    init() {
        loadRoutines()

        // 처음 실행 시 샘플 루틴 추가
        if routines.isEmpty {
            routines = [Routine.sample, Routine.tabata]
            saveRoutines()
        } else {
            // 기존 루틴이 있으면 Watch에 동기화
            PhoneConnectivityManager.shared.syncRoutines(routines)
        }
    }

    func addRoutine(_ routine: Routine) {
        routines.append(routine)
        saveRoutines()
    }

    func updateRoutine(_ routine: Routine) {
        if let index = routines.firstIndex(where: { $0.id == routine.id }) {
            var updatedRoutine = routine
            updatedRoutine.updatedAt = Date()
            routines[index] = updatedRoutine
            saveRoutines()
        }
    }

    func deleteRoutine(_ routine: Routine) {
        routines.removeAll { $0.id == routine.id }
        saveRoutines()
    }

    func deleteRoutine(at offsets: IndexSet) {
        routines.remove(atOffsets: offsets)
        saveRoutines()
    }

    func moveRoutine(from source: IndexSet, to destination: Int) {
        routines.move(fromOffsets: source, toOffset: destination)
        saveRoutines()
    }

    private func saveRoutines() {
        do {
            let data = try JSONEncoder().encode(routines)
            UserDefaults.standard.set(data, forKey: storageKey)

            // Watch에 루틴 동기화
            PhoneConnectivityManager.shared.syncRoutines(routines)
        } catch {
            print("Failed to save routines: \(error)")
        }
    }

    private func loadRoutines() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            return
        }

        do {
            routines = try JSONDecoder().decode([Routine].self, from: data)
        } catch {
            print("Failed to load routines: \(error)")
        }
    }
}
