package com.jiny.interval.data.remote.dto

import com.google.gson.annotations.SerializedName

/**
 * Challenge List Response
 */
data class ChallengeListResponse(
    @SerializedName("success") val success: Boolean?,
    @SerializedName("challenges") val challenges: List<ChallengeListItemDto>?,
    @SerializedName("pagination") val pagination: PaginationDto?,
    @SerializedName("error") val error: String?
)

/**
 * Challenge List Item DTO
 */
data class ChallengeListItemDto(
    @SerializedName("id") val id: Int?,
    @SerializedName("shareCode") val shareCode: String?,
    @SerializedName("share_code") val shareCodeSnake: String?,
    @SerializedName("title") val title: String?,
    @SerializedName("description") val description: String?,
    @SerializedName("routineName") val routineName: String?,
    @SerializedName("routine_name") val routineNameSnake: String?,
    @SerializedName("routineData") val routineData: RoutineDataDto?,
    @SerializedName("routine_data") val routineDataSnake: RoutineDataDto?,
    @SerializedName("registrationStartAt") val registrationStartAt: String?,
    @SerializedName("registration_start_at") val registrationStartAtSnake: String?,
    @SerializedName("registrationEndAt") val registrationEndAt: String?,
    @SerializedName("registration_end_at") val registrationEndAtSnake: String?,
    @SerializedName("challengeStartAt") val challengeStartAt: String?,
    @SerializedName("challenge_start_at") val challengeStartAtSnake: String?,
    @SerializedName("challengeEndAt") val challengeEndAt: String?,
    @SerializedName("challenge_end_at") val challengeEndAtSnake: String?,
    @SerializedName("maxParticipants") val maxParticipants: Int?,
    @SerializedName("max_participants") val maxParticipantsSnake: Int?,
    @SerializedName("entryFee") val entryFee: Int?,
    @SerializedName("entry_fee") val entryFeeSnake: Int?,
    @SerializedName("totalPrizePool") val totalPrizePool: Int?,
    @SerializedName("total_prize_pool") val totalPrizePoolSnake: Int?,
    @SerializedName("participantCount") val participantCount: Int?,
    @SerializedName("participant_count") val participantCountSnake: Int?,
    @SerializedName("status") val status: String?,
    @SerializedName("creatorNickname") val creatorNickname: String?,
    @SerializedName("creator_nickname") val creatorNicknameSnake: String?,
    @SerializedName("isParticipating") val isParticipating: Boolean?,
    @SerializedName("is_participating") val isParticipatingSnake: Boolean?,
    @SerializedName("isCreator") val isCreator: Boolean?,
    @SerializedName("is_creator") val isCreatorSnake: Boolean?,
    @SerializedName("todayCompleted") val todayCompleted: Boolean?,
    @SerializedName("today_completed") val todayCompletedSnake: Boolean?,
    @SerializedName("myStats") val myStats: ParticipationStatsDto?,
    @SerializedName("my_stats") val myStatsSnake: ParticipationStatsDto?,
    @SerializedName("createdAt") val createdAt: String?,
    @SerializedName("created_at") val createdAtSnake: String?
)

/**
 * Challenge Detail Response
 */
data class ChallengeDetailResponse(
    @SerializedName("success") val success: Boolean?,
    @SerializedName("challenge") val challenge: ChallengeDto?,
    @SerializedName("participants") val participants: List<ChallengeParticipantDto>?,
    @SerializedName("error") val error: String?
)

/**
 * Full Challenge DTO
 */
