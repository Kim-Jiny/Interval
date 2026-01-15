//
//  HomeView.swift
//  IntervalApp
//
//  Created by 김미진 on 1/14/26.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var routineStore: RoutineStore
    @State private var showingAddRoutine = false
    @State private var selectedRoutine: Routine?

    var body: some View {
        NavigationStack {
            List {
                ForEach(routineStore.routines) { routine in
                    RoutineRowView(routine: routine)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedRoutine = routine
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                routineStore.deleteRoutine(routine)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }

                            NavigationLink {
                                RoutineEditorView(routine: routine, isNew: false)
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
                }
                .onMove { source, destination in
                    routineStore.moveRoutine(from: source, to: destination)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Interval Training")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddRoutine = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddRoutine) {
                NavigationStack {
                    RoutineEditorView(routine: nil, isNew: true)
                }
            }
            .fullScreenCover(item: $selectedRoutine) { routine in
                TimerView(routine: routine)
            }
        }
    }
}

struct RoutineRowView: View {
    let routine: Routine

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(routine.name)
                .font(.headline)

            HStack(spacing: 16) {
                Label("\(routine.intervals.count) intervals", systemImage: "list.bullet")
                Label("\(routine.rounds) rounds", systemImage: "repeat")
                Label(routine.formattedTotalDuration, systemImage: "clock")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    HomeView()
        .environmentObject(RoutineStore())
}
