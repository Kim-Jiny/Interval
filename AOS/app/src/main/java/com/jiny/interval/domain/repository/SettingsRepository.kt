package com.jiny.interval.domain.repository

import com.jiny.interval.domain.model.Settings
import kotlinx.coroutines.flow.Flow

interface SettingsRepository {
    fun getSettings(): Flow<Settings>
    suspend fun updateVibration(enabled: Boolean)
    suspend fun updateVoiceGuidance(enabled: Boolean)
    suspend fun updateBackgroundSound(enabled: Boolean)
}
