package com.jiny.interval.presentation.home

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.jiny.interval.domain.model.Routine
import com.jiny.interval.domain.usecase.routine.DeleteRoutineUseCase
import com.jiny.interval.domain.usecase.routine.GetFavoriteRoutinesUseCase
import com.jiny.interval.domain.usecase.routine.GetRoutinesUseCase
import com.jiny.interval.domain.usecase.routine.ToggleFavoriteUseCase
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class HomeViewModel @Inject constructor(
    private val getRoutinesUseCase: GetRoutinesUseCase,
    private val getFavoriteRoutinesUseCase: GetFavoriteRoutinesUseCase,
    private val deleteRoutineUseCase: DeleteRoutineUseCase,
    private val toggleFavoriteUseCase: ToggleFavoriteUseCase
) : ViewModel() {

    private val _selectedTab = MutableStateFlow(HomeTab.ALL)
    val selectedTab: StateFlow<HomeTab> = _selectedTab.asStateFlow()

    val allRoutines: StateFlow<List<Routine>> = getRoutinesUseCase()
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5000),
            initialValue = emptyList()
        )

    val favoriteRoutines: StateFlow<List<Routine>> = getFavoriteRoutinesUseCase()
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5000),
            initialValue = emptyList()
        )

    fun selectTab(tab: HomeTab) {
        _selectedTab.value = tab
    }

    fun deleteRoutine(id: String) {
        viewModelScope.launch {
            deleteRoutineUseCase(id)
        }
    }

    fun toggleFavorite(id: String) {
        viewModelScope.launch {
            toggleFavoriteUseCase(id)
        }
    }
}

enum class HomeTab {
    FAVORITES, ALL
}
