package com.jiny.interval.data.remote.api

import com.jiny.interval.data.remote.dto.SimpleResponse
import com.jiny.interval.data.remote.dto.WorkoutHistoryResponse
import retrofit2.Response
import retrofit2.http.DELETE
import retrofit2.http.GET
import retrofit2.http.Query

interface WorkoutApi {

    @GET("workouts/history.php")
    suspend fun getHistory(
        @Query("year") year: Int,
        @Query("month") month: Int
    ): Response<WorkoutHistoryResponse>

    @DELETE("workouts/delete.php")
    suspend fun deleteRecord(
        @Query("id") id: Int
    ): Response<SimpleResponse>
}
