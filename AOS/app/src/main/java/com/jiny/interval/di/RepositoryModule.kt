package com.jiny.interval.di

import com.jiny.interval.data.repository.AuthRepositoryImpl
import com.jiny.interval.data.repository.ChallengeRepositoryImpl
import com.jiny.interval.data.repository.MileageRepositoryImpl
import com.jiny.interval.data.repository.RoutineRepositoryImpl
import com.jiny.interval.data.repository.SettingsRepositoryImpl
import com.jiny.interval.domain.repository.AuthRepository
import com.jiny.interval.domain.repository.ChallengeRepository
import com.jiny.interval.domain.repository.MileageRepository
import com.jiny.interval.domain.repository.RoutineRepository
import com.jiny.interval.domain.repository.SettingsRepository
import dagger.Binds
import dagger.Module
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
abstract class RepositoryModule {

    @Binds
    @Singleton
    abstract fun bindRoutineRepository(
        routineRepositoryImpl: RoutineRepositoryImpl
    ): RoutineRepository

    @Binds
    @Singleton
    abstract fun bindSettingsRepository(
        settingsRepositoryImpl: SettingsRepositoryImpl
    ): SettingsRepository

    @Binds
    @Singleton
    abstract fun bindAuthRepository(
        authRepositoryImpl: AuthRepositoryImpl
    ): AuthRepository

    @Binds
    @Singleton
    abstract fun bindChallengeRepository(
        challengeRepositoryImpl: ChallengeRepositoryImpl
    ): ChallengeRepository

    @Binds
    @Singleton
    abstract fun bindMileageRepository(
        mileageRepositoryImpl: MileageRepositoryImpl
    ): MileageRepository
}
