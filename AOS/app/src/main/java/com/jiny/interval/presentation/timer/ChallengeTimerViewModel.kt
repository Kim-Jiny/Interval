package com.jiny.interval.presentation.timer

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.os.IBinder
import android.util.Log
import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.jiny.interval.domain.model.Challenge
import com.jiny.interval.domain.model.IntervalType
import com.jiny.interval.domain.model.Routine
import com.jiny.interval.domain.model.Settings
import com.jiny.interval.domain.model.TimerState
import com.jiny.interval.domain.model.WorkoutInterval
import com.jiny.interval.domain.repository.ChallengeRepository
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
import java.util.UUID
import javax.inject.Inject

private const val TAG = "ChallengeTimerViewModel"

@HiltViewModel
class ChallengeTimerViewModel @Inject constructor(
    savedStateHandle: SavedStateHandle,
    private val challengeRepository: ChallengeRepository,
    private val getSettingsUseCase: GetSettingsUseCase,
    @ApplicationContext private val context: Context
) : ViewModel() {

    private val challengeId: Int = checkNotNull(savedStateHandle["challengeId"])

    private val _challenge = MutableStateFlow<Challenge?>(null)
    val challenge: StateFlow<Challenge?> = _challenge.asStateFlow()

    private val _routine = MutableStateFlow<Routine?>(null)
    val routine: StateFlow<Routine?> = _routine.asStateFlow()

    private val _timerState = MutableStateFlow(TimerState())
    val timerState: StateFlow<TimerState> = _timerState.asStateFlow()

    private val _actualElapsedTime = MutableStateFlow(0L)
    val actualElapsedTime: StateFlow<Long> = _actualElapsedTime.asStateFlow()

    private val _isLoading = MutableStateFlow(true)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    private val _error = MutableStateFlow<String?>(null)
    val error: StateFlow<String?> = _error.asStateFlow()

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
    private var workoutRecorded = false

    private val serviceConnection = object : ServiceConnection {
        override fun onServiceConnected(name: ComponentName?, service: IBinder?) {
            val binder = service as TimerService.TimerBinder
            timerService = binder.getService()
            serviceBound = true
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
        loadChallenge()
        bindService()
    }

    private fun loadChallenge() {
        viewModelScope.launch {
            _isLoading.value = true
            Log.d(TAG, "Loading challenge: $challengeId")

            challengeRepository.getChallengeDetail(challengeId)
                .onSuccess { (challenge, _) ->
                    Log.d(TAG, "Challenge loaded: ${challenge.title}")
                    Log.d(TAG, "Challenge routineData: ${challenge.routineData}")
                    Log.d(TAG, "Challenge routineName: ${challenge.routineName}")
                    _challenge.value = challenge

                    val routineData = challenge.routineData
                    Log.d(TAG, "routineData is null: ${routineData == null}")
                    if (routineData != null) {
                        Log.d(TAG, "routineData.intervals.size: ${routineData.intervals.size}")
                        routineData.intervals.forEachIndexed { index, interval ->
                            Log.d(TAG, "Interval $index: name=${interval.name}, duration=${interval.duration}, type=${interval.type}")
                        }
                    }
                    if (routineData != null && routineData.intervals.isNotEmpty()) {
                        val routine = Routine(
                            id = "challenge_${challenge.id}",
                            name = challenge.routineName,
                            intervals = routineData.intervals.map { interval ->
                                WorkoutInterval(
                                    id = UUID.randomUUID().toString(),
                                    name = interval.name,
                                    duration = interval.duration,
                                    type = parseIntervalType(interval.type)
                                )
                            },
                            rounds = routineData.rounds
                        )
                        _routine.value = routine
                        initializeTimer(routine)
                        Log.d(TAG, "Routine created: ${routine.name}, ${routine.intervals.size} intervals, ${routine.rounds} rounds")
                    } else {
                        _error.value = "No routine data available"
                        Log.e(TAG, "No routine data in challenge")
                    }
                }
                .onFailure { e ->
                    Log.e(TAG, "Failed to load challenge", e)
                    _error.value = e.message ?: "Failed to load challenge"
                }

            _isLoading.value = false
        }
    }

    private fun parseIntervalType(type: String): IntervalType {
        return when (type.lowercase()) {
            "workout", "work" -> IntervalType.WORKOUT
            "rest" -> IntervalType.REST
            "warmup" -> IntervalType.WARMUP
            "cooldown" -> IntervalType.COOLDOWN
            else -> IntervalType.WORKOUT
        }
    }

    private fun initializeTimer(routine: Routine) {
        val firstInterval = routine.intervals.firstOrNull() ?: return
        _actualElapsedTime.value = 0L
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
        _timerState.update { it.copy(isRunning = true, isCompleted = false) }
        startForegroundService()
        pendingStart = !serviceBound
        tickCount = 0
        timerJob?.cancel()
        timerJob = viewModelScope.launch {
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

        // Track actual elapsed time
        _actualElapsedTime.value += 100

        if (state.timeRemaining <= 0) {
            moveToNextInterval(routine)
        } else {
            _timerState.update { it.copy(timeRemaining = it.timeRemaining - 100) }
            tickCount++
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
            val nextRound = state.currentRound + 1
            if (nextRound > routine.rounds) {
                _timerState.update {
                    it.copy(
                        isRunning = false,
                        isCompleted = true,
                        timeRemaining = 0
                    )
                }
                stopForegroundService()
                recordWorkoutCompletion()
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
        updateServiceNotification()
    }

    private fun recordWorkoutCompletion() {
        if (workoutRecorded) return
        workoutRecorded = true

        val routine = _routine.value ?: return
        val totalDuration = routine.totalDuration
        val roundsCompleted = routine.rounds

        viewModelScope.launch {
            Log.d(TAG, "Recording workout: challengeId=$challengeId, duration=$totalDuration, rounds=$roundsCompleted")
            challengeRepository.recordWorkout(challengeId, totalDuration, roundsCompleted)
                .onSuccess {
                    Log.d(TAG, "Workout recorded successfully")
                }
                .onFailure { e ->
                    Log.e(TAG, "Failed to record workout", e)
                }
        }
    }

    fun skipToPreviousInterval() {
        val routine = _routine.value
        if (routine == null) {
            Log.e(TAG, "skipToPreviousInterval: routine is null")
            return
        }
        val state = _timerState.value
        Log.d(TAG, "skipToPreviousInterval: currentIndex=${state.currentIntervalIndex}, currentRound=${state.currentRound}, totalIntervals=${routine.intervals.size}")

        val prevIntervalIndex = state.currentIntervalIndex - 1
        if (prevIntervalIndex < 0) {
            val prevRound = state.currentRound - 1
            if (prevRound < 1) {
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
        val routine = _routine.value
        if (routine == null) {
            Log.e(TAG, "skipToNextInterval: routine is null")
            return
        }
        Log.d(TAG, "skipToNextInterval: currentIndex=${_timerState.value.currentIntervalIndex}, totalIntervals=${routine.intervals.size}")
        moveToNextInterval(routine)
    }

    fun resetTimer() {
        workoutRecorded = false
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
