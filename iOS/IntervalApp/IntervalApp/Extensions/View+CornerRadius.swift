//
//  View+CornerRadius.swift
//  IntervalApp
//
//  Created on 1/21/26.
//

import SwiftUI

// MARK: - Corner Radius Extension

extension View {
    /// 모든 코너에 라운드 적용
    func cornerRadius(_ radius: CGFloat) -> some View {
        clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
    }

    /// 특정 코너에만 라운드 적용
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }

    /// 라운드 + 테두리
    func roundedBorder(_ radius: CGFloat, color: Color, lineWidth: CGFloat = 1) -> some View {
        self
            .cornerRadius(radius)
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(color, lineWidth: lineWidth)
            )
    }

    /// 특정 코너만 라운드 + 테두리
    func roundedBorder(_ radius: CGFloat, corners: UIRectCorner, color: Color, lineWidth: CGFloat = 1) -> some View {
        self
            .cornerRadius(radius, corners: corners)
            .overlay(
                RoundedCorner(radius: radius, corners: corners)
                    .stroke(color, lineWidth: lineWidth)
            )
    }
}

// MARK: - RoundedCorner Shape

struct RoundedCorner: Shape {
    var radius: CGFloat
    var corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        // 모든 코너 라운드
        Text("All Corners")
            .padding()
            .background(Color.blue)
            .cornerRadius(12)

        // 상단만 라운드
        Text("Top Corners Only")
            .padding()
            .background(Color.green)
            .cornerRadius(12, corners: [.topLeft, .topRight])

        // 라운드 + 테두리
        Text("With Border")
            .padding()
            .roundedBorder(12, color: .red, lineWidth: 2)

        // 특정 코너 라운드 + 테두리
        Text("Bottom + Border")
            .padding()
            .background(Color.orange)
            .roundedBorder(12, corners: [.bottomLeft, .bottomRight], color: .black, lineWidth: 2)
    }
    .padding()
}
