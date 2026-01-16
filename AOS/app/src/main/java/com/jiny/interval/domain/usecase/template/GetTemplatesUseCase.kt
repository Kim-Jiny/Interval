package com.jiny.interval.domain.usecase.template

import com.jiny.interval.domain.model.IntervalType
import com.jiny.interval.domain.model.Routine
import com.jiny.interval.domain.model.WorkoutInterval
import com.jiny.interval.domain.provider.StringProvider
import javax.inject.Inject

class GetTemplatesUseCase @Inject constructor(
    private val stringProvider: StringProvider
) {
    operator fun invoke(): List<Routine> = listOf(
        createEmptyTemplate(),
        createTabataTemplate(),
        createRunningIntervalsTemplate(),
        createPlankChallengeTemplate(),
        createLegRaisesTemplate(),
        createHiitCircuitTemplate(),
        createStretchingTemplate()
    )

    private fun createEmptyTemplate() = Routine(
        name = stringProvider.templateEmpty(),
        intervals = listOf(
            WorkoutInterval(name = stringProvider.intervalWorkout(), duration = 30, type = IntervalType.WORKOUT)
        ),
        rounds = 1
    )

    private fun createTabataTemplate() = Routine(
        name = stringProvider.templateTabata(),
        intervals = listOf(
            WorkoutInterval(name = stringProvider.intervalWork(), duration = 20, type = IntervalType.WORKOUT),
            WorkoutInterval(name = stringProvider.intervalRest(), duration = 10, type = IntervalType.REST)
        ),
        rounds = 8
    )

    private fun createRunningIntervalsTemplate() = Routine(
        name = stringProvider.templateRunning(),
        intervals = listOf(
            WorkoutInterval(name = stringProvider.intervalWarmup(), duration = 300, type = IntervalType.WARMUP),
            WorkoutInterval(name = stringProvider.intervalRun(), duration = 60, type = IntervalType.WORKOUT),
            WorkoutInterval(name = stringProvider.intervalWalk(), duration = 90, type = IntervalType.REST),
            WorkoutInterval(name = stringProvider.intervalCooldown(), duration = 300, type = IntervalType.COOLDOWN)
        ),
        rounds = 5
    )

    private fun createPlankChallengeTemplate() = Routine(
        name = stringProvider.templatePlank(),
        intervals = listOf(
            WorkoutInterval(name = stringProvider.intervalPlank(), duration = 30, type = IntervalType.WORKOUT),
            WorkoutInterval(name = stringProvider.intervalRest(), duration = 15, type = IntervalType.REST)
        ),
        rounds = 5
    )

    private fun createLegRaisesTemplate() = Routine(
        name = stringProvider.templateLegRaises(),
        intervals = listOf(
            WorkoutInterval(name = stringProvider.intervalLegRaises(), duration = 30, type = IntervalType.WORKOUT),
            WorkoutInterval(name = stringProvider.intervalRest(), duration = 20, type = IntervalType.REST)
        ),
        rounds = 4
    )

    private fun createHiitCircuitTemplate() = Routine(
        name = stringProvider.templateHiit(),
        intervals = listOf(
            WorkoutInterval(name = stringProvider.intervalWarmup(), duration = 120, type = IntervalType.WARMUP),
            WorkoutInterval(name = stringProvider.intervalBurpees(), duration = 30, type = IntervalType.WORKOUT),
            WorkoutInterval(name = stringProvider.intervalRest(), duration = 15, type = IntervalType.REST),
            WorkoutInterval(name = stringProvider.intervalJumpSquats(), duration = 30, type = IntervalType.WORKOUT),
            WorkoutInterval(name = stringProvider.intervalRest(), duration = 15, type = IntervalType.REST),
            WorkoutInterval(name = stringProvider.intervalMountainClimbers(), duration = 30, type = IntervalType.WORKOUT),
            WorkoutInterval(name = stringProvider.intervalRest(), duration = 15, type = IntervalType.REST),
            WorkoutInterval(name = stringProvider.intervalPushUps(), duration = 30, type = IntervalType.WORKOUT),
            WorkoutInterval(name = stringProvider.intervalCooldown(), duration = 120, type = IntervalType.COOLDOWN)
        ),
        rounds = 3
    )

    private fun createStretchingTemplate() = Routine(
        name = stringProvider.templateStretching(),
        intervals = listOf(
            WorkoutInterval(name = stringProvider.intervalNeckStretch(), duration = 30, type = IntervalType.WORKOUT),
            WorkoutInterval(name = stringProvider.intervalShoulderStretch(), duration = 30, type = IntervalType.WORKOUT),
            WorkoutInterval(name = stringProvider.intervalArmStretch(), duration = 30, type = IntervalType.WORKOUT),
            WorkoutInterval(name = stringProvider.intervalBackStretch(), duration = 30, type = IntervalType.WORKOUT),
            WorkoutInterval(name = stringProvider.intervalHipStretch(), duration = 30, type = IntervalType.WORKOUT),
            WorkoutInterval(name = stringProvider.intervalLegStretch(), duration = 30, type = IntervalType.WORKOUT),
            WorkoutInterval(name = stringProvider.intervalCalfStretch(), duration = 30, type = IntervalType.WORKOUT)
        ),
        rounds = 2
    )
}
