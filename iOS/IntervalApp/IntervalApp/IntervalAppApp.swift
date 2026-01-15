//
//  IntervalAppApp.swift
//  IntervalApp
//
//  Created by 김미진 on 1/14/26.
//

import SwiftUI

@main
struct IntervalAppApp: App {
    @StateObject private var routineStore = RoutineStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(routineStore)
        }
    }
}
