package com.jiny.interval.data.local.datastore

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.preferencesDataStore
import com.jiny.interval.domain.model.Settings
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import javax.inject.Inject
import javax.inject.Singleton

private val Context.dataStore: DataStore<Preferences> by preferencesDataStore(name = "settings")

@Singleton
class SettingsDataStore @Inject constructor(
    @ApplicationContext private val context: Context
) {
    private object PreferencesKeys {
        val VIBRATION_ENABLED = booleanPreferencesKey("vibration_enabled")
        val VOICE_GUIDANCE_ENABLED = booleanPreferencesKey("voice_guidance_enabled")
        val BACKGROUND_SOUND_ENABLED = booleanPreferencesKey("background_sound_enabled")
    }

    val settings: Flow<Settings> = context.dataStore.data.map { preferences ->
        Settings(
            vibrationEnabled = preferences[PreferencesKeys.VIBRATION_ENABLED] ?: true,
            voiceGuidanceEnabled = preferences[PreferencesKeys.VOICE_GUIDANCE_ENABLED] ?: true,
            backgroundSoundEnabled = preferences[PreferencesKeys.BACKGROUND_SOUND_ENABLED] ?: false
        )
    }

    suspend fun updateVibration(enabled: Boolean) {
        context.dataStore.edit { preferences ->
            preferences[PreferencesKeys.VIBRATION_ENABLED] = enabled
        }
    }

    suspend fun updateVoiceGuidance(enabled: Boolean) {
        context.dataStore.edit { preferences ->
            preferences[PreferencesKeys.VOICE_GUIDANCE_ENABLED] = enabled
        }
    }

    suspend fun updateBackgroundSound(enabled: Boolean) {
        context.dataStore.edit { preferences ->
            preferences[PreferencesKeys.BACKGROUND_SOUND_ENABLED] = enabled
        }
    }
}
