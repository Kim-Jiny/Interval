package com.jiny.interval.domain.repository

import com.jiny.interval.domain.model.Routine
import kotlinx.coroutines.flow.Flow

interface RoutineRepository {
    fun getAllRoutines(): Flow<List<Routine>>
    fun getFavoriteRoutines(): Flow<List<Routine>>
    suspend fun getRoutineById(id: String): Routine?
    suspend fun saveRoutine(routine: Routine)
    suspend fun deleteRoutine(id: String)
    suspend fun toggleFavorite(id: String)
}
