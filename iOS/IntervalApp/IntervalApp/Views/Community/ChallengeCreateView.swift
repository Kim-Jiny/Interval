//
//  ChallengeCreateView.swift
//  IntervalApp
//
//  Created by Claude on 2024.
//

import SwiftUI

struct ChallengeCreateView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var routineStore: RoutineStore
    @ObservedObject private var challengeManager = ChallengeManager.shared
    @ObservedObject private var mileageManager = MileageManager.shared

    @State private var title: String = ""
    @State private var description: String = ""
    @State private var selectedRoutine: Routine?
    @State private var registrationEndDate: Date = Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date()
    @State private var challengeStartDate: Date = Calendar.current.date(byAdding: .day, value: 4, to: Date()) ?? Date()
    @State private var challengeEndDate: Date = Calendar.current.date(byAdding: .day, value: 11, to: Date()) ?? Date()
    @State private var isPublic: Bool = true
    @State private var hasMaxParticipants: Bool = false
    @State private var maxParticipants: Int = 10
    @State private var entryFee: Int = 100

    @State private var showingRoutineSelector = false
    @State private var showingShareSheet = false
    @State private var shareUrl: String?
    @State private var errorMessage: String?
    @State private var showingError = false
    @State private var isCreating = false

    var body: some View {
        Form {
            // Basic Info Section
            Section {
                TextField(String(localized: "Challenge Title"), text: $title)

                TextField(String(localized: "Description (optional)"), text: $description, axis: .vertical)
                    .lineLimit(3...6)
            } header: {
                Text("Basic Info")
            }

            // Routine Section
            Section {
                Button {
                    showingRoutineSelector = true
                } label: {
                    HStack {
                        Text(selectedRoutine?.name ?? String(localized: "Select Routine"))
                            .foregroundStyle(selectedRoutine == nil ? .secondary : .primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)

                if let routine = selectedRoutine {
                    HStack(spacing: 16) {
                        Label("\(routine.intervals.count) intervals", systemImage: "list.bullet")
                        Label("\(routine.rounds) rounds", systemImage: "repeat")
                        Label(routine.formattedTotalDuration, systemImage: "clock")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            } header: {
                Text("Routine")
            }

            // Schedule Section
            Section {
                DatePicker(String(localized: "Registration Ends"),
                          selection: $registrationEndDate,
                          in: Date()...,
                          displayedComponents: [.date, .hourAndMinute])

                DatePicker(String(localized: "Challenge Starts"),
                          selection: $challengeStartDate,
                          in: registrationEndDate...,
                          displayedComponents: [.date, .hourAndMinute])

                DatePicker(String(localized: "Challenge Ends"),
                          selection: $challengeEndDate,
                          in: challengeStartDate...,
                          displayedComponents: [.date, .hourAndMinute])
            } header: {
                Text("Schedule")
            } footer: {
                let days = Calendar.current.dateComponents([.day], from: challengeStartDate, to: challengeEndDate).day ?? 0
                Text("Challenge duration: \(days + 1) days")
            }

            // Settings Section
            Section {
                Toggle(String(localized: "Public Challenge"), isOn: $isPublic)

                Toggle(String(localized: "Limit Participants"), isOn: $hasMaxParticipants)

                if hasMaxParticipants {
                    Stepper("Max: \(maxParticipants)", value: $maxParticipants, in: 2...100)
                }
            } header: {
                Text("Settings")
            }

            // Entry Fee Section
            Section {
                Stepper("Entry Fee: \(entryFee)M", value: $entryFee, in: 0...10000, step: 50)

                HStack {
                    Text("Your Balance")
                    Spacer()
                    Text(mileageManager.balance?.formattedBalance ?? "0M")
                        .foregroundStyle(hasEnoughBalance ? .primary : .primary)
                }
            } header: {
                Text("Entry Fee")
            } footer: {
                if !hasEnoughBalance {
                    Text("Insufficient balance. You need at least \(entryFee)M to create this challenge.")
                        .foregroundStyle(.red)
                } else {
                    Text("As the creator, you will automatically join and pay the entry fee.")
                }
            }

            // Create Button
            Section {
                Button {
                    Task {
                        await createChallenge()
                    }
                } label: {
                    HStack {
                        Spacer()
                        if isCreating {
                            ProgressView()
                        } else {
                            Text("Create Challenge")
                                .fontWeight(.semibold)
                        }
                        Spacer()
                    }
                }
                .disabled(!isValid || isCreating)
            }
        }
        .navigationTitle(String(localized: "New Challenge"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(String(localized: "Cancel")) {
                    dismiss()
                }
            }
        }
        .sheet(isPresented: $showingRoutineSelector) {
            NavigationStack {
                RoutineSelectorView(selectedRoutine: $selectedRoutine)
            }
        }
        .sheet(isPresented: $showingShareSheet, onDismiss: {
            dismiss()
        }) {
            if let url = shareUrl {
                ShareSheet(items: [URL(string: url)!])
            }
        }
        .alert(String(localized: "Error"), isPresented: $showingError) {
            Button(String(localized: "OK"), role: .cancel) {}
        } message: {
            Text(errorMessage ?? "An error occurred")
        }
        .task {
            await mileageManager.fetchBalance()
        }
    }

    // MARK: - Validation

    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
        && selectedRoutine != nil
        && registrationEndDate > Date()
        && challengeStartDate > registrationEndDate
        && challengeEndDate > challengeStartDate
        && hasEnoughBalance
    }

    private var hasEnoughBalance: Bool {
        guard let balance = mileageManager.balance?.balance else { return false }
        return balance >= entryFee
    }

    // MARK: - Create Challenge

    private func createChallenge() async {
        guard let routine = selectedRoutine else { return }

        isCreating = true
        defer { isCreating = false }

        do {
            let (_, url) = try await challengeManager.createChallenge(
                title: title.trimmingCharacters(in: .whitespaces),
                description: description.trimmingCharacters(in: .whitespaces).isEmpty ? nil : description,
                routine: routine,
                registrationEndAt: registrationEndDate,
                challengeStartAt: challengeStartDate,
                challengeEndAt: challengeEndDate,
                isPublic: isPublic,
                maxParticipants: hasMaxParticipants ? maxParticipants : nil,
                entryFee: entryFee
            )

            shareUrl = url
            showingShareSheet = true
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}

// MARK: - Routine Selector View

struct RoutineSelectorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var routineStore: RoutineStore
    @Binding var selectedRoutine: Routine?

    var body: some View {
        List {
            ForEach(routineStore.routines) { routine in
                Button {
                    selectedRoutine = routine
                    dismiss()
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(routine.name)
                                .font(.headline)
                                .foregroundStyle(.primary)

                            HStack(spacing: 12) {
                                Label("\(routine.intervals.count) intervals", systemImage: "list.bullet")
                                Label("\(routine.rounds) rounds", systemImage: "repeat")
                                Label(routine.formattedTotalDuration, systemImage: "clock")
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if selectedRoutine?.id == routine.id {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.blue)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .navigationTitle(String(localized: "Select Routine"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(String(localized: "Cancel")) {
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ChallengeCreateView()
    }
    .environmentObject(RoutineStore())
}
