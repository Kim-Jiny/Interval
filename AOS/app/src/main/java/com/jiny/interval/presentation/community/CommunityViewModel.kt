package com.jiny.interval.presentation.community

import android.util.Log
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.jiny.interval.domain.model.ChallengeListItem
import com.jiny.interval.domain.model.MileageBalance
import com.jiny.interval.domain.repository.AuthRepository
import com.jiny.interval.domain.repository.ChallengeRepository
import com.jiny.interval.domain.repository.MileageRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import javax.inject.Inject

private const val TAG = "CommunityViewModel"

@HiltViewModel
class CommunityViewModel @Inject constructor(
    private val challengeRepository: ChallengeRepository,
    private val mileageRepository: MileageRepository,
    private val authRepository: AuthRepository
) : ViewModel() {

    val isLoggedIn: StateFlow<Boolean> = authRepository.isLoggedIn
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5000),
            initialValue = authRepository.isUserLoggedIn()
        )

    val mileageBalance: StateFlow<MileageBalance> = mileageRepository.balance
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5000),
            initialValue = MileageBalance.EMPTY
        )

    private val _myChallenges = MutableStateFlow<List<ChallengeListItem>>(emptyList())
    val myChallenges: StateFlow<List<ChallengeListItem>> = _myChallenges.asStateFlow()

    private val _joinableChallenges = MutableStateFlow<List<ChallengeListItem>>(emptyList())
    val joinableChallenges: StateFlow<List<ChallengeListItem>> = _joinableChallenges.asStateFlow()

    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    private val _error = MutableStateFlow<String?>(null)
    val error: StateFlow<String?> = _error.asStateFlow()

    init {
        loadData()
    }

    fun loadData() {
        viewModelScope.launch {
            _isLoading.value = true
            _error.value = null

            // Load mileage balance
            if (authRepository.isUserLoggedIn()) {
                mileageRepository.fetchBalance()
                loadMyChallenges()
            }

            // Load joinable challenges
            loadJoinableChallenges()

            _isLoading.value = false
        }
    }

    private suspend fun loadMyChallenges() {
        Log.d(TAG, "loadMyChallenges: Starting...")
        challengeRepository.getMyChallenges()
            .onSuccess { challenges ->
                Log.d(TAG, "loadMyChallenges: Success, got ${challenges.size} challenges")
                _myChallenges.value = challenges.sortedBy { it.computedStatus.ordinal }
            }
            .onFailure { e ->
                Log.e(TAG, "loadMyChallenges: Failed", e)
                _error.value = e.message
            }
    }

    private suspend fun loadJoinableChallenges() {
        Log.d(TAG, "loadJoinableChallenges: Starting...")
        challengeRepository.getJoinableChallenges()
            .onSuccess { challenges ->
                Log.d(TAG, "loadJoinableChallenges: Success, got ${challenges.size} challenges")
                _joinableChallenges.value = challenges
            }
            .onFailure { e ->
                Log.e(TAG, "loadJoinableChallenges: Failed", e)
                _error.value = e.message
            }
    }

    fun joinChallenge(challengeId: Int, onSuccess: () -> Unit) {
        viewModelScope.launch {
            _isLoading.value = true
            challengeRepository.joinChallenge(challengeId)
                .onSuccess {
                    loadData()
                    onSuccess()
                }
                .onFailure { e ->
                    _error.value = e.message
                }
            _isLoading.value = false
        }
    }

    fun clearError() {
        _error.value = null
    }
}
