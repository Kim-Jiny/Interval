package com.jiny.interval.domain.usecase.settings

import com.jiny.interval.domain.repository.SettingsRepository
import javax.inject.Inject

class UpdateSettingsUseCase @Inject constructor(
    private val repository: SettingsRepository
) {
    suspend fun updateVibration(enabled: Boolean) = repository.updateVibration(enabled)
    suspend fun updateVoiceGuidance(enabled: Boolean) = repository.updateVoiceGuidance(enabled)
    suspend fun updateBackgroundSound(enabled: Boolean) = repository.updateBackgroundSound(enabled)
}
