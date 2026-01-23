//
//  SplashView.swift
//  IntervalApp
//
//  Created by Claude on 2025.
//

import SwiftUI

struct SplashView: View {
    @Binding var isFinished: Bool

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            Image("splash")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
        }
        .onAppear {
            // 1.5초 후 스플래시 종료
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeOut(duration: 0.3)) {
                    isFinished = true
                }
            }
        }
    }
}

#Preview {
    SplashView(isFinished: .constant(false))
}
