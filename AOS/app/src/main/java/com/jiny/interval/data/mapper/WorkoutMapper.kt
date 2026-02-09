package com.jiny.interval.data.mapper

import com.jiny.interval.data.remote.dto.WorkoutRecordDto
import com.jiny.interval.domain.model.WorkoutRecord

fun WorkoutRecordDto.toDomain(): WorkoutRecord {
    return WorkoutRecord(
        id = id,
        routineName = routineName,
        totalDuration = totalDuration,
        roundsCompleted = roundsCompleted,
        workoutDate = workoutDate,
        createdAt = createdAt
    )
}
