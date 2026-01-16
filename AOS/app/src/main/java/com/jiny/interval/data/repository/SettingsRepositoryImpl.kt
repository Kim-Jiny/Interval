package com.jiny.interval.data.repository

import com.jiny.interval.data.local.datastore.SettingsDataStore
import com.jiny.interval.domain.model.Settings
import com.jiny.interval.domain.repository.SettingsRepository
import kotlinx.coroutines.flow.Flow
import javax.inject.Inject

class SettingsRepositoryImpl @Inject constructor(
    private val settingsDataStore: SettingsDataStore
) : SettingsRepository {

    override fun getSettings(): Flow<Settings> = settingsDataStore.settings

    override suspend fun updateVibration(enabled: Boolean) {
        settingsDataStore.updateVibration(enabled)
    }

    override suspend fun updateVoiceGuidance(enabled: Boolean) {
        settingsDataStore.updateVoiceGuidance(enabled)
    }

    override suspend fun updateBackgroundSound(enabled: Boolean) {
        settingsDataStore.updateBackgroundSound(enabled)
    }
}