data class ChallengeDto(
    @SerializedName("id") val id: Int?,
    @SerializedName("shareCode") val shareCode: String?,
    @SerializedName("share_code") val shareCodeSnake: String?,
    @SerializedName("shareUrl") val shareUrl: String?,
    @SerializedName("share_url") val shareUrlSnake: String?,
    @SerializedName("title") val title: String?,
    @SerializedName("description") val description: String?,
    @SerializedName("routineName") val routineName: String?,
    @SerializedName("routine_name") val routineNameSnake: String?,
    @SerializedName("routineData") val routineData: RoutineDataDto?,
    @SerializedName("routine_data") val routineDataSnake: RoutineDataDto?,
    @SerializedName("registrationStartAt") val registrationStartAt: String?,
    @SerializedName("registration_start_at") val registrationStartAtSnake: String?,
    @SerializedName("registrationEndAt") val registrationEndAt: String?,
    @SerializedName("registration_end_at") val registrationEndAtSnake: String?,
    @SerializedName("challengeStartAt") val challengeStartAt: String?,
    @SerializedName("challenge_start_at") val challengeStartAtSnake: String?,
    @SerializedName("challengeEndAt") val challengeEndAt: String?,
    @SerializedName("challenge_end_at") val challengeEndAtSnake: String?,
    @SerializedName("isPublic") val isPublic: Boolean?,
    @SerializedName("is_public") val isPublicSnake: Boolean?,
    @SerializedName("maxParticipants") val maxParticipants: Int?,
    @SerializedName("max_participants") val maxParticipantsSnake: Int?,
    @SerializedName("entryFee") val entryFee: Int?,
    @SerializedName("entry_fee") val entryFeeSnake: Int?,
    @SerializedName("totalPrizePool") val totalPrizePool: Int?,
    @SerializedName("total_prize_pool") val totalPrizePoolSnake: Int?,
    @SerializedName("participantCount") val participantCount: Int?,
    @SerializedName("participant_count") val participantCountSnake: Int?,
    @SerializedName("status") val status: String?,
    @SerializedName("creatorId") val creatorId: Int?,
    @SerializedName("creator_id") val creatorIdSnake: Int?,
    @SerializedName("creatorNickname") val creatorNickname: String?,
    @SerializedName("creator_nickname") val creatorNicknameSnake: String?,
    @SerializedName("isParticipating") val isParticipating: Boolean?,
    @SerializedName("is_participating") val isParticipatingSnake: Boolean?,
    @SerializedName("canJoin") val canJoin: Boolean?,
    @SerializedName("can_join") val canJoinSnake: Boolean?,
    @SerializedName("canLeave") val canLeave: Boolean?,
    @SerializedName("can_leave") val canLeaveSnake: Boolean?,
    @SerializedName("myRank") val myRank: Int?,
    @SerializedName("my_rank") val myRankSnake: Int?,
    @SerializedName("myParticipation") val myParticipation: ParticipationStatsDto?,
    @SerializedName("my_participation") val myParticipationSnake: ParticipationStatsDto?,
    @SerializedName("totalDays") val totalDays: Int?,
    @SerializedName("total_days") val totalDaysSnake: Int?,
    @SerializedName("createdAt") val createdAt: String?,
    @SerializedName("created_at") val createdAtSnake: String?
)

/**
 * Routine Data for Challenge
 */
data class RoutineDataDto(
    @SerializedName("intervals") val intervals: List<ChallengeIntervalDto>?,
    @SerializedName("rounds") val rounds: Int?
)

/**
 * Challenge Interval
 */
data class ChallengeIntervalDto(
    @SerializedName("name") val name: String?,
    @SerializedName("duration") val duration: Int?,
    @SerializedName("type") val type: String?
)

/**
 * Participation Stats
 */
data class ParticipationStatsDto(
    @SerializedName("completionCount") val completionCount: Int?,
    @SerializedName("completion_count") val completionCountSnake: Int?,
    @SerializedName("attendanceRate") val attendanceRate: Double?,
    @SerializedName("attendance_rate") val attendanceRateSnake: Double?,
    @SerializedName("finalRank") val finalRank: Int?,
    @SerializedName("final_rank") val finalRankSnake: Int?,
    @SerializedName("prizeWon") val prizeWon: Int?,
    @SerializedName("prize_won") val prizeWonSnake: Int?,
    @SerializedName("entryFeePaid") val entryFeePaid: Int?,
    @SerializedName("entry_fee_paid") val entryFeePaidSnake: Int?,
    @SerializedName("joinedAt") val joinedAt: String?,
    @SerializedName("joined_at") val joinedAtSnake: String?
)

