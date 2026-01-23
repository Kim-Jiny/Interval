package com.jiny.interval.data.remote.api

import com.jiny.interval.data.remote.dto.ChallengeCreateRequest
import com.jiny.interval.data.remote.dto.ChallengeCreateResponse
import com.jiny.interval.data.remote.dto.ChallengeDetailResponse
import com.jiny.interval.data.remote.dto.ChallengeJoinRequest
import com.jiny.interval.data.remote.dto.ChallengeJoinResponse
import com.jiny.interval.data.remote.dto.ChallengeLeaveRequest
import com.jiny.interval.data.remote.dto.ChallengeLeaveResponse
import com.jiny.interval.data.remote.dto.ChallengeListResponse
import com.jiny.interval.data.remote.dto.SimpleResponse
import retrofit2.Response
import retrofit2.http.Body
import retrofit2.http.GET
import retrofit2.http.POST
import retrofit2.http.Query

/**
 * Challenge API interface for Retrofit
 */
interface ChallengeApi {

    /**
     * Get list of joinable challenges
     */
    @GET("challenges/list.php")
    suspend fun getJoinableChallenges(
        @Query("page") page: Int = 1,
        @Query("type") type: String = "joinable"
    ): Response<ChallengeListResponse>

    /**
     * Get my challenges
     */
    @GET("challenges/my.php")
    suspend fun getMyChallenges(
        @Query("type") type: String = "all"
    ): Response<ChallengeListResponse>

    /**
     * Get challenge by share code
     */
    @GET("challenges/get.php")
    suspend fun getChallengeByCode(
        @Query("code") code: String
    ): Response<ChallengeDetailResponse>

    /**
     * Get challenge detail by ID
     */
    @GET("challenges/detail.php")
    suspend fun getChallengeDetail(
        @Query("id") id: Int
    ): Response<ChallengeDetailResponse>

    /**
     * Create a new challenge
     */
    @POST("challenges/create.php")
    suspend fun createChallenge(
        @Body request: ChallengeCreateRequest
    ): Response<ChallengeCreateResponse>

    /**
     * Join a challenge
     */
    @POST("challenges/join.php")
    suspend fun joinChallenge(
        @Body request: ChallengeJoinRequest
    ): Response<ChallengeJoinResponse>

    /**
     * Leave a challenge
     */
    @POST("challenges/leave.php")
    suspend fun leaveChallenge(
        @Body request: ChallengeLeaveRequest
    ): Response<ChallengeLeaveResponse>

    /**
     * Record workout for challenge
     */
    @POST("challenges/record-workout.php")
    suspend fun recordWorkout(
        @Body request: RecordWorkoutRequest
    ): Response<SimpleResponse>
}

data class RecordWorkoutRequest(
    val challengeId: Int,
    val totalDuration: Int,
    val roundsCompleted: Int
)
