package com.jiny.interval.domain.usecase.settings

import com.jiny.interval.domain.model.Settings
import com.jiny.interval.domain.repository.SettingsRepository
import kotlinx.coroutines.flow.Flow
import javax.inject.Inject

class GetSettingsUseCase @Inject constructor(
    private val repository: SettingsRepository
) {
    operator fun invoke(): Flow<Settings> = repository.getSettings()
}
