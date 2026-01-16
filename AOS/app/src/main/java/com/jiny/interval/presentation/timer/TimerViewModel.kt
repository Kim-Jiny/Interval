package com.jiny.interval.presentation.timer

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.os.IBinder
import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.jiny.interval.domain.model.Routine
import com.jiny.interval.domain.model.Settings
import com.jiny.interval.domain.model.TimerState
import com.jiny.interval.domain.model.WorkoutInterval
import com.jiny.interval.domain.usecase.routine.GetRoutineByIdUseCase
import com.jiny.interval.domain.usecase.settings.GetSettingsUseCase
import com.jiny.interval.service.TimerService
import dagger.hilt.android.lifecycle.HiltViewModel
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class TimerViewModel @Inject constructor(
    savedStateHandle: SavedStateHandle,
    private val getRoutineByIdUseCase: GetRoutineByIdUseCase,
    private val getSettingsUseCase: GetSettingsUseCase,
    @ApplicationContext private val context: Context
) : ViewModel() {

    private val routineId: String = checkNotNull(savedStateHandle["routineId"])

    private val _routine = MutableStateFlow<Routine?>(null)
    val routine: StateFlow<Routine?> = _routine.asStateFlow()

    private val _timerState = MutableStateFlow(TimerState())
    val timerState: StateFlow<TimerState> = _timerState.asStateFlow()

    val settings: StateFlow<Settings> = getSettingsUseCase()
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5000),
            initialValue = Settings()
        )

    private var timerJob: Job? = null
    private var timerService: TimerService? = null
    private var serviceBound = false
    private var pendingStart = false
    private var tickCount = 0

    private val serviceConnection = object : ServiceConnection {
        override fun onServiceConnected(name: ComponentName?, service: IBinder?) {
            val binder = service as TimerService.TimerBinder
            timerService = binder.getService()
            serviceBound = true
            // If timer start was requested before service was bound
            if (pendingStart) {
                pendingStart = false
                updateServiceNotification()
            }
        }

        override fun onServiceDisconnected(name: ComponentName?) {
            timerService = null
            serviceBound = false
        }
    }

    init {
        loadRoutine()
        bindService()
    }

    private fun loadRoutine() {
        viewModelScope.launch {
            val routine = getRoutineByIdUseCase(routineId)
            _routine.value = routine
            routine?.let { initializeTimer(it) }
        }
    }

    private fun initializeTimer(routine: Routine) {
        val firstInterval = routine.intervals.firstOrNull() ?: return
        _timerState.update {
            TimerState(
                isRunning = false,
                currentRound = 1,
                currentIntervalIndex = 0,
                timeRemaining = firstInterval.duration * 1000,
                isCompleted = false
            )
        }
    }

    private fun bindService() {
        Intent(context, TimerService::class.java).also { intent ->
            context.bindService(intent, serviceConnection, Context.BIND_AUTO_CREATE)
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

    fun startTimer() {
        _timerState.update { it.copy(isRunning = true) }
        startForegroundService()
        pendingStart = !serviceBound
        tickCount = 0
        timerJob?.cancel()
        timerJob = viewModelScope.launch {
            // Initial notification update
            updateServiceNotification()
            while (_timerState.value.isRunning && !_timerState.value.isCompleted) {
                delay(100)
                tick()
            }
        }
    }

    fun pauseTimer() {
        _timerState.update { it.copy(isRunning = false) }
        timerJob?.cancel()
        updateServiceNotification()
    }

    private fun tick() {
        val routine = _routine.value ?: return
        val state = _timerState.value

        if (state.timeRemaining <= 0) {
            moveToNextInterval(routine)
        } else {
            _timerState.update { it.copy(timeRemaining = it.timeRemaining - 100) }
            tickCount++
            // Update notification once per second (every 10 ticks)
            if (tickCount >= 10) {
                tickCount = 0
                updateServiceNotification()
            }
        }
    }

    private fun updateServiceNotification() {
        timerService?.updateNotification(_timerState.value, getCurrentInterval())
    }

    private fun moveToNextInterval(routine: Routine) {
        val state = _timerState.value
        val nextIntervalIndex = state.currentIntervalIndex + 1

        if (nextIntervalIndex >= routine.intervals.size) {
            // Move to next round
            val nextRound = state.currentRound + 1
            if (nextRound > routine.rounds) {
                // Workout completed
                _timerState.update {
                    it.copy(
                        isRunning = false,
                        isCompleted = true,
                        timeRemaining = 0
                    )
                }
                stopForegroundService()
                return
            } else {
                // Start next round
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
            // Move to next interval in current round
            val nextInterval = routine.intervals[nextIntervalIndex]
            _timerState.update {
                it.copy(
                    currentIntervalIndex = nextIntervalIndex,
                    timeRemaining = nextInterval.duration * 1000
                )
            }
        }
        updateServiceNotification()
    }

    fun skipToPreviousInterval() {
        val routine = _routine.value ?: return
        val state = _timerState.value

        val prevIntervalIndex = state.currentIntervalIndex - 1
        if (prevIntervalIndex < 0) {
            // Move to previous round
            val prevRound = state.currentRound - 1
            if (prevRound < 1) {
                // Already at beginning, just reset current interval
                val currentInterval = routine.intervals[state.currentIntervalIndex]
                _timerState.update {
                    it.copy(timeRemaining = currentInterval.duration * 1000)
                }
            } else {
                val lastInterval = routine.intervals.last()
                _timerState.update {
                    it.copy(
                        currentRound = prevRound,
                        currentIntervalIndex = routine.intervals.size - 1,
                        timeRemaining = lastInterval.duration * 1000
                    )
                }
            }
        } else {
            val prevInterval = routine.intervals[prevIntervalIndex]
            _timerState.update {
                it.copy(
                    currentIntervalIndex = prevIntervalIndex,
                    timeRemaining = prevInterval.duration * 1000
                )
            }
        }
        updateServiceNotification()
    }

    fun skipToNextInterval() {
        val routine = _routine.value ?: return
        moveToNextInterval(routine)
    }

    fun resetTimer() {
        _routine.value?.let { routine ->
            initializeTimer(routine)
        }
        stopForegroundService()
    }

    fun getCurrentInterval(): WorkoutInterval? {
        val routine = _routine.value ?: return null
        val state = _timerState.value
        return routine.intervals.getOrNull(state.currentIntervalIndex)
    }

    fun getNextInterval(): WorkoutInterval? {
        val routine = _routine.value ?: return null
        val state = _timerState.value
        val nextIndex = state.currentIntervalIndex + 1
        return if (nextIndex < routine.intervals.size) {
            routine.intervals[nextIndex]
        } else if (state.currentRound < routine.rounds) {
            routine.intervals.firstOrNull()
        } else {
            null
        }
    }

    private fun startForegroundService() {
        Intent(context, TimerService::class.java).apply {
            action = TimerService.ACTION_START
        }.also { intent ->
            context.startForegroundService(intent)
        }
    }

    private fun stopForegroundService() {
        Intent(context, TimerService::class.java).apply {
            action = TimerService.ACTION_STOP
        }.also { intent ->
            context.startService(intent)
        }
    }

    override fun onCleared() {
        super.onCleared()
        timerJob?.cancel()
        if (serviceBound) {
            context.unbindService(serviceConnection)
            serviceBound = false
        }
    }
}
