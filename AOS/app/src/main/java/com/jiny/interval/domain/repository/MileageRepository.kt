package com.jiny.interval.domain.repository

import com.jiny.interval.domain.model.MileageBalance
import com.jiny.interval.domain.model.MileageTransaction
import kotlinx.coroutines.flow.Flow

/**
 * Repository interface for mileage operations
 */
interface MileageRepository {

    /**
     * Current mileage balance as Flow
     */
    val balance: Flow<MileageBalance>

    /**
     * Fetch mileage balance from server
     */
    suspend fun fetchBalance(): Result<MileageBalance>

    /**
     * Get transaction history
     */
    suspend fun getHistory(page: Int = 1, limit: Int = 20): Result<List<MileageTransaction>>
}
