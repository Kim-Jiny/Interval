package com.jiny.interval.wear.presentation.home

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.wear.compose.foundation.lazy.ScalingLazyColumn
import androidx.wear.compose.foundation.lazy.itemsIndexed
import androidx.wear.compose.foundation.lazy.rememberScalingLazyListState
import androidx.wear.compose.material.Card
import androidx.wear.compose.material.MaterialTheme
import androidx.wear.compose.material.PositionIndicator
import androidx.wear.compose.material.Scaffold
import androidx.wear.compose.material.Text
import androidx.wear.compose.material.TimeText
import com.jiny.interval.wear.domain.model.WearRoutine
import com.jiny.interval.wear.presentation.theme.CooldownColor
import com.jiny.interval.wear.presentation.theme.RestColor
import com.jiny.interval.wear.presentation.theme.WarmupColor
import com.jiny.interval.wear.presentation.theme.WorkoutColor

@Composable
fun WearHomeScreen(
    onRoutineClick: (Int) -> Unit,
    viewModel: WearHomeViewModel = hiltViewModel()
) {
    val routines by viewModel.routines.collectAsState()
    val listState = rememberScalingLazyListState()

    Scaffold(
        timeText = { TimeText() },
        positionIndicator = { PositionIndicator(scalingLazyListState = listState) }
    ) {
        if (routines.isEmpty()) {
            EmptyState()
        } else {
            ScalingLazyColumn(
                state = listState,
                modifier = Modifier.fillMaxSize()
            ) {
                item {
                    Text(
                        text = "Routines",
                        style = MaterialTheme.typography.title3,
                        modifier = Modifier.padding(bottom = 8.dp)
                    )
                }

                itemsIndexed(routines) { index, routine ->
                    RoutineChip(
                        routine = routine,
                        onClick = { onRoutineClick(index) }
                    )
                }
            }
        }
    }
}

@Composable
private fun EmptyState() {
    Box(
        modifier = Modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(
                text = "No routines",
                style = MaterialTheme.typography.body1,
                textAlign = TextAlign.Center
            )
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = "Add routines on your phone",
                style = MaterialTheme.typography.caption2,
                color = MaterialTheme.colors.onSurfaceVariant,
                textAlign = TextAlign.Center
            )
        }
    }
}

@Composable
private fun RoutineChip(
    routine: WearRoutine,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Card(
        onClick = onClick,
        modifier = modifier.fillMaxWidth()
    ) {
        Column(
            modifier = Modifier.padding(8.dp)
        ) {
            Text(
                text = routine.name,
                style = MaterialTheme.typography.title3,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
            Spacer(modifier = Modifier.height(4.dp))
            Text(
                text = "${routine.rounds} rounds",
                style = MaterialTheme.typography.caption2,
                color = MaterialTheme.colors.onSurfaceVariant
            )
            Spacer(modifier = Modifier.height(8.dp))
            Row(
                horizontalArrangement = Arrangement.spacedBy(4.dp)
            ) {
                routine.intervals.take(5).forEach { interval ->
                    val color = when (interval.type) {
                        "WORKOUT" -> WorkoutColor
                        "REST" -> RestColor
                        "WARMUP" -> WarmupColor
                        "COOLDOWN" -> CooldownColor
                        else -> WorkoutColor
                    }
                    Box(
                        modifier = Modifier
                            .size(6.dp)
                            .clip(CircleShape)
                            .background(color)
                    )
                }
                if (routine.intervals.size > 5) {
                    Text(
                        text = "+${routine.intervals.size - 5}",
                        style = MaterialTheme.typography.caption3,
                        color = MaterialTheme.colors.onSurfaceVariant
                    )
                }
            }
        }
    }
}
