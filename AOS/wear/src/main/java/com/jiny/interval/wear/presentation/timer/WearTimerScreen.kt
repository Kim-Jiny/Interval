package com.jiny.interval.wear.presentation.timer

import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.wear.compose.material.Button
import androidx.wear.compose.material.ButtonDefaults
import androidx.wear.compose.material.Icon
import androidx.wear.compose.material.MaterialTheme
import androidx.wear.compose.material.Scaffold
import androidx.wear.compose.material.Text
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Pause
import androidx.compose.material.icons.filled.PlayArrow
import com.jiny.interval.wear.presentation.theme.CooldownColor
import com.jiny.interval.wear.presentation.theme.RestColor
import com.jiny.interval.wear.presentation.theme.WarmupColor
import com.jiny.interval.wear.presentation.theme.WorkoutColor

@Composable
fun WearTimerScreen(
    routineIndex: Int,
    onNavigateBack: () -> Unit,
    viewModel: WearTimerViewModel = hiltViewModel()
) {
    val routine by viewModel.routine.collectAsState()
    val timerState by viewModel.timerState.collectAsState()

    LaunchedEffect(routineIndex) {
        viewModel.loadRoutine(routineIndex)
    }

    val currentInterval = routine?.intervals?.getOrNull(timerState.currentIntervalIndex)
    val backgroundColor by animateColorAsState(
        targetValue = when (currentInterval?.type) {
            "WORKOUT" -> WorkoutColor
            "REST" -> RestColor
            "WARMUP" -> WarmupColor
            "COOLDOWN" -> CooldownColor
            else -> MaterialTheme.colors.background
        },
        animationSpec = tween(durationMillis = 300),
        label = "backgroundColor"
    )

    Scaffold {
        routine?.let { currentRoutine ->
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(backgroundColor),
                contentAlignment = Alignment.Center
            ) {
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally,
                    modifier = Modifier.padding(16.dp)
                ) {
                    // Round indicator
                    Text(
                        text = "Round ${timerState.currentRound}/${currentRoutine.rounds}",
                        style = MaterialTheme.typography.caption1,
                        color = Color.White.copy(alpha = 0.8f)
                    )

                    Spacer(modifier = Modifier.height(4.dp))

                    // Current interval name
                    Text(
                        text = currentInterval?.name ?: "",
                        style = MaterialTheme.typography.title3,
                        color = Color.White,
                        textAlign = TextAlign.Center
                    )

                    Spacer(modifier = Modifier.height(8.dp))

                    // Timer display
                    if (timerState.isCompleted) {
                        Text(
                            text = "Done!",
                            style = MaterialTheme.typography.display1,
                            color = Color.White
                        )
                    } else {
                        val minutes = timerState.timeRemaining / 60000
                        val seconds = (timerState.timeRemaining % 60000) / 1000

                        Text(
                            text = String.format("%02d:%02d", minutes, seconds),
                            fontSize = 48.sp,
                            fontWeight = FontWeight.Bold,
                            color = Color.White
                        )
                    }

                    Spacer(modifier = Modifier.height(8.dp))

                    // Interval dots
                    Row(
                        horizontalArrangement = Arrangement.spacedBy(4.dp)
                    ) {
                        currentRoutine.intervals.forEachIndexed { index, _ ->
                            Box(
                                modifier = Modifier
                                    .size(if (index == timerState.currentIntervalIndex) 8.dp else 6.dp)
                                    .clip(CircleShape)
                                    .background(
                                        if (index <= timerState.currentIntervalIndex)
                                            Color.White
                                        else
                                            Color.White.copy(alpha = 0.3f)
                                    )
                            )
                        }
                    }

                    Spacer(modifier = Modifier.height(16.dp))

                    // Play/Pause button
                    Button(
                        onClick = { viewModel.toggleTimer() },
                        modifier = Modifier.size(48.dp),
                        colors = ButtonDefaults.buttonColors(
                            backgroundColor = Color.White.copy(alpha = 0.2f)
                        )
                    ) {
                        Icon(
                            imageVector = if (timerState.isRunning) Icons.Default.Pause else Icons.Default.PlayArrow,
                            contentDescription = if (timerState.isRunning) "Pause" else "Play",
                            tint = Color.White,
                            modifier = Modifier.size(24.dp)
                        )
                    }
                }
            }
        }
    }
}
