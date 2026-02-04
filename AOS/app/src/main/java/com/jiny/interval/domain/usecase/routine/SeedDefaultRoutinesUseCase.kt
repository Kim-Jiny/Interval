package com.jiny.interval.domain.usecase.routine

import com.jiny.interval.domain.model.IntervalType
import com.jiny.interval.domain.model.Routine
import com.jiny.interval.domain.model.WorkoutInterval
import com.jiny.interval.domain.provider.StringProvider
import com.jiny.interval.domain.repository.RoutineRepository
import javax.inject.Inject

class SeedDefaultRoutinesUseCase @Inject constructor(
    private val repository: RoutineRepository,
    private val stringProvider: StringProvider
) {
    suspend operator fun invoke() {
        if (repository.getRoutineCount() > 0) return

        val now = System.currentTimeMillis()
        val routines = listOf(
            createBasicIntervalRoutine(now),
            createTabataRoutine(now)
        )

        routines.forEach { routine ->
            repository.saveRoutine(routine)
        }
    }

    private fun createBasicIntervalRoutine(timestamp: Long) = Routine(
        name = stringProvider.templateBasicInterval(),
        intervals = listOf(
            WorkoutInterval(name = stringProvider.intervalWarmup(), duration = 10, type = IntervalType.WARMUP),
            WorkoutInterval(name = stringProvider.intervalWorkout(), duration = 30, type = IntervalType.WORKOUT),
            WorkoutInterval(name = stringProvider.intervalRest(), duration = 10, type = IntervalType.REST),
            WorkoutInterval(name = stringProvider.intervalWorkout(), duration = 30, type = IntervalType.WORKOUT),
            WorkoutInterval(name = stringProvider.intervalRest(), duration = 10, type = IntervalType.REST),
            WorkoutInterval(name = stringProvider.intervalCooldown(), duration = 10, type = IntervalType.COOLDOWN)
        ),
        rounds = 3,
        createdAt = timestamp,
        updatedAt = timestamp
    )

    private fun createTabataRoutine(timestamp: Long) = Routine(
        name = stringProvider.templateTabata(),
        intervals = listOf(
            WorkoutInterval(name = stringProvider.intervalWarmup(), duration = 10, type = IntervalType.WARMUP),
            WorkoutInterval(name = stringProvider.intervalWorkout(), duration = 20, type = IntervalType.WORKOUT),
            WorkoutInterval(name = stringProvider.intervalRest(), duration = 10, type = IntervalType.REST)
        ),
        rounds = 8,
        createdAt = timestamp,
        updatedAt = timestamp
    )
}
