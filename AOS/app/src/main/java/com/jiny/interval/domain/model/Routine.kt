package com.jiny.interval.domain.model

import java.util.UUID

data class Routine(
    val id: String = UUID.randomUUID().toString(),
    val name: String,
    val intervals: List<WorkoutInterval>,
    val rounds: Int,
    val createdAt: Long = System.currentTimeMillis(),
    val updatedAt: Long = System.currentTimeMillis(),
    val isFavorite: Boolean = false
) {
    val totalDuration: Int
        get() = intervals.sumOf { it.duration } * rounds
}
