package com.jiny.interval.util

object TimeFormatter {

    fun formatDuration(seconds: Int): String {
        val hours = seconds / 3600
        val minutes = (seconds % 3600) / 60
        val secs = seconds % 60

        return when {
            hours > 0 -> String.format("%d:%02d:%02d", hours, minutes, secs)
            else -> String.format("%d:%02d", minutes, secs)
        }
    }

    fun formatDurationLong(seconds: Int): String {
        val hours = seconds / 3600
        val minutes = (seconds % 3600) / 60
        val secs = seconds % 60

        return buildString {
            if (hours > 0) {
                append("${hours}h ")
            }
            if (minutes > 0) {
                append("${minutes}m ")
            }
            if (secs > 0 || (hours == 0 && minutes == 0)) {
                append("${secs}s")
            }
        }.trim()
    }

    fun formatMillisToMinSec(millis: Int): String {
        val totalSeconds = millis / 1000
        val minutes = totalSeconds / 60
        val seconds = totalSeconds % 60
        return String.format("%02d:%02d", minutes, seconds)
    }

    fun formatMillisToMinSecTenths(millis: Int): String {
        val totalSeconds = millis / 1000
        val minutes = totalSeconds / 60
        val seconds = totalSeconds % 60
        val tenths = (millis % 1000) / 100
        return String.format("%02d:%02d.%d", minutes, seconds, tenths)
    }

    fun formatMillis(millis: Long): String {
        val totalSeconds = (millis / 1000).toInt()
        val hours = totalSeconds / 3600
        val minutes = (totalSeconds % 3600) / 60
        val secs = totalSeconds % 60

        return when {
            hours > 0 -> String.format("%d:%02d:%02d", hours, minutes, secs)
            else -> String.format("%d:%02d", minutes, secs)
        }
    }
}
