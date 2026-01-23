package com.jiny.interval.data.remote.dto

import com.google.gson.annotations.SerializedName

/**
 * Mileage Balance Response
 */
data class MileageBalanceResponse(
    @SerializedName("success") val success: Boolean?,
    @SerializedName("mileage") val mileage: MileageBalanceDto?,
    @SerializedName("data") val data: MileageBalanceDto?
)

/**
 * Mileage Balance DTO
 */
data class MileageBalanceDto(
    @SerializedName("balance") val balance: Int?,
    @SerializedName("totalEarned") val totalEarned: Int?,
    @SerializedName("totalSpent") val totalSpent: Int?,
    @SerializedName("total_earned") val totalEarnedSnake: Int?,
    @SerializedName("total_spent") val totalSpentSnake: Int?
)

/**
 * Mileage History Response
 */
data class MileageHistoryResponse(
    @SerializedName("success") val success: Boolean?,
    @SerializedName("transactions") val transactions: List<MileageTransactionDto>?,
    @SerializedName("data") val data: List<MileageTransactionDto>?,
    @SerializedName("pagination") val pagination: PaginationDto?
)

/**
 * Mileage Transaction DTO
 */
data class MileageTransactionDto(
    @SerializedName("id") val id: Int?,
    @SerializedName("amount") val amount: Int?,
    @SerializedName("balanceAfter") val balanceAfter: Int?,
    @SerializedName("balance_after") val balanceAfterSnake: Int?,
    @SerializedName("transaction_type") val type: String?,
    @SerializedName("referenceType") val referenceType: String?,
    @SerializedName("reference_type") val referenceTypeSnake: String?,
    @SerializedName("referenceId") val referenceId: Int?,
    @SerializedName("reference_id") val referenceIdSnake: Int?,
    @SerializedName("description") val description: String?,
    @SerializedName("createdAt") val createdAt: String?,
    @SerializedName("created_at") val createdAtSnake: String?
)
