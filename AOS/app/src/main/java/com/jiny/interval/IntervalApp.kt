package com.jiny.interval

import android.app.Application
import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import com.jiny.interval.data.remote.ConfigManager
import com.jiny.interval.domain.usecase.routine.SeedDefaultRoutinesUseCase
import dagger.hilt.android.HiltAndroidApp
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltAndroidApp
class IntervalApp : Application() {

    @Inject
    lateinit var configManager: ConfigManager

    @Inject
    lateinit var seedDefaultRoutinesUseCase: SeedDefaultRoutinesUseCase

    private val applicationScope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        loadRemoteConfig()
        seedDefaultRoutines()
    }

    private fun loadRemoteConfig() {
        applicationScope.launch {
            configManager.loadConfig()
        }
    }

    private fun seedDefaultRoutines() {
        applicationScope.launch(Dispatchers.IO) {
            seedDefaultRoutinesUseCase()
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                TIMER_CHANNEL_ID,
                getString(R.string.timer_notification_channel),
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "Timer notifications"
                setShowBadge(false)
                setSound(null, null)
                enableVibration(false)
            }

            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
        }
    }

    companion object {
        const val TIMER_CHANNEL_ID = "timer_channel"
    }
}
