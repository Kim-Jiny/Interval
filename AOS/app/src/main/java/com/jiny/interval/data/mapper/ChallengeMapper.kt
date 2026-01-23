package com.jiny.interval.data.mapper

import com.jiny.interval.data.remote.dto.ChallengeDto
import com.jiny.interval.data.remote.dto.ChallengeIntervalDto
import com.jiny.interval.data.remote.dto.ChallengeListItemDto
import com.jiny.interval.data.remote.dto.ChallengeParticipantDto
import com.jiny.interval.data.remote.dto.MileageBalanceDto
import com.jiny.interval.data.remote.dto.MileageTransactionDto
import com.jiny.interval.data.remote.dto.ParticipationStatsDto
import com.jiny.interval.data.remote.dto.RoutineDataDto
import com.jiny.interval.domain.model.Challenge
import com.jiny.interval.domain.model.ChallengeInterval
import com.jiny.interval.domain.model.ChallengeListItem
import com.jiny.interval.domain.model.ChallengeParticipant
import com.jiny.interval.domain.model.ChallengeRoutineData
import com.jiny.interval.domain.model.ChallengeStatus
import com.jiny.interval.domain.model.MileageBalance
import com.jiny.interval.domain.model.MileageTransaction
import com.jiny.interval.domain.model.MileageTransactionType
import com.jiny.interval.domain.model.ParticipationStats

// Challenge List Item Mapping
fun ChallengeListItemDto.toDomain(): ChallengeListItem {
    return ChallengeListItem(
        id = id ?: 0,
        shareCode = shareCode ?: shareCodeSnake ?: "",
        title = title ?: "",
        description = description,
        routineName = routineName ?: routineNameSnake ?: "",
        routineData = (routineData ?: routineDataSnake)?.toDomain(),
        registrationStartAt = registrationStartAt ?: registrationStartAtSnake ?: "",
        registrationEndAt = registrationEndAt ?: registrationEndAtSnake ?: "",
        challengeStartAt = challengeStartAt ?: challengeStartAtSnake ?: "",
        challengeEndAt = challengeEndAt ?: challengeEndAtSnake ?: "",
        maxParticipants = maxParticipants ?: maxParticipantsSnake,
        entryFee = entryFee ?: entryFeeSnake ?: 0,
        totalPrizePool = totalPrizePool ?: totalPrizePoolSnake ?: 0,
        participantCount = participantCount ?: participantCountSnake ?: 0,
        status = ChallengeStatus.fromValue(status ?: "registration"),
        creatorNickname = creatorNickname ?: creatorNicknameSnake,
        isParticipating = isParticipating ?: isParticipatingSnake ?: false,
        isCreator = isCreator ?: isCreatorSnake,
        todayCompleted = todayCompleted ?: todayCompletedSnake,
        myStats = (myStats ?: myStatsSnake)?.toDomain(),
        createdAt = createdAt ?: createdAtSnake ?: ""
    )
}

// Full Challenge Mapping
fun ChallengeDto.toDomain(): Challenge {
    return Challenge(
        id = id ?: 0,
        shareCode = shareCode ?: shareCodeSnake ?: "",
        shareUrl = shareUrl ?: shareUrlSnake,
        title = title ?: "",
        description = description,
        routineName = routineName ?: routineNameSnake ?: "",
        routineData = (routineData ?: routineDataSnake)?.toDomain(),
        registrationStartAt = registrationStartAt ?: registrationStartAtSnake ?: "",
        registrationEndAt = registrationEndAt ?: registrationEndAtSnake ?: "",
        challengeStartAt = challengeStartAt ?: challengeStartAtSnake ?: "",
        challengeEndAt = challengeEndAt ?: challengeEndAtSnake ?: "",
        isPublic = isPublic ?: isPublicSnake,
        maxParticipants = maxParticipants ?: maxParticipantsSnake,
        entryFee = entryFee ?: entryFeeSnake ?: 0,
        totalPrizePool = totalPrizePool ?: totalPrizePoolSnake ?: 0,
        participantCount = participantCount ?: participantCountSnake ?: 0,
        status = ChallengeStatus.fromValue(status ?: "registration"),
        creatorId = creatorId ?: creatorIdSnake,
        creatorNickname = creatorNickname ?: creatorNicknameSnake,
        isParticipating = isParticipating ?: isParticipatingSnake,
        canJoin = canJoin ?: canJoinSnake,
        canLeave = canLeave ?: canLeaveSnake,
        myRank = myRank ?: myRankSnake,
        myParticipation = (myParticipation ?: myParticipationSnake)?.toDomain(),
        totalDays = totalDays ?: totalDaysSnake,
        createdAt = createdAt ?: createdAtSnake ?: ""
    )
}

fun RoutineDataDto.toDomain(): ChallengeRoutineData {
    return ChallengeRoutineData(
        intervals = intervals?.map { it.toDomain() } ?: emptyList(),
        rounds = rounds ?: 1
    )
}

fun ChallengeIntervalDto.toDomain(): ChallengeInterval {
    return ChallengeInterval(
        name = name ?: "",
        duration = duration ?: 0,
        type = type ?: "workout"
    )
}

fun ParticipationStatsDto.toDomain(): ParticipationStats {
    return ParticipationStats(
        completionCount = completionCount ?: completionCountSnake ?: 0,
        attendanceRate = attendanceRate ?: attendanceRateSnake ?: 0.0,
        finalRank = finalRank ?: finalRankSnake,
        prizeWon = prizeWon ?: prizeWonSnake ?: 0,
        entryFeePaid = entryFeePaid ?: entryFeePaidSnake ?: 0,
        joinedAt = joinedAt ?: joinedAtSnake
    )
}

fun ChallengeParticipantDto.toDomain(): ChallengeParticipant {
    return ChallengeParticipant(
        rank = rank ?: 0,
        userId = userId ?: userIdSnake ?: 0,
        nickname = nickname,
        profileImage = profileImage ?: profileImageSnake,
        completionCount = completionCount ?: completionCountSnake ?: 0,
        attendanceRate = attendanceRate ?: attendanceRateSnake ?: 0.0,
        finalRank = finalRank ?: finalRankSnake,
        prizeWon = prizeWon ?: prizeWonSnake ?: 0,
        joinedAt = joinedAt ?: joinedAtSnake ?: ""
    )
}

// Mileage Mapping
fun MileageBalanceDto.toDomain(): MileageBalance {
    return MileageBalance(
        balance = balance ?: 0,
        totalEarned = totalEarned ?: totalEarnedSnake ?: 0,
        totalSpent = totalSpent ?: totalSpentSnake ?: 0
    )
}

fun MileageTransactionDto.toDomain(): MileageTransaction {
    return MileageTransaction(
        id = id ?: 0,
        amount = amount ?: 0,
        balanceAfter = balanceAfter ?: balanceAfterSnake ?: 0,
        type = MileageTransactionType.fromValue(type ?: "admin"),
        referenceType = referenceType ?: referenceTypeSnake,
        referenceId = referenceId ?: referenceIdSnake,
        description = description,
        createdAt = createdAt ?: createdAtSnake ?: ""
    )
}
