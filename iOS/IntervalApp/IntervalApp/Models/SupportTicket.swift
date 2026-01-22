//
//  SupportTicket.swift
//  IntervalApp
//
//  Created by Claude on 2024.
//

import Foundation

// MARK: - Ticket Category

enum TicketCategory: String, Codable, CaseIterable {
    case bug = "bug"
    case feature = "feature"
    case account = "account"
    case payment = "payment"
    case other = "other"

    var displayName: String {
        switch self {
        case .bug:
            return String(localized: "Bug Report")
        case .feature:
            return String(localized: "Feature Request")
        case .account:
            return String(localized: "Account Issue")
        case .payment:
            return String(localized: "Payment Issue")
        case .other:
            return String(localized: "Other")
        }
    }

    var icon: String {
        switch self {
        case .bug:
            return "ladybug.fill"
        case .feature:
            return "lightbulb.fill"
        case .account:
            return "person.fill"
        case .payment:
            return "creditcard.fill"
        case .other:
            return "text.bubble.fill"
        }
    }
}

// MARK: - Ticket Status

enum TicketStatus: String, Codable {
    case open = "open"
    case inProgress = "in_progress"
    case resolved = "resolved"
    case closed = "closed"

    var displayName: String {
        switch self {
        case .open:
            return String(localized: "Open")
        case .inProgress:
            return String(localized: "In Progress")
        case .resolved:
            return String(localized: "Resolved")
        case .closed:
            return String(localized: "Closed")
        }
    }

    var color: String {
        switch self {
        case .open:
            return "red"
        case .inProgress:
            return "orange"
        case .resolved:
            return "green"
        case .closed:
            return "gray"
        }
    }
}

// MARK: - Support Ticket

struct SupportTicket: Identifiable, Codable {
    let id: Int
    let category: TicketCategory
    let title: String
    let content: String?
    let deviceInfo: String?
    let appVersion: String?
    let status: TicketStatus
    let replyCount: Int?
    let hasNewReply: Bool?
    let createdAt: String
    let updatedAt: String?

    var createdDate: Date? {
        parseDate(createdAt)
    }

    var formattedDate: String {
        if let date = createdDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
        return createdAt
    }
}

// MARK: - Support Reply

struct SupportReply: Identifiable, Codable {
    let id: Int
    let adminName: String
    let content: String
    let createdAt: String

    var createdDate: Date? {
        parseDate(createdAt)
    }

    var formattedDate: String {
        if let date = createdDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
        return createdAt
    }
}

// MARK: - API Responses

struct SupportTicketListResponse: Codable {
    let success: Bool
    let tickets: [SupportTicket]
    let pagination: Pagination
}

struct SupportTicketDetailResponse: Codable {
    let success: Bool
    let ticket: SupportTicket
    let replies: [SupportReply]
}

struct SupportTicketCreateResponse: Codable {
    let success: Bool
    let message: String
    let ticket: SupportTicket
}