/**
 * Challenge Participant
 */
data class ChallengeParticipantDto(
    @SerializedName("rank") val rank: Int?,
    @SerializedName("userId") val userId: Int?,
    @SerializedName("user_id") val userIdSnake: Int?,
    @SerializedName("nickname") val nickname: String?,
    @SerializedName("profileImage") val profileImage: String?,
    @SerializedName("profile_image") val profileImageSnake: String?,
    @SerializedName("completionCount") val completionCount: Int?,
    @SerializedName("completion_count") val completionCountSnake: Int?,
    @SerializedName("attendanceRate") val attendanceRate: Double?,
    @SerializedName("attendance_rate") val attendanceRateSnake: Double?,
    @SerializedName("finalRank") val finalRank: Int?,
    @SerializedName("final_rank") val finalRankSnake: Int?,
    @SerializedName("prizeWon") val prizeWon: Int?,
    @SerializedName("prize_won") val prizeWonSnake: Int?,
    @SerializedName("joinedAt") val joinedAt: String?,
    @SerializedName("joined_at") val joinedAtSnake: String?
)

/**
 * Challenge Create Request
 */
data class ChallengeCreateRequest(
    @SerializedName("title") val title: String,
    @SerializedName("description") val description: String?,
    @SerializedName("routineName") val routineName: String,
    @SerializedName("routineData") val routineData: RoutineDataDto,
    @SerializedName("registrationEndAt") val registrationEndAt: String,
    @SerializedName("challengeStartAt") val challengeStartAt: String,
    @SerializedName("challengeEndAt") val challengeEndAt: String,
    @SerializedName("entryFee") val entryFee: Int,
    @SerializedName("isPublic") val isPublic: Boolean,
    @SerializedName("maxParticipants") val maxParticipants: Int?
)

/**
 * Challenge Create Response
 */
data class ChallengeCreateResponse(
    @SerializedName("success") val success: Boolean,
    @SerializedName("challenge") val challenge: ChallengeDto?,
    @SerializedName("shareUrl") val shareUrl: String?,
    @SerializedName("error") val error: String?
)

/**
 * Challenge Join Request
 */
data class ChallengeJoinRequest(
    @SerializedName("challengeId") val challengeId: Int
)

/**
 * Challenge Join Response
 */
data class ChallengeJoinResponse(
    @SerializedName("success") val success: Boolean,
    @SerializedName("message") val message: String?,
    @SerializedName("challenge") val challenge: ChallengeJoinInfoDto?,
    @SerializedName("entryFeePaid") val entryFeePaid: Int?,
    @SerializedName("error") val error: String?
)

data class ChallengeJoinInfoDto(
    @SerializedName("id") val id: Int,
    @SerializedName("shareCode") val shareCode: String,
    @SerializedName("title") val title: String,
    @SerializedName("participantCount") val participantCount: Int,
    @SerializedName("totalPrizePool") val totalPrizePool: Int
)

/**
 * Challenge Leave Request
 */
data class ChallengeLeaveRequest(
    @SerializedName("challengeId") val challengeId: Int
)

/**
 * Challenge Leave Response
 */
data class ChallengeLeaveResponse(
    @SerializedName("success") val success: Boolean,
    @SerializedName("message") val message: String?,
    @SerializedName("refundedAmount") val refundedAmount: Int?,
    @SerializedName("error") val error: String?
)

/**
 * Pagination
 */
data class PaginationDto(
    @SerializedName("page") val page: Int,
    @SerializedName("limit") val limit: Int,
    @SerializedName("total") val total: Int,
    @SerializedName("totalPages") val totalPages: Int
)
