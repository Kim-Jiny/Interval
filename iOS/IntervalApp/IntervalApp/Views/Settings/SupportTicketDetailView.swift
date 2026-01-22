//
//  SupportTicketDetailView.swift
//  IntervalApp
//
//  Created by Claude on 2024.
//

import SwiftUI

struct SupportTicketDetailView: View {
    let ticketId: Int

    @StateObject private var supportManager = SupportManager.shared

    var body: some View {
        Group {
            if supportManager.isLoading && supportManager.currentTicket == nil {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                        .tint(.blue)
                    Text("Loading...")
                        .foregroundStyle(.secondary)
                }
            } else if let ticket = supportManager.currentTicket {
                ScrollView {
                    VStack(spacing: 16) {
                        // Ticket Info Card
                        ticketInfoCard(ticket)

                        // Original Content
                        contentCard(ticket)

                        // Replies Section
                        if !supportManager.currentReplies.isEmpty {
                            repliesSection
                        }

                        // Waiting for Reply
                        if supportManager.currentReplies.isEmpty && ticket.status != .resolved && ticket.status != .closed {
                            waitingCard
                        }
                    }
                    .padding()
                }
                .background(Color(.systemGroupedBackground))
            } else {
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.red.opacity(0.1))
                            .frame(width: 80, height: 80)
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(.red)
                    }
                    Text("Ticket not found")
                        .font(.headline)
                }
            }
        }
        .navigationTitle("Inquiry #\(ticketId)")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            do {
                try await supportManager.fetchTicketDetail(id: ticketId)
            } catch {
                print("Failed to fetch ticket detail: \(error)")
            }
        }
        .refreshable {
            try? await supportManager.fetchTicketDetail(id: ticketId)
        }
    }

    // MARK: - Ticket Info Card

    private func ticketInfoCard(_ ticket: SupportTicket) -> some View {
        VStack(spacing: 12) {
            HStack {
                // Category Badge
                HStack(spacing: 6) {
                    Image(systemName: ticket.category.icon)
                        .font(.caption)
                    Text(ticket.category.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundStyle(categoryColor(ticket.category))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(categoryColor(ticket.category).opacity(0.15))
                .clipShape(Capsule())

                Spacer()

                // Status Badge
                Text(ticket.status.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(statusColor(ticket.status))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(statusColor(ticket.status).opacity(0.15))
                    .clipShape(Capsule())
            }

            Text(ticket.title)
                .font(.title3)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack {
                Image(systemName: "calendar")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(ticket.formattedDate)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }

    // MARK: - Content Card

    private func contentCard(_ ticket: SupportTicket) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "text.alignleft")
                    .foregroundStyle(.blue)
                Text("My Inquiry")
                    .font(.headline)
            }

            Text(ticket.content ?? "")
                .font(.body)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let deviceInfo = ticket.deviceInfo, !deviceInfo.isEmpty {
                Divider()

                VStack(alignment: .leading, spacing: 4) {
                    if let device = ticket.deviceInfo {
                        HStack(spacing: 6) {
                            Image(systemName: "iphone")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(device)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    if let version = ticket.appVersion {
                        HStack(spacing: 6) {
                            Image(systemName: "app.badge")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("v\(version)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }

    // MARK: - Replies Section

    private var repliesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .foregroundStyle(.green)
                Text("Replies")
                    .font(.headline)

                Spacer()

                Text("\(supportManager.currentReplies.count)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 12) {
                ForEach(supportManager.currentReplies) { reply in
                    replyCard(reply)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }

    private func replyCard(_ reply: SupportReply) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.15))
                        .frame(width: 32, height: 32)
                    Image(systemName: "headphones.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(.blue)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(reply.adminName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text(reply.formattedDate)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            Text(reply.content)
                .font(.body)
                .foregroundStyle(.primary)
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Waiting Card

    private var waitingCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock.badge.checkmark")
                .font(.system(size: 40))
                .foregroundStyle(.orange)

            Text("Waiting for Response")
                .font(.headline)

            Text("We've received your inquiry and will respond as soon as possible.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.orange.opacity(0.1))
        )
    }

    // MARK: - Helpers

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
        SupportTicketDetailView(ticketId: 1)
    }
}
