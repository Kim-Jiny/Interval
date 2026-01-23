package com.jiny.interval.data.repository

import android.util.Log
import com.jiny.interval.data.mapper.toDomain
import com.jiny.interval.data.remote.api.ChallengeApi
import com.jiny.interval.data.remote.api.RecordWorkoutRequest
import com.jiny.interval.data.remote.dto.ChallengeCreateRequest
import com.jiny.interval.data.remote.dto.ChallengeIntervalDto
import com.jiny.interval.data.remote.dto.ChallengeJoinRequest
import com.jiny.interval.data.remote.dto.ChallengeLeaveRequest
import com.jiny.interval.data.remote.dto.RoutineDataDto
import com.jiny.interval.domain.model.Challenge
import com.jiny.interval.domain.model.ChallengeListItem
import com.jiny.interval.domain.model.ChallengeParticipant
import com.jiny.interval.domain.repository.ChallengeRepository
import com.jiny.interval.domain.repository.ChallengeRoutineInterval
import javax.inject.Inject
import javax.inject.Singleton

private const val TAG = "ChallengeRepository"

@Singleton
class ChallengeRepositoryImpl @Inject constructor(
    private val challengeApi: ChallengeApi
) : ChallengeRepository {

    override suspend fun getJoinableChallenges(page: Int): Result<List<ChallengeListItem>> {
        return try {
            val response = challengeApi.getJoinableChallenges(page = page)
            if (response.isSuccessful && response.body()?.success == true) {
                val challenges = response.body()?.challenges?.map { it.toDomain() } ?: emptyList()
                Result.success(challenges)
            } else {
                val error = response.body()?.error ?: "Failed to get challenges"
                Result.failure(Exception(error))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun getMyChallenges(): Result<List<ChallengeListItem>> {
        return try {
            Log.d(TAG, "getMyChallenges: Calling API...")
            val response = challengeApi.getMyChallenges()
            val code = response.code()
            val body = response.body()
            val errorBodyStr = response.errorBody()?.string()

            Log.d(TAG, "getMyChallenges: Response code=$code, isSuccessful=${response.isSuccessful}")
            Log.d(TAG, "getMyChallenges: Body success=${body?.success}, error=${body?.error}, challenges count=${body?.challenges?.size}")
            Log.d(TAG, "getMyChallenges: Error body=$errorBodyStr")

            if (response.isSuccessful && body?.success == true) {
                val challenges = body.challenges?.map { it.toDomain() } ?: emptyList()
                Log.d(TAG, "getMyChallenges: Success, parsed ${challenges.size} challenges")
                Result.success(challenges)
            } else {
                val error = body?.error ?: errorBodyStr ?: "Failed to get my challenges (code=$code)"
                Log.e(TAG, "getMyChallenges: Failed with error: $error")
                Result.failure(Exception(error))
            }
        } catch (e: Exception) {
            Log.e(TAG, "getMyChallenges: Exception", e)
            Result.failure(e)
        }
    }

    override suspend fun getChallengeByCode(code: String): Result<Pair<Challenge, List<ChallengeParticipant>>> {
        return try {
            val response = challengeApi.getChallengeByCode(code)
            if (response.isSuccessful && response.body()?.success == true) {
                val body = response.body()!!
                val challengeDto = body.challenge
                if (challengeDto == null) {
                    return Result.failure(Exception("Challenge not found"))
                }
                val challenge = challengeDto.toDomain()
                val participants = body.participants?.map { it.toDomain() } ?: emptyList()
                Result.success(Pair(challenge, participants))
            } else {
                val error = response.body()?.error ?: "Challenge not found"
                Result.failure(Exception(error))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun getChallengeDetail(id: Int): Result<Pair<Challenge, List<ChallengeParticipant>>> {
        return try {
            val response = challengeApi.getChallengeDetail(id)
            if (response.isSuccessful && response.body()?.success == true) {
                val body = response.body()!!
                val challengeDto = body.challenge
                if (challengeDto == null) {
                    return Result.failure(Exception("Challenge not found"))
                }
                val challenge = challengeDto.toDomain()
                val participants = body.participants?.map { it.toDomain() } ?: emptyList()
                Result.success(Pair(challenge, participants))
            } else {
                val error = response.body()?.error ?: "Challenge not found"
                Result.failure(Exception(error))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun joinChallenge(challengeId: Int): Result<Int> {
        return try {
            val response = challengeApi.joinChallenge(ChallengeJoinRequest(challengeId))
            if (response.isSuccessful && response.body()?.success == true) {
                val entryFeePaid = response.body()!!.entryFeePaid ?: 0
                Result.success(entryFeePaid)
            } else {
                val error = response.body()?.error ?: "Failed to join challenge"
                Result.failure(Exception(error))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun leaveChallenge(challengeId: Int): Result<Int> {
        return try {
            val response = challengeApi.leaveChallenge(ChallengeLeaveRequest(challengeId))
            if (response.isSuccessful && response.body()?.success == true) {
                val refundedAmount = response.body()!!.refundedAmount ?: 0
                Result.success(refundedAmount)
            } else {
                val error = response.body()?.error ?: "Failed to leave challenge"
                Result.failure(Exception(error))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun recordWorkout(
        challengeId: Int,
        totalDuration: Int,
        roundsCompleted: Int
    ): Result<Unit> {
        return try {
            val response = challengeApi.recordWorkout(
                RecordWorkoutRequest(challengeId, totalDuration, roundsCompleted)
            )
            if (response.isSuccessful && response.body()?.success == true) {
                Result.success(Unit)
            } else {
                Result.failure(Exception("Failed to record workout"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun createChallenge(
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
    ): Result<String> {
        return try {
            val routineData = RoutineDataDto(
                intervals = routineIntervals.map { interval ->
                    ChallengeIntervalDto(
                        name = interval.name,
                        duration = interval.duration,
                        type = interval.type
                    )
                },
                rounds = routineRounds
            )

            val request = ChallengeCreateRequest(
                title = title,
                description = description,
                routineName = routineName,
                routineData = routineData,
                registrationEndAt = registrationEndAt,
                challengeStartAt = challengeStartAt,
                challengeEndAt = challengeEndAt,
                entryFee = entryFee,
                isPublic = isPublic,
                maxParticipants = maxParticipants
            )

            val response = challengeApi.createChallenge(request)
            if (response.isSuccessful && response.body()?.success == true) {
                val shareUrl = response.body()!!.shareUrl ?: ""
                Result.success(shareUrl)
            } else {
                val error = response.body()?.error ?: "Failed to create challenge"
                Result.failure(Exception(error))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}
