package com.jiny.interval.presentation.template

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.jiny.interval.domain.model.Routine
import com.jiny.interval.domain.usecase.routine.SaveRoutineUseCase
import com.jiny.interval.domain.usecase.template.GetTemplatesUseCase
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class TemplateSelectionViewModel @Inject constructor(
    private val getTemplatesUseCase: GetTemplatesUseCase,
    private val saveRoutineUseCase: SaveRoutineUseCase
) : ViewModel() {

    private val _templates = MutableStateFlow<List<Routine>>(emptyList())
    val templates: StateFlow<List<Routine>> = _templates.asStateFlow()

    init {
        loadTemplates()
    }

    private fun loadTemplates() {
        _templates.value = getTemplatesUseCase()
    }

    fun selectTemplate(routine: Routine, onSuccess: (Routine) -> Unit) {
        viewModelScope.launch {
            // Create a new routine based on the template
            val newRoutine = routine.copy(
                createdAt = System.currentTimeMillis(),
                updatedAt = System.currentTimeMillis()
            )
            saveRoutineUseCase(newRoutine)
            onSuccess(newRoutine)
        }
    }
}
