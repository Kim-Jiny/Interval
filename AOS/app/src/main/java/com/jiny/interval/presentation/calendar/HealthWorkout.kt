package com.jiny.interval.presentation.calendar

import java.time.Instant

data class HealthWorkout(
    val id: String,
    val startTime: Instant,
    val endTime: Instant,
    val durationSeconds: Int
)
