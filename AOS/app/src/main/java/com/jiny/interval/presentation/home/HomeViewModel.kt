package com.jiny.interval.presentation.home

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.jiny.interval.domain.model.ChallengeListItem
import com.jiny.interval.domain.model.ChallengeStatus
import com.jiny.interval.domain.model.Routine
import com.jiny.interval.domain.repository.AuthRepository
import com.jiny.interval.domain.repository.ChallengeRepository
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
    private val toggleFavoriteUseCase: ToggleFavoriteUseCase,
    private val challengeRepository: ChallengeRepository,
    private val authRepository: AuthRepository
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

    private val _activeChallenges = MutableStateFlow<List<ChallengeListItem>>(emptyList())
    val activeChallenges: StateFlow<List<ChallengeListItem>> = _activeChallenges.asStateFlow()

    private val _isLoggedIn = MutableStateFlow(false)
    val isLoggedIn: StateFlow<Boolean> = _isLoggedIn.asStateFlow()

    init {
        loadChallenges()
    }

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

    fun loadChallenges() {
        viewModelScope.launch {
            _isLoggedIn.value = authRepository.isUserLoggedIn()
            if (authRepository.isUserLoggedIn()) {
                challengeRepository.getMyChallenges()
                    .onSuccess { challenges ->
                        // Sort challenges by priority:
                        // 1. Completed but prize not received
                        // 2. Active (in progress)
                        // 3. Registration (recruiting)
                        // 4. Completed with prize received
                        // 5. Cancelled or others
                        _activeChallenges.value = challenges.sortedWith(
                            compareBy { challenge ->
                                when {
                                    // 1. Completed but prize not received yet
                                    challenge.computedStatus == ChallengeStatus.COMPLETED &&
                                    (challenge.myStats?.prizeWon ?: 0) == 0 -> 0
                                    // 2. Active challenges
                                    challenge.computedStatus == ChallengeStatus.ACTIVE -> 1
                                    // 3. Registration challenges
                                    challenge.computedStatus == ChallengeStatus.REGISTRATION -> 2
                                    // 4. Completed with prize received
                                    challenge.computedStatus == ChallengeStatus.COMPLETED &&
                                    (challenge.myStats?.prizeWon ?: 0) > 0 -> 3
                                    // 5. Cancelled or others
                                    else -> 4
                                }
                            }
                        )
                    }
            }
        }
    }
}

enum class HomeTab {
    CHALLENGE, FAVORITES, ALL
}
