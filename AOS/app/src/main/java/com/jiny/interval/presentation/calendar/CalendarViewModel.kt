package com.jiny.interval.presentation.calendar

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.jiny.interval.domain.model.WorkoutHistory
import com.jiny.interval.domain.model.WorkoutRecord
import com.jiny.interval.domain.repository.AuthRepository
import com.jiny.interval.domain.usecase.workout.DeleteWorkoutRecordUseCase
import com.jiny.interval.domain.usecase.workout.GetWorkoutHistoryUseCase
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import java.time.LocalDate
import java.time.YearMonth
import javax.inject.Inject

@HiltViewModel
class CalendarViewModel @Inject constructor(
    private val getWorkoutHistoryUseCase: GetWorkoutHistoryUseCase,
    private val deleteWorkoutRecordUseCase: DeleteWorkoutRecordUseCase,
    private val authRepository: AuthRepository
) : ViewModel() {

    private val _currentMonth = MutableStateFlow(YearMonth.now())
    val currentMonth: StateFlow<YearMonth> = _currentMonth.asStateFlow()

    private val _selectedDate = MutableStateFlow<LocalDate?>(null)
    val selectedDate: StateFlow<LocalDate?> = _selectedDate.asStateFlow()

    private val _records = MutableStateFlow<List<WorkoutRecord>>(emptyList())
    val records: StateFlow<List<WorkoutRecord>> = _records.asStateFlow()

    private val _healthWorkouts = MutableStateFlow<List<HealthWorkout>>(emptyList())
    val healthWorkouts: StateFlow<List<HealthWorkout>> = _healthWorkouts.asStateFlow()

    private val _healthPermissionsGranted = MutableStateFlow(false)
    val healthPermissionsGranted: StateFlow<Boolean> = _healthPermissionsGranted.asStateFlow()

    private val _healthAvailable = MutableStateFlow(true)
    val healthAvailable: StateFlow<Boolean> = _healthAvailable.asStateFlow()

    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    private val _error = MutableStateFlow<String?>(null)
    val error: StateFlow<String?> = _error.asStateFlow()

    private val _isLoggedIn = MutableStateFlow(authRepository.isUserLoggedIn())
    val isLoggedIn: StateFlow<Boolean> = _isLoggedIn.asStateFlow()

    init {
        loadMonth(YearMonth.now())
    }

    fun selectDate(date: LocalDate?) {
        _selectedDate.value = date
    }

    fun goToMonth(month: YearMonth) {
        _currentMonth.value = month
        loadMonth(month)
    }

    fun refresh() {
        loadMonth(_currentMonth.value)
    }

    fun clearError() {
        _error.value = null
    }

    fun setHealthAvailability(available: Boolean) {
        _healthAvailable.value = available
    }

    fun setHealthPermissionsGranted(granted: Boolean) {
        _healthPermissionsGranted.value = granted
    }

    fun setHealthWorkouts(items: List<HealthWorkout>) {
        _healthWorkouts.value = items
    }

    fun deleteRecord(id: Int) {
        viewModelScope.launch {
            deleteWorkoutRecordUseCase(id)
                .onSuccess {
                    _records.value = _records.value.filterNot { it.id == id }
                }
                .onFailure { error ->
                    _error.value = error.message ?: "Failed to delete record"
                }
        }
    }

    private fun loadMonth(month: YearMonth) {
        viewModelScope.launch {
            _isLoggedIn.value = authRepository.isUserLoggedIn()
            if (!_isLoggedIn.value) {
                _records.value = emptyList()
                _isLoading.value = false
                return@launch
            }

            _isLoading.value = true
            getWorkoutHistoryUseCase(month.year, month.monthValue)
                .onSuccess { history ->
                    applyHistory(history)
                }
                .onFailure { error ->
                    _records.value = emptyList()
                    _error.value = error.message ?: "Failed to load history"
                }
            _isLoading.value = false
        }
    }

    private fun applyHistory(history: WorkoutHistory) {
        _records.value = history.records
    }
}
