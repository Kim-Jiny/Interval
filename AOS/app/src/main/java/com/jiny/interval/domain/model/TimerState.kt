package com.jiny.interval.domain.model

data class TimerState(
    val isRunning: Boolean = false,
    val currentRound: Int = 1,
    val currentIntervalIndex: Int = 0,
    val timeRemaining: Int = 0,  // milliseconds
    val isCompleted: Boolean = false
)
