package com.jiny.interval.data.mapper

import com.jiny.interval.data.local.database.entity.IntervalEntity
import com.jiny.interval.data.local.database.entity.RoutineEntity
import com.jiny.interval.data.local.database.entity.RoutineWithIntervals
import com.jiny.interval.domain.model.IntervalType
import com.jiny.interval.domain.model.Routine
import com.jiny.interval.domain.model.WorkoutInterval

fun RoutineWithIntervals.toDomain(): Routine {
    return Routine(
        id = routine.id,
        name = routine.name,
        intervals = intervals
            .sortedBy { it.orderIndex }
            .map { it.toDomain() },
        rounds = routine.rounds,
        createdAt = routine.createdAt,
        updatedAt = routine.updatedAt,
        isFavorite = routine.isFavorite
    )
}

fun IntervalEntity.toDomain(): WorkoutInterval {
    return WorkoutInterval(
        id = id,
        name = name,
        duration = duration,
        type = IntervalType.valueOf(type)
    )
}

fun Routine.toEntity(): RoutineEntity {
    return RoutineEntity(
        id = id,
        name = name,
        rounds = rounds,
        createdAt = createdAt,
        updatedAt = updatedAt,
        isFavorite = isFavorite
    )
}

fun WorkoutInterval.toEntity(routineId: String, orderIndex: Int): IntervalEntity {
    return IntervalEntity(
        id = id,
        routineId = routineId,
        name = name,
        duration = duration,
        type = type.name,
        orderIndex = orderIndex
    )
}

fun Routine.toIntervalEntities(): List<IntervalEntity> {
    return intervals.mapIndexed { index, interval ->
        interval.toEntity(id, index)
    }
}
