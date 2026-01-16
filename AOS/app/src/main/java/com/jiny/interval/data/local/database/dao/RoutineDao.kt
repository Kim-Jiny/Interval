package com.jiny.interval.data.local.database.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Transaction
import com.jiny.interval.data.local.database.entity.IntervalEntity
import com.jiny.interval.data.local.database.entity.RoutineEntity
import com.jiny.interval.data.local.database.entity.RoutineWithIntervals
import kotlinx.coroutines.flow.Flow

@Dao
interface RoutineDao {

    @Transaction
    @Query("SELECT * FROM routines ORDER BY updatedAt DESC")
    fun getAllRoutines(): Flow<List<RoutineWithIntervals>>

    @Transaction
    @Query("SELECT * FROM routines WHERE isFavorite = 1 ORDER BY updatedAt DESC")
    fun getFavoriteRoutines(): Flow<List<RoutineWithIntervals>>

    @Transaction
    @Query("SELECT * FROM routines WHERE id = :id")
    suspend fun getRoutineById(id: String): RoutineWithIntervals?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertRoutine(routine: RoutineEntity)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertIntervals(intervals: List<IntervalEntity>)

    @Query("DELETE FROM intervals WHERE routineId = :routineId")
    suspend fun deleteIntervalsByRoutineId(routineId: String)

    @Query("DELETE FROM routines WHERE id = :id")
    suspend fun deleteRoutine(id: String)

    @Query("UPDATE routines SET isFavorite = NOT isFavorite, updatedAt = :updatedAt WHERE id = :id")
    suspend fun toggleFavorite(id: String, updatedAt: Long = System.currentTimeMillis())

    @Transaction
    suspend fun saveRoutineWithIntervals(routine: RoutineEntity, intervals: List<IntervalEntity>) {
        deleteIntervalsByRoutineId(routine.id)
        insertRoutine(routine)
        insertIntervals(intervals)
    }
}
