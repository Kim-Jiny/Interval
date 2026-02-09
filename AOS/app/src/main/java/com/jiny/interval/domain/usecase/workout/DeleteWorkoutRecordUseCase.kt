package com.jiny.interval.domain.usecase.workout

import com.jiny.interval.domain.repository.WorkoutRepository
import javax.inject.Inject

class DeleteWorkoutRecordUseCase @Inject constructor(
    private val repository: WorkoutRepository
) {
    suspend operator fun invoke(id: Int): Result<Unit> {
        return repository.deleteRecord(id)
    }
}
