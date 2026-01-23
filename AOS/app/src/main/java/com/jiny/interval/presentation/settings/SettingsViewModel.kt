package com.jiny.interval.presentation.settings

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.jiny.interval.domain.model.Settings
import com.jiny.interval.domain.model.User
import com.jiny.interval.domain.repository.AuthRepository
import com.jiny.interval.domain.usecase.settings.GetSettingsUseCase
import com.jiny.interval.domain.usecase.settings.UpdateSettingsUseCase
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class SettingsViewModel @Inject constructor(
    private val getSettingsUseCase: GetSettingsUseCase,
    private val updateSettingsUseCase: UpdateSettingsUseCase,
    private val authRepository: AuthRepository
) : ViewModel() {

    val settings: StateFlow<Settings> = getSettingsUseCase()
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5000),
            initialValue = Settings()
        )

    val isLoggedIn: StateFlow<Boolean> = authRepository.isLoggedIn
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5000),
            initialValue = authRepository.isUserLoggedIn()
        )

    val currentUser: StateFlow<User?> = authRepository.currentUser
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5000),
            initialValue = authRepository.getCurrentUser()
        )

    private val _deleteAccountState = MutableStateFlow<DeleteAccountState>(DeleteAccountState.Idle)
    val deleteAccountState: StateFlow<DeleteAccountState> = _deleteAccountState.asStateFlow()

    fun updateVibration(enabled: Boolean) {
        viewModelScope.launch {
            updateSettingsUseCase.updateVibration(enabled)
        }
    }

    fun updateVoiceGuidance(enabled: Boolean) {
        viewModelScope.launch {
            updateSettingsUseCase.updateVoiceGuidance(enabled)
        }
    }

    fun updateBackgroundSound(enabled: Boolean) {
        viewModelScope.launch {
            updateSettingsUseCase.updateBackgroundSound(enabled)
        }
    }

    fun logout() {
        viewModelScope.launch {
            authRepository.logout()
        }
    }

    fun deleteAccount() {
        viewModelScope.launch {
            _deleteAccountState.value = DeleteAccountState.Loading

            val result = authRepository.deleteAccount()
            _deleteAccountState.value = result.fold(
                onSuccess = { DeleteAccountState.Success },
                onFailure = { DeleteAccountState.Error(it.message ?: "Failed to delete account") }
            )
        }
    }

    fun resetDeleteAccountState() {
        _deleteAccountState.value = DeleteAccountState.Idle
    }
}

sealed class DeleteAccountState {
    data object Idle : DeleteAccountState()
    data object Loading : DeleteAccountState()
    data object Success : DeleteAccountState()
    data class Error(val message: String) : DeleteAccountState()
}
