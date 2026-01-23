package com.jiny.interval.presentation.community

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.jiny.interval.domain.model.Challenge
import com.jiny.interval.domain.model.ChallengeParticipant
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

@HiltViewModel
class ChallengeDetailViewModel @Inject constructor(
    savedStateHandle: SavedStateHandle,
    private val challengeRepository: ChallengeRepository,
    private val mileageRepository: MileageRepository,
    private val authRepository: AuthRepository
) : ViewModel() {

    private val challengeId: Int? = savedStateHandle.get<Int>("challengeId")
    private val shareCode: String? = savedStateHandle.get<String>("shareCode")

    private var loadedChallengeId: Int = challengeId ?: 0

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

    private val _challenge = MutableStateFlow<Challenge?>(null)
    val challenge: StateFlow<Challenge?> = _challenge.asStateFlow()

    private val _participants = MutableStateFlow<List<ChallengeParticipant>>(emptyList())
    val participants: StateFlow<List<ChallengeParticipant>> = _participants.asStateFlow()

    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    private val _isJoining = MutableStateFlow(false)
    val isJoining: StateFlow<Boolean> = _isJoining.asStateFlow()

    private val _error = MutableStateFlow<String?>(null)
    val error: StateFlow<String?> = _error.asStateFlow()

    private val _message = MutableStateFlow<String?>(null)
    val message: StateFlow<String?> = _message.asStateFlow()

    init {
        loadData()
    }

    fun loadData() {
        viewModelScope.launch {
            _isLoading.value = true
            _error.value = null

            if (authRepository.isUserLoggedIn()) {
                mileageRepository.fetchBalance()
            }

            // Load by share code or challenge id
            val result = if (!shareCode.isNullOrEmpty()) {
                challengeRepository.getChallengeByCode(shareCode)
            } else {
                challengeRepository.getChallengeDetail(loadedChallengeId)
            }

            result
                .onSuccess { (challenge, participants) ->
                    _challenge.value = challenge
                    _participants.value = participants.sortedBy { it.rank }
                    loadedChallengeId = challenge.id
                }
                .onFailure { e ->
                    _error.value = e.message
                }

            _isLoading.value = false
        }
    }

    fun joinChallenge() {
        val challenge = _challenge.value ?: return
        if (!authRepository.isUserLoggedIn()) {
            _error.value = "Please login to join challenges"
            return
        }

        if (mileageBalance.value.balance < challenge.entryFee) {
            _error.value = "Insufficient mileage"
            return
        }

        viewModelScope.launch {
            _isJoining.value = true
            challengeRepository.joinChallenge(loadedChallengeId)
                .onSuccess { entryFeePaid ->
                    _message.value = "Joined! Entry fee: ${entryFeePaid}M"
                    loadData()
                }
                .onFailure { e ->
                    _error.value = e.message
                }
            _isJoining.value = false
        }
    }

    fun leaveChallenge() {
        viewModelScope.launch {
            _isJoining.value = true
            challengeRepository.leaveChallenge(loadedChallengeId)
                .onSuccess { refundedAmount ->
                    _message.value = "Left challenge. Refunded: ${refundedAmount}M"
                    loadData()
                }
                .onFailure { e ->
                    _error.value = e.message
                }
            _isJoining.value = false
        }
    }

    fun clearError() {
        _error.value = null
    }

    fun clearMessage() {
        _message.value = null
    }
}
