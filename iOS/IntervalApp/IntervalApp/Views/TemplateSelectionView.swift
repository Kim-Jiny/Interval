//
//  TemplateSelectionView.swift
//  IntervalApp
//
//  Created by 김미진 on 1/15/26.
//

import SwiftUI

struct TemplateSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    let onSelect: (Routine) -> Void

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(RoutineTemplate.templates) { template in
                        TemplateCard(template: template)
                            .onTapGesture {
                                onSelect(template.routine)
                                dismiss()
                            }
                    }
                }
                .padding()
            }
            .navigationTitle("Select Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct TemplateCard: View {
    let template: RoutineTemplate

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: template.icon)
                .font(.system(size: 36))
                .foregroundStyle(iconColor)

            VStack(spacing: 4) {
                Text(template.name)
                    .font(.headline)
                    .lineLimit(1)

                Text(template.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 8) {
                Label("\(template.routine.intervals.count)", systemImage: "list.bullet")
                Label("\(template.routine.rounds)R", systemImage: "repeat")
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .frame(height: 160)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var iconColor: Color {
        switch template.icon {
        case "flame.fill": return .orange
        case "figure.run": return .blue
        case "figure.core.training": return .purple
        case "figure.strengthtraining.functional": return .green
        case "bolt.fill": return .red
        case "figure.flexibility": return .cyan
        default: return .gray
        }
    }
}

#Preview {
    TemplateSelectionView { routine in
        print("Selected: \(routine.name)")
    }
}
