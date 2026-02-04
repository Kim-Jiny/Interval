package com.jiny.interval.domain.model

import java.text.NumberFormat
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.concurrent.TimeUnit

/**
 * Challenge Status
 */
enum class ChallengeStatus(val value: String) {
    REGISTRATION("registration"),
    ACTIVE("active"),
    COMPLETED("completed"),
    CANCELLED("cancelled");

    companion object {
        fun fromValue(value: String): ChallengeStatus {
            return entries.find { it.value == value } ?: REGISTRATION
        }
    }
}

/**
 * Challenge List Item for display in lists
 */
data class ChallengeListItem(
    val id: Int,
    val shareCode: String,
    val title: String,
    val description: String?,
    val routineName: String,
    val routineData: ChallengeRoutineData?,
    val registrationStartAt: String,
    val registrationEndAt: String,
    val challengeStartAt: String,
    val challengeEndAt: String,
    val maxParticipants: Int?,
    val entryFee: Int,
    val totalPrizePool: Int,
    val participantCount: Int,
    val status: ChallengeStatus,
    val creatorNickname: String?,
    val isParticipating: Boolean,
    val isCreator: Boolean?,
    val todayCompleted: Boolean?,
    val myStats: ParticipationStats?,
    val createdAt: String
) {
    val formattedEntryFee: String
        get() = "${formatNumber(entryFee)}M"

    val formattedPrizePool: String
        get() = "${formatNumber(totalPrizePool)}M"

    val challengeStartDate: Date?
        get() = parseDate(challengeStartAt)

    val challengeEndDate: Date?
        get() = parseDate(challengeEndAt)

    val daysRemaining: Int?
        get() {
            val endDate = challengeEndDate ?: return null
            val diff = endDate.time - System.currentTimeMillis()
            return maxOf(0, TimeUnit.MILLISECONDS.toDays(diff).toInt())
        }

    val daysUntilStart: Int?
        get() {
            val startDate = challengeStartDate ?: return null
            val diff = startDate.time - System.currentTimeMillis()
            return maxOf(0, TimeUnit.MILLISECONDS.toDays(diff).toInt())
        }

    val isCurrentlyActive: Boolean
        get() {
            val startDate = challengeStartDate ?: return false
            val endDate = challengeEndDate ?: return false
            val now = Date()
            return now.after(startDate) && now.before(endDate)
        }

    val computedStatus: ChallengeStatus
        get() {
            val regEndDate = parseDate(registrationEndAt) ?: return status
            val startDate = challengeStartDate ?: return status
            val endDate = challengeEndDate ?: return status
            val now = Date()

            return when {
                now.after(endDate) -> ChallengeStatus.COMPLETED
                now.after(startDate) -> ChallengeStatus.ACTIVE
                now.before(regEndDate) -> ChallengeStatus.REGISTRATION
                else -> ChallengeStatus.REGISTRATION
            }
        }
}

/**
 * Full Challenge model with all details
 */
data class Challenge(
    val id: Int,
    val shareCode: String,
    val shareUrl: String?,
    val title: String,
    val description: String?,
    val routineName: String,
    val routineData: ChallengeRoutineData?,
    val registrationStartAt: String,
    val registrationEndAt: String,
    val challengeStartAt: String,
    val challengeEndAt: String,
    val isPublic: Boolean?,
    val maxParticipants: Int?,
    val entryFee: Int,
    val totalPrizePool: Int,
    val participantCount: Int,
    val status: ChallengeStatus,
    val creatorId: Int?,
    val creatorNickname: String?,
    val isParticipating: Boolean?,
    val canJoin: Boolean?,
    val canLeave: Boolean?,
    val myRank: Int?,
    val myParticipation: ParticipationStats?,
    val totalDays: Int?,
    val createdAt: String
) {
    val formattedEntryFee: String
        get() = "${formatNumber(entryFee)}M"

    val formattedPrizePool: String
        get() = "${formatNumber(totalPrizePool)}M"

    val challengeStartDate: Date?
        get() = parseDate(challengeStartAt)

    val challengeEndDate: Date?
        get() = parseDate(challengeEndAt)

    val computedStatus: ChallengeStatus
        get() {
            val regEndDate = parseDate(registrationEndAt) ?: return status
            val startDate = challengeStartDate ?: return status
            val endDate = challengeEndDate ?: return status
            val now = Date()

            return when {
                now.after(endDate) -> ChallengeStatus.COMPLETED
                now.after(startDate) -> ChallengeStatus.ACTIVE
                now.before(regEndDate) -> ChallengeStatus.REGISTRATION
                else -> ChallengeStatus.REGISTRATION
            }
        }
}

/**
 * Challenge Routine Data
 */
data class ChallengeRoutineData(
    val intervals: List<ChallengeInterval>,
    val rounds: Int
)

/**
 * Challenge Interval
 */
data class ChallengeInterval(
    val name: String,
    val duration: Int,
    val type: String
)

/**
 * Participation Stats
 */
data class ParticipationStats(
    val completionCount: Int,
    val attendanceRate: Double,
    val finalRank: Int?,
    val prizeWon: Int,
    val entryFeePaid: Int,
    val joinedAt: String?
) {
    val formattedAttendanceRate: String
        get() = String.format(Locale.getDefault(), "%.1f%%", attendanceRate)

    val formattedPrizeWon: String
        get() = "${formatNumber(prizeWon)}M"
}

/**
 * Challenge Participant
 */
data class ChallengeParticipant(
    val rank: Int,
    val userId: Int,
    val nickname: String?,
    val profileImage: String?,
    val completionCount: Int,
    val attendanceRate: Double,
    val finalRank: Int?,
    val prizeWon: Int,
    val joinedAt: String
) {
    val formattedAttendanceRate: String
        get() = String.format(Locale.getDefault(), "%.1f%%", attendanceRate)

    val formattedPrizeWon: String
        get() = "${formatNumber(prizeWon)}M"

    val displayName: String
        get() = nickname ?: "User $userId"
}

// Helper functions
private fun formatNumber(value: Int): String {
    return NumberFormat.getNumberInstance(Locale.getDefault()).format(value)
}

private fun parseDate(dateString: String): Date? {
    val formats = listOf(
        SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.getDefault()),
        SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.getDefault()),
        SimpleDateFormat("yyyy-MM-dd", Locale.getDefault())
    )

    for (format in formats) {
        try {
            return format.parse(dateString)
        } catch (e: Exception) {
            // Try next format
        }
    }
    return null
}
