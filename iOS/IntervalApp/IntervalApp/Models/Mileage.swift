//
//  Mileage.swift
//  IntervalApp
//
//  Created by Claude on 2024.
//

import Foundation

// MARK: - Mileage Balance

struct MileageBalance: Codable, Equatable {
    let balance: Int
    let totalEarned: Int
    let totalSpent: Int

    var formattedBalance: String {
        "\(balance)M"
    }

    var formattedTotalEarned: String {
        "\(totalEarned)M"
    }

    var formattedTotalSpent: String {
        "\(totalSpent)M"
    }
}

// MARK: - Transaction Type

enum MileageTransactionType: String, Codable, CaseIterable {
    case earn = "earn"
    case spend = "spend"
    case prize = "prize"
    case refund = "refund"
    case admin = "admin"

    var displayName: String {
        switch self {
        case .earn:
            return String(localized: "Earned")
        case .spend:
            return String(localized: "Spent")
        case .prize:
            return String(localized: "Prize")
        case .refund:
            return String(localized: "Refund")
        case .admin:
            return String(localized: "Admin")
        }
    }

    var icon: String {
        switch self {
        case .earn:
            return "arrow.down.circle.fill"
        case .spend:
            return "arrow.up.circle.fill"
        case .prize:
            return "trophy.fill"
        case .refund:
            return "arrow.uturn.backward.circle.fill"
        case .admin:
            return "person.badge.key.fill"
        }
    }

    var isPositive: Bool {
        switch self {
        case .earn, .prize, .refund, .admin:
            return true
        case .spend:
            return false
        }
    }
}

// MARK: - Mileage Transaction

struct MileageTransaction: Identifiable, Codable, Equatable {
    let id: Int
    let amount: Int
    let balanceAfter: Int
    let type: MileageTransactionType
    let referenceType: String?
    let referenceId: Int?
    let description: String?
    let createdAt: String

    var formattedAmount: String {
        if amount >= 0 {
            return "+\(amount)M"
        } else {
            return "\(amount)M"
        }
    }

    var formattedBalanceAfter: String {
        "\(balanceAfter)M"
    }

    var createdDate: Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.date(from: createdAt)
    }

    var formattedDate: String {
        guard let date = createdDate else { return createdAt }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - API Response Models

struct MileageBalanceResponse: Codable {
    let success: Bool
    let mileage: MileageBalance
}

struct MileageHistoryResponse: Codable {
    let success: Bool
    let transactions: [MileageTransaction]
    let pagination: MileagePagination
}

struct MileagePagination: Codable {
    let page: Int
    let limit: Int
    let total: Int
    let totalPages: Int
}
