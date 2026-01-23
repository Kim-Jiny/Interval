package com.jiny.interval.data.remote.api

import com.jiny.interval.data.remote.dto.MileageBalanceResponse
import com.jiny.interval.data.remote.dto.MileageHistoryResponse
import retrofit2.Response
import retrofit2.http.GET
import retrofit2.http.Query

/**
 * Mileage API interface for Retrofit
 */
interface MileageApi {

    /**
     * Get mileage balance
     */
    @GET("mileage/balance.php")
    suspend fun getBalance(): Response<MileageBalanceResponse>

    /**
     * Get mileage transaction history
     */
    @GET("mileage/history.php")
    suspend fun getHistory(
        @Query("page") page: Int = 1,
        @Query("limit") limit: Int = 20
    ): Response<MileageHistoryResponse>
}
