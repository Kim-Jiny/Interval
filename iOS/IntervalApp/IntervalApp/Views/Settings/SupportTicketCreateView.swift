//
//  SupportTicketCreateView.swift
//  IntervalApp
//
//  Created by Claude on 2024.
//

import SwiftUI

struct SupportTicketCreateView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var supportManager = SupportManager.shared

    @State private var selectedCategory: TicketCategory = .other
    @State private var title = ""
    @State private var content = ""
    @State private var isSubmitting = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingSuccess = false
    @FocusState private var focusedField: Field?

    private enum Field {
        case title, content
    }

    var body: some View {
        Form {
            // Category Section
            Section {
                Picker("Category", selection: $selectedCategory) {
                    ForEach(TicketCategory.allCases, id: \.self) { category in
                        HStack {
                            Image(systemName: category.icon)
                            Text(category.displayName)
                        }
                        .tag(category)
                    }
                }
                .pickerStyle(.menu)
            } header: {
                Text("Category")
            } footer: {
                Text(categoryDescription)
            }

            // Title Section
            Section {
                TextField("Brief summary of your issue", text: $title)
                    .textInputAutocapitalization(.sentences)
                    .focused($focusedField, equals: .title)
            } header: {
                Text("Title")
            }

            // Content Section
            Section {
                TextEditor(text: $content)
                    .frame(minHeight: 150)
                    .focused($focusedField, equals: .content)
            } header: {
                Text("Description")
            } footer: {
                Text("Please provide as much detail as possible to help us assist you better.")
            }

            // Device Info Section
            Section {
                HStack {
                    Text("Device")
                    Spacer()
                    Text(deviceInfo)
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("App Version")
                    Spacer()
                    Text(appVersion)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Device Information")
            } footer: {
                Text("This information helps us diagnose issues faster.")
            }
        }
        .navigationTitle("New Inquiry")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    submitTicket()
                } label: {
                    if isSubmitting {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Text("Submit")
                            .fontWeight(.semibold)
                    }
                }
                .disabled(!isFormValid || isSubmitting)
            }

            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    focusedField = nil
                }
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .alert("Submitted", isPresented: $showingSuccess) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Your inquiry has been submitted. We'll get back to you soon!")
        }
        .interactiveDismissDisabled(isSubmitting)
        .scrollDismissesKeyboard(.interactively)
        .onTapGesture {
            focusedField = nil
        }
    }

    private var isFormValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var categoryDescription: String {
        switch selectedCategory {
        case .bug:
            return String(localized: "Report app crashes, errors, or unexpected behavior")
        case .feature:
            return String(localized: "Suggest new features or improvements")
        case .account:
            return String(localized: "Issues with login, profile, or account settings")
        case .payment:
            return String(localized: "Questions about mileage, challenges, or transactions")
        case .other:
            return String(localized: "General questions or feedback")
        }
    }

    private var deviceInfo: String {
        let device = UIDevice.current
        return "\(device.model), iOS \(device.systemVersion)"
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        return "\(version) (\(build))"
    }

    private func submitTicket() {
        isSubmitting = true

        Task {
            do {
                _ = try await supportManager.createTicket(
                    category: selectedCategory,
                    title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                    content: content.trimmingCharacters(in: .whitespacesAndNewlines)
                )
                isSubmitting = false
                showingSuccess = true
            } catch {
                isSubmitting = false
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
}

#Preview {
    NavigationStack {
        SupportTicketCreateView()
    }
}
