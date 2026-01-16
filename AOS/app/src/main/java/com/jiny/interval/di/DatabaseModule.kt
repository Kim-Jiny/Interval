package com.jiny.interval.di

import android.content.Context
import androidx.room.Room
import com.jiny.interval.data.local.database.AppDatabase
import com.jiny.interval.data.local.database.dao.RoutineDao
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object DatabaseModule {

    @Provides
    @Singleton
    fun provideDatabase(@ApplicationContext context: Context): AppDatabase {
        return Room.databaseBuilder(
            context,
            AppDatabase::class.java,
            "interval_database"
        ).build()
    }

    @Provides
    @Singleton
    fun provideRoutineDao(database: AppDatabase): RoutineDao {
        return database.routineDao()
    }
}
