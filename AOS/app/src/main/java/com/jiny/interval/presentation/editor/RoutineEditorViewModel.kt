package com.jiny.interval.presentation.editor

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.jiny.interval.domain.model.IntervalType
import com.jiny.interval.domain.model.Routine
import com.jiny.interval.domain.model.WorkoutInterval
import com.jiny.interval.domain.usecase.routine.GetRoutineByIdUseCase
import com.jiny.interval.domain.usecase.routine.SaveRoutineUseCase
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import java.util.UUID
import javax.inject.Inject

@HiltViewModel
class RoutineEditorViewModel @Inject constructor(
    savedStateHandle: SavedStateHandle,
    private val getRoutineByIdUseCase: GetRoutineByIdUseCase,
    private val saveRoutineUseCase: SaveRoutineUseCase
) : ViewModel() {

    private val routineId: String? = savedStateHandle["routineId"]

    private val _uiState = MutableStateFlow(RoutineEditorUiState())
    val uiState: StateFlow<RoutineEditorUiState> = _uiState.asStateFlow()

    private val _editingInterval = MutableStateFlow<EditingInterval?>(null)
    val editingInterval: StateFlow<EditingInterval?> = _editingInterval.asStateFlow()

    init {
        if (routineId != null) {
            loadRoutine(routineId)
        }
    }

    private fun loadRoutine(id: String) {
        viewModelScope.launch {
            val routine = getRoutineByIdUseCase(id)
            routine?.let {
                _uiState.update { state ->
                    state.copy(
                        id = it.id,
                        name = it.name,
                        rounds = it.rounds,
                        intervals = it.intervals,
                        isEditing = true
                    )
                }
            }
        }
    }

    fun updateName(name: String) {
        _uiState.update { it.copy(name = name) }
    }

    fun updateRounds(rounds: Int) {
        _uiState.update { it.copy(rounds = rounds.coerceIn(1, 99)) }
    }

    fun incrementRounds() {
        _uiState.update { it.copy(rounds = (it.rounds + 1).coerceIn(1, 99)) }
    }

    fun decrementRounds() {
        _uiState.update { it.copy(rounds = (it.rounds - 1).coerceIn(1, 99)) }
    }

    fun addInterval(interval: WorkoutInterval) {
        _uiState.update { state ->
            state.copy(intervals = state.intervals + interval)
        }
    }

    fun updateInterval(index: Int, interval: WorkoutInterval) {
        _uiState.update { state ->
            val newIntervals = state.intervals.toMutableList()
            if (index in newIntervals.indices) {
                newIntervals[index] = interval
            }
            state.copy(intervals = newIntervals)
        }
    }

    fun deleteInterval(index: Int) {
        _uiState.update { state ->
            val newIntervals = state.intervals.toMutableList()
            if (index in newIntervals.indices) {
                newIntervals.removeAt(index)
            }
            state.copy(intervals = newIntervals)
        }
    }

    fun moveInterval(fromIndex: Int, toIndex: Int) {
        _uiState.update { state ->
            val newIntervals = state.intervals.toMutableList()
            if (fromIndex in newIntervals.indices && toIndex in newIntervals.indices) {
                val item = newIntervals.removeAt(fromIndex)
                newIntervals.add(toIndex, item)
            }
            state.copy(intervals = newIntervals)
        }
    }

    fun startEditingInterval(index: Int? = null) {
        val state = _uiState.value
        val interval = index?.let { state.intervals.getOrNull(it) }
        _editingInterval.value = EditingInterval(
            index = index,
            name = interval?.name ?: "Work",
            duration = interval?.duration ?: 30,
            type = interval?.type ?: IntervalType.WORKOUT
        )
    }

    fun updateEditingIntervalName(name: String) {
        _editingInterval.update { it?.copy(name = name) }
    }

    fun updateEditingIntervalDuration(duration: Int) {
        _editingInterval.update { it?.copy(duration = duration.coerceIn(1, 3600)) }
    }

    fun updateEditingIntervalType(type: IntervalType) {
        _editingInterval.update { it?.copy(type = type) }
    }

    fun saveEditingInterval() {
        val editing = _editingInterval.value ?: return
        val interval = WorkoutInterval(
            id = _uiState.value.intervals.getOrNull(editing.index ?: -1)?.id ?: UUID.randomUUID().toString(),
            name = editing.name,
            duration = editing.duration,
            type = editing.type
        )

        if (editing.index != null) {
            updateInterval(editing.index, interval)
        } else {
            addInterval(interval)
        }
        _editingInterval.value = null
    }

    fun cancelEditingInterval() {
        _editingInterval.value = null
    }

    fun saveRoutine(onSuccess: () -> Unit) {
        viewModelScope.launch {
            val state = _uiState.value
            if (state.name.isBlank() || state.intervals.isEmpty()) {
                return@launch
            }

            val routine = Routine(
                id = state.id,
                name = state.name,
                intervals = state.intervals,
                rounds = state.rounds,
                createdAt = if (state.isEditing) {
                    // Preserve original creation time for editing
                    System.currentTimeMillis() // This will be overwritten in repository
                } else {
                    System.currentTimeMillis()
                },
                updatedAt = System.currentTimeMillis()
            )

            saveRoutineUseCase(routine)
            onSuccess()
        }
    }

    fun canSave(): Boolean {
        val state = _uiState.value
        return state.name.isNotBlank() && state.intervals.isNotEmpty()
    }
}

data class RoutineEditorUiState(
    val id: String = UUID.randomUUID().toString(),
    val name: String = "",
    val rounds: Int = 1,
    val intervals: List<WorkoutInterval> = emptyList(),
    val isEditing: Boolean = false
)

data class EditingInterval(
    val index: Int?,
    val name: String,
    val duration: Int,
    val type: IntervalType
)
