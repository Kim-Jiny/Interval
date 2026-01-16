package com.jiny.interval.wear.domain.model

data class WearRoutine(
    val id: String,
    val name: String,
    val intervals: List<WearInterval>,
    val rounds: Int
)

data class WearInterval(
    val id: String,
    val name: String,
    val duration: Int,
    val type: String
)

data class WearTimerState(
    val isRunning: Boolean = false,
    val currentRound: Int = 1,
    val currentIntervalIndex: Int = 0,
    val timeRemaining: Int = 0,
    val isCompleted: Boolean = false
)
