package com.jiny.interval.domain.usecase.routine

import com.jiny.interval.domain.model.Routine
import com.jiny.interval.domain.repository.RoutineRepository
import javax.inject.Inject

class GetRoutineByIdUseCase @Inject constructor(
    private val repository: RoutineRepository
) {
    suspend operator fun invoke(id: String): Routine? = repository.getRoutineById(id)
}
