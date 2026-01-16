package com.jiny.interval.data.local.database.entity

import androidx.room.Embedded
import androidx.room.Relation

data class RoutineWithIntervals(
    @Embedded val routine: RoutineEntity,
    @Relation(
        parentColumn = "id",
        entityColumn = "routineId"
    )
    val intervals: List<IntervalEntity>
)
