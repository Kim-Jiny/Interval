package com.jiny.interval.data.local.database.entity

import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.PrimaryKey

@Entity(
    tableName = "intervals",
    foreignKeys = [
        ForeignKey(
            entity = RoutineEntity::class,
            parentColumns = ["id"],
            childColumns = ["routineId"],
            onDelete = ForeignKey.CASCADE
        )
    ],
    indices = [Index("routineId")]
)
data class IntervalEntity(
    @PrimaryKey val id: String,
    val routineId: String,
    val name: String,
    val duration: Int,
    val type: String,
    val orderIndex: Int
)
