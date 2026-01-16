package com.jiny.interval.presentation.settings

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.jiny.interval.domain.model.Settings
import com.jiny.interval.domain.usecase.settings.GetSettingsUseCase
import com.jiny.interval.domain.usecase.settings.UpdateSettingsUseCase
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class SettingsViewModel @Inject constructor(
    private val getSettingsUseCase: GetSettingsUseCase,
    private val updateSettingsUseCase: UpdateSettingsUseCase
) : ViewModel() {

    val settings: StateFlow<Settings> = getSettingsUseCase()
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5000),
            initialValue = Settings()
        )

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
}
