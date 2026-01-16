package com.jiny.interval.domain.model

import java.util.UUID

data class WorkoutInterval(
    val id: String = UUID.randomUUID().toString(),
    val name: String,
    val duration: Int,  // seconds
    val type: IntervalType
)
