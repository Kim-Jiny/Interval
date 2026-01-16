package com.jiny.interval.domain.usecase.routine

import com.jiny.interval.domain.model.Routine
import com.jiny.interval.domain.repository.RoutineRepository
import javax.inject.Inject

class SaveRoutineUseCase @Inject constructor(
    private val repository: RoutineRepository
) {
    suspend operator fun invoke(routine: Routine) = repository.saveRoutine(routine)
}
