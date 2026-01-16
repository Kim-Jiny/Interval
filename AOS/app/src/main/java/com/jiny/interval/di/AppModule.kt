package com.jiny.interval.di

import android.content.Context
import com.jiny.interval.data.provider.StringProviderImpl
import com.jiny.interval.domain.provider.StringProvider
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object AppModule {

    @Provides
    @Singleton
    fun provideContext(@ApplicationContext context: Context): Context = context

    @Provides
    @Singleton
    fun provideStringProvider(@ApplicationContext context: Context): StringProvider =
        StringProviderImpl(context)
}
