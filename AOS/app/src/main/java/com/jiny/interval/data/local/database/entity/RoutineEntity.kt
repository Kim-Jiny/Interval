package com.jiny.interval.data.local.database.entity

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "routines")
data class RoutineEntity(
    @PrimaryKey val id: String,
    val name: String,
    val rounds: Int,
    val createdAt: Long,
    val updatedAt: Long,
    val isFavorite: Boolean
)
