package com.jiny.interval.domain.repository

import com.jiny.interval.domain.model.WorkoutHistory

interface WorkoutRepository {
    suspend fun getHistory(year: Int, month: Int): Result<WorkoutHistory>
    suspend fun deleteRecord(id: Int): Result<Unit>
}
