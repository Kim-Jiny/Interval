package com.jiny.interval.presentation.auth

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.jiny.interval.domain.model.User
import com.jiny.interval.domain.repository.AuthRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class AuthViewModel @Inject constructor(
    private val authRepository: AuthRepository
) : ViewModel() {

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

    private val _authState = MutableStateFlow<AuthState>(AuthState.Idle)
    val authState: StateFlow<AuthState> = _authState.asStateFlow()

    fun loginWithGoogle(idToken: String, email: String?, displayName: String?) {
        viewModelScope.launch {
            _authState.value = AuthState.Loading

            val result = authRepository.socialLogin(
                provider = "google",
                providerToken = idToken,
                email = email,
                nickname = displayName
            )

            _authState.value = result.fold(
                onSuccess = { AuthState.Success(it) },
                onFailure = { AuthState.Error(it.message ?: "Login failed") }
            )
        }
    }

    fun logout() {
        viewModelScope.launch {
            authRepository.logout()
            _authState.value = AuthState.Idle
        }
    }

    fun deleteAccount() {
        viewModelScope.launch {
            _authState.value = AuthState.Loading

            val result = authRepository.deleteAccount()

            _authState.value = result.fold(
                onSuccess = { AuthState.AccountDeleted },
                onFailure = { AuthState.Error(it.message ?: "Delete account failed") }
            )
        }
    }

    fun resetAuthState() {
        _authState.value = AuthState.Idle
    }
}

sealed class AuthState {
    data object Idle : AuthState()
    data object Loading : AuthState()
    data class Success(val user: User) : AuthState()
    data class Error(val message: String) : AuthState()
    data object AccountDeleted : AuthState()
}
