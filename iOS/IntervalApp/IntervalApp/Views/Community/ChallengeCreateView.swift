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
    @State private var createdChallenge: Challenge?
    @State private var errorMessage: String?
    @State private var showingError = false
    @State private var isCreating = false
    @State private var showingSuccess = false

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
                          in: registrationEndDate.addingTimeInterval(60)...,
                          displayedComponents: [.date, .hourAndMinute])

                DatePicker(String(localized: "Challenge Ends"),
                          selection: $challengeEndDate,
                          in: challengeStartDate.addingTimeInterval(60)...,
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
                    Stepper(String(localized: "Max Participants") + ": \(maxParticipants)", value: $maxParticipants, in: 2...100)
                }
            } header: {
                Text("Settings")
            }

            // Entry Fee Section
            Section {
                // Entry Fee Stepper
                HStack {
                    Label {
                        Text(String(localized: "Entry Fee"))
                    } icon: {
                        Image(systemName: "ticket.fill")
                            .foregroundStyle(.blue)
                    }
                    Spacer()
                    HStack(spacing: 16) {
                        Button {
                            if entryFee >= 50 { entryFee -= 50 }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.title2)
                                .foregroundStyle(entryFee >= 50 ? .blue : .gray)
                        }
                        .buttonStyle(.plain)

                        Text("\(entryFee)M")
                            .font(.title3)
                            .fontWeight(.bold)
                            .monospacedDigit()
                            .frame(minWidth: 70)

                        Button {
                            if entryFee < 10000 { entryFee += 50 }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundStyle(entryFee < 10000 ? .blue : .gray)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 4)
            } header: {
                Text(String(localized: "Entry Fee"))
            } footer: {
                Text(String(localized: "Entry fee goes to the prize pool"))
                    .foregroundStyle(.secondary)
            }

            // Cost Summary Section
            Section {
                // Visual Summary Card
                VStack(spacing: 0) {
                    // Creation Fee Row
                    HStack {
                        HStack(spacing: 8) {
                            Text("🎨")
                            Text(String(localized: "Creation Fee"))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("300M")
                            .fontWeight(.medium)
                    }
                    .padding(.vertical, 12)

                    Divider()

                    // Entry Fee Row
                    HStack {
                        HStack(spacing: 8) {
                            Text("🎟️")
                            Text(String(localized: "Entry Fee"))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("\(entryFee)M")
                            .fontWeight(.medium)
                    }
                    .padding(.vertical, 12)

                    Divider()

                    // Total Row
                    HStack {
                        HStack(spacing: 8) {
                            Text("💰")
                            Text(String(localized: "Total Required"))
                                .fontWeight(.semibold)
                        }
                        Spacer()
                        Text("\(totalRequired)M")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(.orange)
                    }
                    .padding(.vertical, 12)
                }

                // Balance Card
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(String(localized: "Your Balance"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(mileageManager.balance?.formattedBalance ?? "0M")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(hasEnoughBalance ? .green : .red)
                    }

                    Spacer()

                    if hasEnoughBalance {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(.green)
                    } else {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(.red)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(hasEnoughBalance ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                )
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            } header: {
                Text(String(localized: "Cost Summary"))
            } footer: {
                if !hasEnoughBalance {
                    Label(String(localized: "Insufficient balance"), systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
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
                                .tint(.white)
                            Text("Creating...")
                                .fontWeight(.semibold)
                                .padding(.leading, 8)
                        } else {
                            Text("Create Challenge")
                                .fontWeight(.semibold)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
                .disabled(!isValid || isCreating)
                .listRowBackground(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isValid && !isCreating ? Color.orange : Color.gray.opacity(0.3))
                )
                .foregroundStyle(isValid && !isCreating ? .white : .secondary)
            } footer: {
                if let message = validationMessage {
                    Text(message)
                        .foregroundStyle(.red)
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle(String(localized: "New Challenge"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(String(localized: "Cancel")) {
                    dismiss()
                }
                .disabled(isCreating)
            }
        }
        .overlay {
            if isCreating {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()

                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.white)
                        Text("Creating Challenge...")
                            .font(.headline)
                            .foregroundStyle(.white)
                    }
                    .padding(32)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
        }
        .allowsHitTesting(!isCreating)
        .sheet(isPresented: $showingRoutineSelector) {
            NavigationStack {
                RoutineSelectorView(selectedRoutine: $selectedRoutine)
            }
        }
        .sheet(isPresented: $showingSuccess) {
            ChallengeCreatedView(
                challenge: createdChallenge,
                shareUrl: shareUrl,
                onDismiss: { dismiss() }
            )
        }
        .sheet(isPresented: $showingShareSheet) {
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
        // Auto-update start date when registration end date changes
        // Auto-update start date when registration end date changes (always set to reg end + 1 min)
        .onChange(of: registrationEndDate) { _, newValue in
            challengeStartDate = newValue.addingTimeInterval(60) // +1 minute
        }
        // Auto-update end date when start date changes
        .onChange(of: challengeStartDate) { _, newValue in
            if challengeEndDate <= newValue {
                // Set end date to start date + 1 day
                challengeEndDate = newValue.addingTimeInterval(24 * 60 * 60)
            }
        }
    }

    // MARK: - Validation

    private var validationMessage: String? {
        if title.trimmingCharacters(in: .whitespaces).isEmpty {
            return String(localized: "Please enter a challenge title.")
        }
        if selectedRoutine == nil {
            return String(localized: "Please select a routine.")
        }
        if registrationEndDate <= Date() {
            return String(localized: "Registration end date must be in the future.")
        }
        if challengeStartDate < registrationEndDate.addingTimeInterval(60) {
            return String(localized: "Challenge must start at least 1 minute after registration ends.")
        }
        if challengeEndDate < challengeStartDate.addingTimeInterval(60) {
            return String(localized: "Challenge end date must be at least 1 minute after start date.")
        }
        if !hasEnoughBalance {
            return String(localized: "Insufficient mileage balance.")
        }
        return nil
    }

    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
        && selectedRoutine != nil
        && registrationEndDate > Date()
        && challengeStartDate >= registrationEndDate.addingTimeInterval(60)
        && challengeEndDate >= challengeStartDate.addingTimeInterval(60)
        && hasEnoughBalance
    }

    private let creationFee = 300

    private var totalRequired: Int {
        creationFee + entryFee
    }

    private var hasEnoughBalance: Bool {
        guard let balance = mileageManager.balance?.balance else { return false }
        return balance >= totalRequired
    }

    // MARK: - Create Challenge

    private func createChallenge() async {
        guard let routine = selectedRoutine else { return }

        isCreating = true
        defer { isCreating = false }

        do {
            let (challenge, url) = try await challengeManager.createChallenge(
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

            createdChallenge = challenge
            shareUrl = url
            showingSuccess = true
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}

// MARK: - Challenge Created View

struct ChallengeCreatedView: View {
    let challenge: Challenge?
    let shareUrl: String?
    let onDismiss: () -> Void

    @State private var showingShareSheet = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Success Icon
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.green)

            // Title
            Text("Challenge Created!")
                .font(.title)
                .fontWeight(.bold)

            // Challenge Info
            if let challenge = challenge {
                VStack(spacing: 8) {
                    Text(challenge.title)
                        .font(.headline)

                    HStack(spacing: 16) {
                        Label(challenge.formattedEntryFee, systemImage: "ticket.fill")
                        Label(challenge.formattedPrizePool, systemImage: "trophy.fill")
                            .foregroundStyle(.orange)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Text("Share this challenge with friends to invite them!")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer()

            // Buttons
            VStack(spacing: 12) {
                Button {
                    showingShareSheet = true
                } label: {
                    Label("Share Challenge", systemImage: "square.and.arrow.up")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button {
                    onDismiss()
                } label: {
                    Text("Done")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .foregroundStyle(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
        .sheet(isPresented: $showingShareSheet) {
            if let url = shareUrl, let shareURL = URL(string: url) {
                ShareSheet(items: [shareURL])
            }
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

// MARK: - Keyboard Helper

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    NavigationStack {
        ChallengeCreateView()
    }
    .environmentObject(RoutineStore())
}
