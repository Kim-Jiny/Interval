package com.jiny.interval.domain.model

data class WorkoutRecord(
    val id: Int,
    val routineName: String,
    val totalDuration: Int,
    val roundsCompleted: Int,
    val workoutDate: String,
    val createdAt: String?
)

data class WorkoutHistory(
    val year: Int,
    val month: Int,
    val records: List<WorkoutRecord>,
    val totalWorkouts: Int,
    val workoutDays: Int
)
