package com.jiny.interval.wear.presentation.timer

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.jiny.interval.wear.domain.model.WearInterval
import com.jiny.interval.wear.domain.model.WearRoutine
import com.jiny.interval.wear.domain.model.WearTimerState
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import java.util.UUID
import javax.inject.Inject

@HiltViewModel
class WearTimerViewModel @Inject constructor() : ViewModel() {

    private val _routine = MutableStateFlow<WearRoutine?>(null)
    val routine: StateFlow<WearRoutine?> = _routine.asStateFlow()

    private val _timerState = MutableStateFlow(WearTimerState())
    val timerState: StateFlow<WearTimerState> = _timerState.asStateFlow()

    private var timerJob: Job? = null

    private val defaultRoutines = listOf(
        WearRoutine(
            id = UUID.randomUUID().toString(),
            name = "Tabata",
            intervals = listOf(
                WearInterval(UUID.randomUUID().toString(), "Work", 20, "WORKOUT"),
                WearInterval(UUID.randomUUID().toString(), "Rest", 10, "REST")
            ),
            rounds = 8
        ),
        WearRoutine(
            id = UUID.randomUUID().toString(),
            name = "HIIT",
            intervals = listOf(
                WearInterval(UUID.randomUUID().toString(), "Warmup", 60, "WARMUP"),
                WearInterval(UUID.randomUUID().toString(), "Work", 30, "WORKOUT"),
                WearInterval(UUID.randomUUID().toString(), "Rest", 15, "REST"),
                WearInterval(UUID.randomUUID().toString(), "Cooldown", 60, "COOLDOWN")
            ),
            rounds = 4
        ),
        WearRoutine(
            id = UUID.randomUUID().toString(),
            name = "Quick Workout",
            intervals = listOf(
                WearInterval(UUID.randomUUID().toString(), "Exercise", 45, "WORKOUT"),
                WearInterval(UUID.randomUUID().toString(), "Rest", 15, "REST")
            ),
            rounds = 5
        )
    )

    fun loadRoutine(index: Int) {
        val routine = defaultRoutines.getOrNull(index) ?: return
        _routine.value = routine
        initializeTimer(routine)
    }

    private fun initializeTimer(routine: WearRoutine) {
        val firstInterval = routine.intervals.firstOrNull() ?: return
        _timerState.update {
            WearTimerState(
                isRunning = false,
                currentRound = 1,
                currentIntervalIndex = 0,
                timeRemaining = firstInterval.duration * 1000,
                isCompleted = false
            )
        }
    }

    fun toggleTimer() {
        val currentState = _timerState.value
        if (currentState.isRunning) {
            pauseTimer()
        } else {
            startTimer()
        }
    }

    private fun startTimer() {
        _timerState.update { it.copy(isRunning = true) }
        timerJob?.cancel()
        timerJob = viewModelScope.launch {
            while (_timerState.value.isRunning && !_timerState.value.isCompleted) {
                delay(100)
                tick()
            }
        }
    }

    private fun pauseTimer() {
        _timerState.update { it.copy(isRunning = false) }
        timerJob?.cancel()
    }

    private fun tick() {
        val routine = _routine.value ?: return
        val state = _timerState.value

        if (state.timeRemaining <= 0) {
            moveToNextInterval(routine)
        } else {
            _timerState.update { it.copy(timeRemaining = it.timeRemaining - 100) }
        }
    }

    private fun moveToNextInterval(routine: WearRoutine) {
        val state = _timerState.value
        val nextIntervalIndex = state.currentIntervalIndex + 1

        if (nextIntervalIndex >= routine.intervals.size) {
            val nextRound = state.currentRound + 1
            if (nextRound > routine.rounds) {
                _timerState.update {
                    it.copy(
                        isRunning = false,
                        isCompleted = true,
                        timeRemaining = 0
                    )
                }
                return
            } else {
                val firstInterval = routine.intervals.first()
                _timerState.update {
                    it.copy(
                        currentRound = nextRound,
                        currentIntervalIndex = 0,
                        timeRemaining = firstInterval.duration * 1000
                    )
                }
            }
        } else {
            val nextInterval = routine.intervals[nextIntervalIndex]
            _timerState.update {
                it.copy(
                    currentIntervalIndex = nextIntervalIndex,
                    timeRemaining = nextInterval.duration * 1000
                )
            }
        }
    }

    override fun onCleared() {
        super.onCleared()
        timerJob?.cancel()
    }
}
