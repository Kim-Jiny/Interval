package com.jiny.interval.service

import android.app.Service
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Binder
import android.os.Build
import android.os.IBinder
import androidx.core.app.ServiceCompat
import com.jiny.interval.domain.model.TimerState
import com.jiny.interval.domain.model.WorkoutInterval
import dagger.hilt.android.AndroidEntryPoint

@AndroidEntryPoint
class TimerService : Service() {

    companion object {
        const val ACTION_START = "ACTION_START"
        const val ACTION_STOP = "ACTION_STOP"
        const val ACTION_PAUSE = "ACTION_PAUSE"
        const val ACTION_RESUME = "ACTION_RESUME"
    }

    private val binder = TimerBinder()
    private lateinit var notificationManager: TimerNotificationManager

    private var currentTimerState: TimerState = TimerState()
    private var currentInterval: WorkoutInterval? = null

    inner class TimerBinder : Binder() {
        fun getService(): TimerService = this@TimerService
    }

    override fun onCreate() {
        super.onCreate()
        notificationManager = TimerNotificationManager(this)
    }

    override fun onBind(intent: Intent?): IBinder {
        return binder
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> {
                // Cancel any existing notification first to prevent stacking
                val sysNotificationManager = getSystemService(NOTIFICATION_SERVICE) as android.app.NotificationManager
                sysNotificationManager.cancel(TimerNotificationManager.NOTIFICATION_ID)

                // Reset state for new routine
                currentTimerState = TimerState()
                currentInterval = null

                startForegroundService()
            }
            ACTION_STOP -> stopForegroundService()
            ACTION_PAUSE -> {
                // Handled by ViewModel
            }
            ACTION_RESUME -> {
                // Handled by ViewModel
            }
        }
        return START_STICKY
    }

    private fun startForegroundService() {
        val notification = notificationManager.createNotification(
            currentTimerState,
            currentInterval
        )

        ServiceCompat.startForeground(
            this,
            TimerNotificationManager.NOTIFICATION_ID,
            notification,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK
            } else {
                0
            }
        )
    }

    private fun stopForegroundService() {
        ServiceCompat.stopForeground(this, ServiceCompat.STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    fun updateNotification(timerState: TimerState, interval: WorkoutInterval?) {
        currentTimerState = timerState
        currentInterval = interval

        val notification = notificationManager.createNotification(timerState, interval)
        val notificationManager = getSystemService(NOTIFICATION_SERVICE) as android.app.NotificationManager
        notificationManager.notify(TimerNotificationManager.NOTIFICATION_ID, notification)
    }

    override fun onDestroy() {
        super.onDestroy()
        ServiceCompat.stopForeground(this, ServiceCompat.STOP_FOREGROUND_REMOVE)
    }
}
