package com.jiny.interval.data.repository

import com.jiny.interval.data.local.database.dao.RoutineDao
import com.jiny.interval.data.mapper.toDomain
import com.jiny.interval.data.mapper.toEntity
import com.jiny.interval.data.mapper.toIntervalEntities
import com.jiny.interval.domain.model.Routine
import com.jiny.interval.domain.repository.RoutineRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import javax.inject.Inject

class RoutineRepositoryImpl @Inject constructor(
    private val routineDao: RoutineDao
) : RoutineRepository {

    override fun getAllRoutines(): Flow<List<Routine>> {
        return routineDao.getAllRoutines().map { list ->
            list.map { it.toDomain() }
        }
    }

    override fun getFavoriteRoutines(): Flow<List<Routine>> {
        return routineDao.getFavoriteRoutines().map { list ->
            list.map { it.toDomain() }
        }
    }

    override suspend fun getRoutineById(id: String): Routine? {
        return routineDao.getRoutineById(id)?.toDomain()
    }

    override suspend fun getRoutineCount(): Int {
        return routineDao.getRoutineCount()
    }

    override suspend fun saveRoutine(routine: Routine) {
        val updatedRoutine = routine.copy(updatedAt = System.currentTimeMillis())
        routineDao.saveRoutineWithIntervals(
            updatedRoutine.toEntity(),
            updatedRoutine.toIntervalEntities()
        )
    }

    override suspend fun deleteRoutine(id: String) {
        routineDao.deleteRoutine(id)
    }

    override suspend fun toggleFavorite(id: String) {
        routineDao.toggleFavorite(id)
    }
}
