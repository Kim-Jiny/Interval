package com.jiny.interval.domain.usecase.routine

import com.jiny.interval.domain.repository.RoutineRepository
import javax.inject.Inject

class DeleteRoutineUseCase @Inject constructor(
    private val repository: RoutineRepository
) {
    suspend operator fun invoke(id: String) = repository.deleteRoutine(id)
}
