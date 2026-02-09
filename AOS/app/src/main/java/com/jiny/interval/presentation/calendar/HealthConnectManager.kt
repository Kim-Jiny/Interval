package com.jiny.interval.presentation.calendar

import android.content.Context
import android.content.pm.PackageManager
import androidx.health.connect.client.HealthConnectClient
import androidx.health.connect.client.permission.HealthPermission
import androidx.health.connect.client.records.ExerciseSessionRecord
import androidx.health.connect.client.request.ReadRecordsRequest
import androidx.health.connect.client.time.TimeRangeFilter
import java.time.Instant
import java.time.ZoneId
import java.time.ZonedDateTime
import java.time.YearMonth

class HealthConnectManager(
    private val context: Context
) {
    private val client: HealthConnectClient? = try {
        HealthConnectClient.getOrCreate(context)
    } catch (e: Exception) {
        null
    }

    val permissionSet: Set<String> = setOf(
        HealthPermission.getReadPermission(ExerciseSessionRecord::class)
    )

    suspend fun isAvailable(): Boolean {
        return try {
            context.packageManager.getPackageInfo(
                HEALTH_CONNECT_PACKAGE,
                0
            )
            true
        } catch (_: PackageManager.NameNotFoundException) {
            false
        } catch (_: Exception) {
            false
        }
    }

    suspend fun hasPermissions(): Boolean {
        val controller = client?.permissionController ?: return false
        return controller.getGrantedPermissions().containsAll(permissionSet)
    }

    suspend fun readMonthlyWorkouts(month: YearMonth): List<HealthWorkout> {
        val hc = client ?: return emptyList()
        val start = month.atDay(1).atStartOfDay(ZoneId.systemDefault()).toInstant()
        val end = month.atEndOfMonth().atTime(23, 59, 59).atZone(ZoneId.systemDefault()).toInstant()

        val response = hc.readRecords(
            ReadRecordsRequest(
                recordType = ExerciseSessionRecord::class,
                timeRangeFilter = TimeRangeFilter.between(start, end)
            )
        )

        return response.records.map { record ->
            val startTime = record.startTime
            val endTime = record.endTime
            val durationSeconds = (endTime.epochSecond - startTime.epochSecond).toInt().coerceAtLeast(0)
            HealthWorkout(
                id = record.metadata.id,
                startTime = startTime,
                endTime = endTime,
                durationSeconds = durationSeconds
            )
        }
    }

    companion object {
        // Avoid DEFAULT_PROVIDER_PACKAGE_NAME (internal in some HC versions).
        private const val HEALTH_CONNECT_PACKAGE = "com.google.android.apps.healthdata"

        fun toLocalDate(instant: Instant): java.time.LocalDate {
            return instant.atZone(ZoneId.systemDefault()).toLocalDate()
        }

        fun toLocalTime(instant: Instant): java.time.LocalTime {
            return instant.atZone(ZoneId.systemDefault()).toLocalTime()
        }
    }
}
