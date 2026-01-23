package com.jiny.interval.domain.model

import java.text.NumberFormat
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Mileage Balance
 */
data class MileageBalance(
    val balance: Int,
    val totalEarned: Int,
    val totalSpent: Int
) {
    val formattedBalance: String
        get() = "${formatNumber(balance)}M"

    val formattedTotalEarned: String
        get() = "${formatNumber(totalEarned)}M"

    val formattedTotalSpent: String
        get() = "${formatNumber(totalSpent)}M"

    companion object {
        val EMPTY = MileageBalance(0, 0, 0)
    }
}

/**
 * Mileage Transaction Type
 */
enum class MileageTransactionType(val value: String) {
    EARN("earn"),
    SPEND("spend"),
    PRIZE("prize"),
    REFUND("refund"),
    ADMIN("admin");

    val isPositive: Boolean
        get() = this != SPEND

    companion object {
        fun fromValue(value: String): MileageTransactionType {
            return entries.find { it.value == value } ?: ADMIN
        }
    }
}

/**
 * Mileage Transaction
 */
data class MileageTransaction(
    val id: Int,
    val amount: Int,
    val balanceAfter: Int,
    val type: MileageTransactionType,
    val referenceType: String?,
    val referenceId: Int?,
    val description: String?,
    val createdAt: String
) {
    val formattedAmount: String
        get() = if (amount >= 0) "+${formatNumber(amount)}M" else "${formatNumber(amount)}M"

    val formattedBalanceAfter: String
        get() = "${formatNumber(balanceAfter)}M"

    val createdDate: Date?
        get() {
            val formats = listOf(
                SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.getDefault()),
                SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.getDefault())
            )
            for (format in formats) {
                try {
                    return format.parse(createdAt)
                } catch (e: Exception) {
                    // Try next format
                }
            }
            return null
        }

    val formattedDate: String
        get() {
            val date = createdDate ?: return createdAt
            val formatter = SimpleDateFormat("yyyy.MM.dd HH:mm", Locale.getDefault())
            return formatter.format(date)
        }
}

private fun formatNumber(value: Int): String {
    return NumberFormat.getNumberInstance(Locale.getDefault()).format(value)
}
