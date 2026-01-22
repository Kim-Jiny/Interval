//
//  SupportView.swift
//  IntervalApp
//
//  Created by Claude on 2024.
//

import SwiftUI

struct SupportView: View {
    @StateObject private var supportManager = SupportManager.shared
    @State private var showingCreateTicket = false

    var body: some View {
        Group {
            if supportManager.isLoading && supportManager.tickets.isEmpty {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                        .tint(.blue)
                    Text("Loading...")
                        .foregroundStyle(.secondary)
                }
            } else if supportManager.tickets.isEmpty {
                emptyState
            } else {
                ticketList
            }
        }
        .navigationTitle("Support")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingCreateTicket = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.blue)
                }
            }
        }
        .task {
            do {
                try await supportManager.fetchTickets()
            } catch {
                print("Failed to fetch tickets: \(error)")
            }
        }
        .refreshable {
            try? await supportManager.fetchTickets()
        }
        .sheet(isPresented: $showingCreateTicket) {
            NavigationStack {
                SupportTicketCreateView()
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 100, height: 100)
                Image(systemName: "bubble.left.and.bubble.right")
                    .font(.system(size: 40))
                    .foregroundStyle(.blue)
            }

            VStack(spacing: 8) {
                Text("No Inquiries Yet")
                    .font(.title3)
                    .fontWeight(.semibold)

                Text("Have a question or found a bug?\nWe're here to help!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                showingCreateTicket = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Create Inquiry")
                }
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(Color.blue)
                .clipShape(Capsule())
            }

            Spacer()
        }
        .padding()
    }

    // MARK: - Ticket List

    private var ticketList: some View {
        List {
            ForEach(supportManager.tickets) { ticket in
                NavigationLink {
                    SupportTicketDetailView(ticketId: ticket.id)
                } label: {
                    ticketRow(ticket)
                }
            }
        }
        .listStyle(.plain)
    }

    private func ticketRow(_ ticket: SupportTicket) -> some View {
        HStack(spacing: 12) {
            // Category Icon
            ZStack {
                Circle()
                    .fill(categoryColor(ticket.category).opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: ticket.category.icon)
                    .font(.system(size: 18))
                    .foregroundStyle(categoryColor(ticket.category))
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(ticket.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)

                    Spacer()

                    if ticket.hasNewReply == true {
                        Circle()
                            .fill(.red)
                            .frame(width: 8, height: 8)
                    }
                }

                HStack(spacing: 8) {
                    statusBadge(ticket.status)

                    if let replyCount = ticket.replyCount, replyCount > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "bubble.left.fill")
                                .font(.caption2)
                            Text("\(replyCount)")
                                .font(.caption)
                        }
                        .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Text(ticket.formattedDate)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func statusBadge(_ status: TicketStatus) -> some View {
        Text(status.displayName)
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundStyle(statusColor(status))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(statusColor(status).opacity(0.15))
            .clipShape(Capsule())
    }

    private func categoryColor(_ category: TicketCategory) -> Color {
        switch category {
        case .bug:
            return .red
        case .feature:
            return .yellow
        case .account:
            return .blue
        case .payment:
            return .green
        case .other:
            return .gray
        }
    }

    private func statusColor(_ status: TicketStatus) -> Color {
        switch status {
        case .open:
            return .red
        case .inProgress:
            return .orange
        case .resolved:
            return .green
        case .closed:
            return .gray
        }
    }
}

#Preview {
    NavigationStack {
        SupportView()
    }
}
