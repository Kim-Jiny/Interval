package com.jiny.interval.domain.usecase.workout

import com.jiny.interval.domain.model.WorkoutHistory
import com.jiny.interval.domain.repository.WorkoutRepository
import javax.inject.Inject

class GetWorkoutHistoryUseCase @Inject constructor(
    private val repository: WorkoutRepository
) {
    suspend operator fun invoke(year: Int, month: Int): Result<WorkoutHistory> {
        return repository.getHistory(year, month)
    }
}
