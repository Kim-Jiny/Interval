package com.jiny.interval.util

import android.content.Context
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import dagger.hilt.android.qualifiers.ApplicationContext
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class VibrationManager @Inject constructor(
    @ApplicationContext private val context: Context
) {
    private val vibrator: Vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
        val vibratorManager = context.getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
        vibratorManager.defaultVibrator
    } else {
        @Suppress("DEPRECATION")
        context.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
    }

    fun vibrateShort() {
        vibrate(100)
    }

    fun vibrateMedium() {
        vibrate(200)
    }

    fun vibrateLong() {
        vibrate(500)
    }

    fun vibratePattern(pattern: LongArray) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            vibrator.vibrate(VibrationEffect.createWaveform(pattern, -1))
        } else {
            @Suppress("DEPRECATION")
            vibrator.vibrate(pattern, -1)
        }
    }

    fun vibrateIntervalChange() {
        vibratePattern(longArrayOf(0, 100, 100, 100))
    }

    fun vibrateRoundComplete() {
        vibratePattern(longArrayOf(0, 200, 100, 200, 100, 200))
    }

    fun vibrateWorkoutComplete() {
        vibratePattern(longArrayOf(0, 300, 100, 300, 100, 500))
    }

    private fun vibrate(duration: Long) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            vibrator.vibrate(VibrationEffect.createOneShot(duration, VibrationEffect.DEFAULT_AMPLITUDE))
        } else {
            @Suppress("DEPRECATION")
            vibrator.vibrate(duration)
        }
    }

    fun cancel() {
        vibrator.cancel()
    }
}
