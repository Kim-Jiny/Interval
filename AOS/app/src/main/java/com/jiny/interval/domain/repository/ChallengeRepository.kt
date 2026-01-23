package com.jiny.interval.domain.repository

import com.jiny.interval.domain.model.Challenge
import com.jiny.interval.domain.model.ChallengeListItem
import com.jiny.interval.domain.model.ChallengeParticipant

/**
 * Repository interface for challenge operations
 */
interface ChallengeRepository {

    /**
     * Get list of joinable challenges
     */
    suspend fun getJoinableChallenges(page: Int = 1): Result<List<ChallengeListItem>>

    /**
     * Get my challenges
     */
    suspend fun getMyChallenges(): Result<List<ChallengeListItem>>

    /**
     * Get challenge by share code
     */
    suspend fun getChallengeByCode(code: String): Result<Pair<Challenge, List<ChallengeParticipant>>>

    /**
     * Get challenge detail
     */
    suspend fun getChallengeDetail(id: Int): Result<Pair<Challenge, List<ChallengeParticipant>>>

    /**
     * Join a challenge
     */
    suspend fun joinChallenge(challengeId: Int): Result<Int> // Returns entry fee paid

    /**
     * Leave a challenge
     */
    suspend fun leaveChallenge(challengeId: Int): Result<Int> // Returns refunded amount

    /**
     * Record workout for challenge
     */
    suspend fun recordWorkout(challengeId: Int, totalDuration: Int, roundsCompleted: Int): Result<Unit>

    /**
     * Create a new challenge
     */
    suspend fun createChallenge(
        title: String,
        description: String?,
        routineName: String,
        routineIntervals: List<ChallengeRoutineInterval>,
        routineRounds: Int,
        registrationEndAt: String,
        challengeStartAt: String,
        challengeEndAt: String,
        entryFee: Int,
        isPublic: Boolean,
        maxParticipants: Int?
    ): Result<String> // Returns share URL
}

data class ChallengeRoutineInterval(
    val name: String,
    val duration: Int,
    val type: String
)
