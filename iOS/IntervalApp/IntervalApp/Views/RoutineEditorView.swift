//
//  RoutineEditorView.swift
//  IntervalApp
//
//  Created by 김미진 on 1/14/26.
//

import SwiftUI

struct IntervalEditItem: Identifiable {
    let id = UUID()
    let interval: WorkoutInterval?
    let index: Int?
}

struct RoutineEditorView: View {
    @EnvironmentObject var routineStore: RoutineStore
    @Environment(\.dismiss) private var dismiss

    let isNew: Bool

    @State private var name: String
    @State private var intervals: [WorkoutInterval]
    @State private var rounds: Int
    @State private var editingItem: IntervalEditItem?

    private let originalRoutine: Routine?

    init(routine: Routine?, isNew: Bool) {
        self.isNew = isNew
        self.originalRoutine = routine

        _name = State(initialValue: routine?.name ?? String(localized: "New Routine"))
        _intervals = State(initialValue: routine?.intervals ?? [
            WorkoutInterval.defaultWorkout,
            WorkoutInterval.defaultRest
        ])
        _rounds = State(initialValue: routine?.rounds ?? 3)
    }

    var body: some View {
        Form {
            Section("Routine Info") {
                TextField("Routine Name", text: $name)

                Stepper("Rounds: \(rounds)", value: $rounds, in: 1...99)
            }

            Section("Intervals") {
                ForEach(Array(intervals.enumerated()), id: \.element.id) { index, interval in
                    IntervalRowView(interval: interval)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            editingItem = IntervalEditItem(interval: interval, index: index)
                        }
                }
                .onDelete(perform: deleteInterval)
                .onMove(perform: moveInterval)

                Button {
                    editingItem = IntervalEditItem(interval: nil, index: nil)
                } label: {
                    Label("Add Interval", systemImage: "plus.circle")
                }
            }

            Section("Total Time") {
                let totalSeconds = intervals.reduce(0) { $0 + $1.duration } * Double(rounds)
                let minutes = Int(totalSeconds) / 60
                let seconds = Int(totalSeconds) % 60
                Text("\(minutes)m \(String(format: "%02d", seconds))s")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(isNew ? "New Routine" : "Edit Routine")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveRoutine()
                }
                .disabled(name.isEmpty || intervals.isEmpty)
            }
        }
        .sheet(item: $editingItem) { item in
            NavigationStack {
                IntervalEditorView(
                    interval: item.interval,
                    onSave: { newInterval in
                        if let index = item.index {
                            intervals[index] = newInterval
                        } else {
                            intervals.append(newInterval)
                        }
                    }
                )
            }
        }
    }

    private func deleteInterval(at offsets: IndexSet) {
        intervals.remove(atOffsets: offsets)
    }

    private func moveInterval(from source: IndexSet, to destination: Int) {
        intervals.move(fromOffsets: source, toOffset: destination)
    }

    private func saveRoutine() {
        if isNew {
            let newRoutine = Routine(
                name: name,
                intervals: intervals,
                rounds: rounds
            )
            routineStore.addRoutine(newRoutine)
        } else if let original = originalRoutine {
            let updatedRoutine = Routine(
                id: original.id,
                name: name,
                intervals: intervals,
                rounds: rounds,
                createdAt: original.createdAt
            )
            routineStore.updateRoutine(updatedRoutine)
        }
        dismiss()
    }
}

struct IntervalRowView: View {
    let interval: WorkoutInterval

    var body: some View {
        HStack {
            Circle()
                .fill(colorForType(interval.type))
                .frame(width: 12, height: 12)

            VStack(alignment: .leading) {
                Text(interval.name)
                    .font(.body)
                Text(interval.type.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(interval.formattedDuration)
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    private func colorForType(_ type: IntervalType) -> Color {
        switch type {
        case .workout: return .red
        case .rest: return .green
        case .warmup: return .orange
        case .cooldown: return .blue
        }
    }
}

struct IntervalEditorView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var minutes: Int
    @State private var seconds: Int
    @State private var type: IntervalType

    private let isNewInterval: Bool
    private let originalTypeName: String

    let onSave: (WorkoutInterval) -> Void

    init(interval: WorkoutInterval?, onSave: @escaping (WorkoutInterval) -> Void) {
        let isNew = interval == nil
        let interval = interval ?? WorkoutInterval.defaultWorkout
        _name = State(initialValue: interval.name)
        _minutes = State(initialValue: Int(interval.duration) / 60)
        _seconds = State(initialValue: Int(interval.duration) % 60)
        _type = State(initialValue: interval.type)
        self.onSave = onSave
        self.isNewInterval = isNew
        self.originalTypeName = interval.type.displayName
    }

    var body: some View {
        Form {
            Section("Interval Info") {
                TextField("Interval Name", text: $name)

                Picker("Type", selection: $type) {
                    ForEach(IntervalType.allCases, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .onChange(of: type) { oldType, newType in
                    if name == oldType.displayName || (isNewInterval && name == originalTypeName) {
                        name = newType.displayName
                    }
                }
            }

            Section("Time Setting") {
                HStack {
                    Picker("Minutes", selection: $minutes) {
                        ForEach(0..<60) { min in
                            Text("\(min)m").tag(min)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity)

                    Picker("Seconds", selection: $seconds) {
                        ForEach(0..<60) { sec in
                            Text("\(sec)s").tag(sec)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity)
                }
                .frame(height: 150)
            }
        }
        .navigationTitle("Edit Interval")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    let duration = TimeInterval(minutes * 60 + seconds)
                    let interval = WorkoutInterval(
                        name: name,
                        duration: max(1, duration),
                        type: type
                    )
                    onSave(interval)
                    dismiss()
                }
                .disabled(name.isEmpty)
            }
        }
    }
}

#Preview {
    NavigationStack {
        RoutineEditorView(routine: Routine.sample, isNew: false)
            .environmentObject(RoutineStore())
    }
}
