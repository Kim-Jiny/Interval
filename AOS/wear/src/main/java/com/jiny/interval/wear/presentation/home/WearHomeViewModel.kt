package com.jiny.interval.wear.presentation.home

import androidx.lifecycle.ViewModel
import com.jiny.interval.wear.domain.model.WearInterval
import com.jiny.interval.wear.domain.model.WearRoutine
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import java.util.UUID
import javax.inject.Inject

@HiltViewModel
class WearHomeViewModel @Inject constructor() : ViewModel() {

    private val _routines = MutableStateFlow(getDefaultRoutines())
    val routines: StateFlow<List<WearRoutine>> = _routines.asStateFlow()

    private fun getDefaultRoutines(): List<WearRoutine> {
        return listOf(
            WearRoutine(
                id = UUID.randomUUID().toString(),
                name = "Tabata",
                intervals = listOf(
                    WearInterval(UUID.randomUUID().toString(), "Work", 20, "WORKOUT"),
                    WearInterval(UUID.randomUUID().toString(), "Rest", 10, "REST")
                ),
                rounds = 8
            ),
            WearRoutine(
                id = UUID.randomUUID().toString(),
                name = "HIIT",
                intervals = listOf(
                    WearInterval(UUID.randomUUID().toString(), "Warmup", 60, "WARMUP"),
                    WearInterval(UUID.randomUUID().toString(), "Work", 30, "WORKOUT"),
                    WearInterval(UUID.randomUUID().toString(), "Rest", 15, "REST"),
                    WearInterval(UUID.randomUUID().toString(), "Cooldown", 60, "COOLDOWN")
                ),
                rounds = 4
            ),
            WearRoutine(
                id = UUID.randomUUID().toString(),
                name = "Quick Workout",
                intervals = listOf(
                    WearInterval(UUID.randomUUID().toString(), "Exercise", 45, "WORKOUT"),
                    WearInterval(UUID.randomUUID().toString(), "Rest", 15, "REST")
                ),
                rounds = 5
            )
        )
    }

    fun getRoutine(index: Int): WearRoutine? {
        return _routines.value.getOrNull(index)
    }
}
