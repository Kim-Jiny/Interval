package com.jiny.interval.data.repository

import com.jiny.interval.data.mapper.toDomain
import com.jiny.interval.data.remote.api.WorkoutApi
import com.jiny.interval.domain.model.WorkoutHistory
import com.jiny.interval.domain.repository.WorkoutRepository
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class WorkoutRepositoryImpl @Inject constructor(
    private val workoutApi: WorkoutApi
) : WorkoutRepository {

    override suspend fun getHistory(year: Int, month: Int): Result<WorkoutHistory> {
        return try {
            val response = workoutApi.getHistory(year, month)
            if (response.isSuccessful && response.body()?.success == true) {
                val body = response.body()!!
                val records = body.records?.map { it.toDomain() } ?: emptyList()
                val workoutDays = body.workoutDays ?: records.map { it.workoutDate }.toSet().size
                val totalWorkouts = body.totalWorkouts ?: records.size
                Result.success(
                    WorkoutHistory(
                        year = body.year ?: year,
                        month = body.month ?: month,
                        records = records,
                        totalWorkouts = totalWorkouts,
                        workoutDays = workoutDays
                    )
                )
            } else {
                Result.failure(Exception(bodyError(response.body()?.error, "Failed to load history")))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun deleteRecord(id: Int): Result<Unit> {
        return try {
            val response = workoutApi.deleteRecord(id)
            if (response.isSuccessful && response.body()?.success == true) {
                Result.success(Unit)
            } else {
                Result.failure(Exception(bodyError(response.body()?.error, "Failed to delete record")))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    private fun bodyError(error: String?, fallback: String): String {
        return if (error.isNullOrBlank()) fallback else error
    }
}
