package com.jiny.interval.service

import android.app.Notification
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import androidx.core.app.NotificationCompat
import com.jiny.interval.IntervalApp
import com.jiny.interval.domain.model.TimerState
import com.jiny.interval.domain.model.WorkoutInterval
import com.jiny.interval.presentation.MainActivity
import com.jiny.interval.util.TimeFormatter

class TimerNotificationManager(private val context: Context) {

    companion object {
        const val NOTIFICATION_ID = 1
    }

    private val pendingIntentFlags = PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT

    fun createNotification(
        timerState: TimerState,
        currentInterval: WorkoutInterval?
    ): Notification {
        // Just bring the app to foreground without any navigation
        val intent = Intent(context, MainActivity::class.java).apply {
            action = Intent.ACTION_MAIN
            addCategory(Intent.CATEGORY_LAUNCHER)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_RESET_TASK_IF_NEEDED
        }
        val contentIntent = PendingIntent.getActivity(
            context,
            0,
            intent,
            pendingIntentFlags
        )

        val intervalName = currentInterval?.name ?: "Timer"
        val timeText = TimeFormatter.formatMillisToMinSec(timerState.timeRemaining)

        return NotificationCompat.Builder(context, IntervalApp.TIMER_CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setContentTitle(intervalName)
            .setContentText("$timeText - Round ${timerState.currentRound}")
            .setContentIntent(contentIntent)
            .setOngoing(true)
            .setSilent(true)
            .setOnlyAlertOnce(true)
            .setCategory(NotificationCompat.CATEGORY_WORKOUT)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .build()
    }
}
