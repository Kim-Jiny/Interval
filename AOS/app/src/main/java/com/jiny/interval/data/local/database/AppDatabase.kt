package com.jiny.interval.data.local.database

import androidx.room.Database
import androidx.room.RoomDatabase
import com.jiny.interval.data.local.database.dao.RoutineDao
import com.jiny.interval.data.local.database.entity.IntervalEntity
import com.jiny.interval.data.local.database.entity.RoutineEntity

@Database(
    entities = [RoutineEntity::class, IntervalEntity::class],
    version = 1,
    exportSchema = false
)
abstract class AppDatabase : RoomDatabase() {
    abstract fun routineDao(): RoutineDao
}
