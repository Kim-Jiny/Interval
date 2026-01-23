package com.jiny.interval.presentation.community

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.jiny.interval.domain.model.MileageBalance
import com.jiny.interval.domain.model.Routine
import com.jiny.interval.domain.repository.AuthRepository
import com.jiny.interval.domain.repository.ChallengeRepository
import com.jiny.interval.domain.repository.ChallengeRoutineInterval
import com.jiny.interval.domain.repository.MileageRepository
import com.jiny.interval.domain.repository.RoutineRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale
import javax.inject.Inject

@HiltViewModel
class CreateChallengeViewModel @Inject constructor(
    private val challengeRepository: ChallengeRepository,
    private val mileageRepository: MileageRepository,
    private val routineRepository: RoutineRepository,
    private val authRepository: AuthRepository
) : ViewModel() {

    val mileageBalance: StateFlow<MileageBalance> = mileageRepository.balance
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5000),
            initialValue = MileageBalance.EMPTY
        )

    val routines: StateFlow<List<Routine>> = routineRepository.getAllRoutines()
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5000),
            initialValue = emptyList()
        )

    private val _title = MutableStateFlow("")
    val title: StateFlow<String> = _title.asStateFlow()

    private val _description = MutableStateFlow("")
    val description: StateFlow<String> = _description.asStateFlow()

    private val _selectedRoutine = MutableStateFlow<Routine?>(null)
    val selectedRoutine: StateFlow<Routine?> = _selectedRoutine.asStateFlow()

    private val _registrationEndDate = MutableStateFlow(getDefaultRegistrationEndDate())
    val registrationEndDate: StateFlow<Date> = _registrationEndDate.asStateFlow()

    private val _challengeStartDate = MutableStateFlow(getDefaultChallengeStartDate())
    val challengeStartDate: StateFlow<Date> = _challengeStartDate.asStateFlow()

    private val _challengeEndDate = MutableStateFlow(getDefaultChallengeEndDate())
    val challengeEndDate: StateFlow<Date> = _challengeEndDate.asStateFlow()

    private val _entryFee = MutableStateFlow(100)
    val entryFee: StateFlow<Int> = _entryFee.asStateFlow()

    private val _isPublic = MutableStateFlow(true)
    val isPublic: StateFlow<Boolean> = _isPublic.asStateFlow()

    private val _maxParticipants = MutableStateFlow<Int?>(null)
    val maxParticipants: StateFlow<Int?> = _maxParticipants.asStateFlow()

    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    private val _error = MutableStateFlow<String?>(null)
    val error: StateFlow<String?> = _error.asStateFlow()

    private val _createdShareUrl = MutableStateFlow<String?>(null)
    val createdShareUrl: StateFlow<String?> = _createdShareUrl.asStateFlow()

    init {
        viewModelScope.launch {
            if (authRepository.isUserLoggedIn()) {
                mileageRepository.fetchBalance()
            }
        }
    }

    fun updateTitle(value: String) {
        _title.value = value
    }

    fun updateDescription(value: String) {
        _description.value = value
    }

    fun selectRoutine(routine: Routine) {
        _selectedRoutine.value = routine
        if (_title.value.isBlank()) {
            _title.value = routine.name
        }
    }

    fun updateRegistrationEndDate(date: Date) {
        _registrationEndDate.value = date
        // Ensure challenge start is after registration end
        if (_challengeStartDate.value.before(date)) {
            val calendar = Calendar.getInstance()
            calendar.time = date
            calendar.add(Calendar.DAY_OF_MONTH, 1)
            _challengeStartDate.value = calendar.time
        }
    }

    fun updateChallengeStartDate(date: Date) {
        _challengeStartDate.value = date
        // Ensure challenge end is after challenge start
        if (_challengeEndDate.value.before(date)) {
            val calendar = Calendar.getInstance()
            calendar.time = date
            calendar.add(Calendar.DAY_OF_MONTH, 7)
            _challengeEndDate.value = calendar.time
        }
    }

    fun updateChallengeEndDate(date: Date) {
        _challengeEndDate.value = date
    }

    fun updateEntryFee(fee: Int) {
        _entryFee.value = fee.coerceIn(0, 10000)
    }

    fun updateIsPublic(value: Boolean) {
        _isPublic.value = value
    }

    fun updateMaxParticipants(value: Int?) {
        _maxParticipants.value = value
    }

    fun createChallenge(onSuccess: () -> Unit) {
        val routine = _selectedRoutine.value
        if (routine == null) {
            _error.value = "Please select a routine"
            return
        }

        if (_title.value.isBlank()) {
            _error.value = "Please enter a title"
            return
        }

        if (_entryFee.value > mileageBalance.value.balance) {
            _error.value = "Insufficient mileage"
            return
        }

        viewModelScope.launch {
            _isLoading.value = true
            _error.value = null

            val dateFormat = SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.getDefault())

            val intervals = routine.intervals.map { interval ->
                ChallengeRoutineInterval(
                    name = interval.name,
                    duration = interval.duration,
                    type = interval.type.name.lowercase()
                )
            }

            challengeRepository.createChallenge(
                title = _title.value,
                description = _description.value.takeIf { it.isNotBlank() },
                routineName = routine.name,
                routineIntervals = intervals,
                routineRounds = routine.rounds,
                registrationEndAt = dateFormat.format(_registrationEndDate.value),
                challengeStartAt = dateFormat.format(_challengeStartDate.value),
                challengeEndAt = dateFormat.format(_challengeEndDate.value),
                entryFee = _entryFee.value,
                isPublic = _isPublic.value,
                maxParticipants = _maxParticipants.value
            ).onSuccess { shareUrl ->
                _createdShareUrl.value = shareUrl
                onSuccess()
            }.onFailure { e ->
                _error.value = e.message
            }

            _isLoading.value = false
        }
    }

    fun clearError() {
        _error.value = null
    }

    private fun getDefaultRegistrationEndDate(): Date {
        val calendar = Calendar.getInstance()
        calendar.add(Calendar.DAY_OF_MONTH, 3)
        return calendar.time
    }

    private fun getDefaultChallengeStartDate(): Date {
        val calendar = Calendar.getInstance()
        calendar.add(Calendar.DAY_OF_MONTH, 4)
        return calendar.time
    }

    private fun getDefaultChallengeEndDate(): Date {
        val calendar = Calendar.getInstance()
        calendar.add(Calendar.DAY_OF_MONTH, 11)
        return calendar.time
    }
}
