package com.jiny.interval.domain.usecase.routine

import com.jiny.interval.domain.model.Routine
import com.jiny.interval.domain.repository.RoutineRepository
import kotlinx.coroutines.flow.Flow
import javax.inject.Inject

class GetFavoriteRoutinesUseCase @Inject constructor(
    private val repository: RoutineRepository
) {
    operator fun invoke(): Flow<List<Routine>> = repository.getFavoriteRoutines()
}
