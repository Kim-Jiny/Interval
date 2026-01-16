package com.jiny.interval.presentation.timer

import androidx.activity.compose.BackHandler
import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.tween
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
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Pause
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material.icons.filled.SkipNext
import androidx.compose.material.icons.filled.SkipPrevious
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.FilledIconButton
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.IconButtonDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.jiny.interval.R
import com.jiny.interval.domain.model.IntervalType
import com.jiny.interval.presentation.components.IntervalDotsIndicator
import com.jiny.interval.presentation.components.LinearProgressBar
import com.jiny.interval.presentation.components.RoundIndicator
import com.jiny.interval.presentation.components.TimerDisplay
import com.jiny.interval.presentation.components.toColor
import com.jiny.interval.util.TimeFormatter

@Composable
fun TimerScreen(
    onNavigateBack: () -> Unit,
    viewModel: TimerViewModel = hiltViewModel()
) {
    val routine by viewModel.routine.collectAsState()
    val timerState by viewModel.timerState.collectAsState()
    val settings by viewModel.settings.collectAsState()

    var showExitDialog by remember { mutableStateOf(false) }

    val currentInterval = viewModel.getCurrentInterval()
    val nextInterval = viewModel.getNextInterval()

    val backgroundColor by animateColorAsState(
        targetValue = currentInterval?.type?.toColor() ?: MaterialTheme.colorScheme.primary,
        animationSpec = tween(durationMillis = 300),
        label = "backgroundColor"
    )

    BackHandler {
        if (timerState.isRunning) {
            showExitDialog = true
        } else {
            onNavigateBack()
        }
    }

    routine?.let { currentRoutine ->
        val totalDuration = currentInterval?.duration?.times(1000) ?: 1
        val progress = timerState.timeRemaining.toFloat() / totalDuration.toFloat()

        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(backgroundColor)
        ) {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(24.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                // Top bar
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    IconButton(
                        onClick = {
                            if (timerState.isRunning) {
                                showExitDialog = true
                            } else {
                                onNavigateBack()
                            }
                        }
                    ) {
                        Icon(
                            imageVector = Icons.Default.Close,
                            contentDescription = stringResource(R.string.close),
                            tint = Color.White
                        )
                    }

                    Text(
                        text = currentRoutine.name,
                        style = MaterialTheme.typography.titleMedium,
                        color = Color.White
                    )

                    IconButton(onClick = { viewModel.resetTimer() }) {
                        Icon(
                            imageVector = Icons.Default.Refresh,
                            contentDescription = stringResource(R.string.reset),
                            tint = Color.White
                        )
                    }
                }

                Spacer(modifier = Modifier.height(32.dp))

                // Round indicator
                RoundIndicator(
                    currentRound = timerState.currentRound,
                    totalRounds = currentRoutine.rounds
                )

                Spacer(modifier = Modifier.height(24.dp))

                // Current interval name
                Text(
                    text = currentInterval?.name ?: "",
                    style = MaterialTheme.typography.headlineMedium.copy(
                        fontWeight = FontWeight.Bold
                    ),
                    color = Color.White
                )

                Spacer(modifier = Modifier.weight(1f))

                // Timer display
                if (timerState.isCompleted) {
                    Text(
                        text = stringResource(R.string.workout_complete),
                        style = MaterialTheme.typography.displaySmall,
                        color = Color.White
                    )
                } else {
                    TimerDisplay(
                        timeRemaining = timerState.timeRemaining,
                        textColor = Color.White
                    )
                }

                Spacer(modifier = Modifier.height(24.dp))

                // Progress bar
                LinearProgressBar(
                    progress = progress,
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 32.dp)
                )

                Spacer(modifier = Modifier.height(16.dp))

                // Interval dots
                IntervalDotsIndicator(
                    totalIntervals = currentRoutine.intervals.size,
                    currentIntervalIndex = timerState.currentIntervalIndex
                )

                Spacer(modifier = Modifier.weight(1f))

                // Next interval preview
                nextInterval?.let { next ->
                    Column(
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Text(
                            text = stringResource(R.string.next),
                            style = MaterialTheme.typography.labelMedium,
                            color = Color.White.copy(alpha = 0.7f)
                        )
                        Spacer(modifier = Modifier.height(4.dp))
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            Box(
                                modifier = Modifier
                                    .size(8.dp)
                                    .clip(CircleShape)
                                    .background(next.type.toColor().copy(alpha = 0.8f))
                            )
                            Text(
                                text = "${next.name} · ${TimeFormatter.formatDuration(next.duration)}",
                                style = MaterialTheme.typography.bodyMedium,
                                color = Color.White.copy(alpha = 0.9f)
                            )
                        }
                    }
                }

                Spacer(modifier = Modifier.height(32.dp))

                // Control buttons
                Row(
                    horizontalArrangement = Arrangement.spacedBy(24.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    FilledIconButton(
                        onClick = { viewModel.skipToPreviousInterval() },
                        modifier = Modifier.size(56.dp),
                        colors = IconButtonDefaults.filledIconButtonColors(
                            containerColor = Color.White.copy(alpha = 0.2f)
                        )
                    ) {
                        Icon(
                            imageVector = Icons.Default.SkipPrevious,
                            contentDescription = stringResource(R.string.previous),
                            tint = Color.White,
                            modifier = Modifier.size(32.dp)
                        )
                    }

                    FilledIconButton(
                        onClick = { viewModel.toggleTimer() },
                        modifier = Modifier.size(80.dp),
                        colors = IconButtonDefaults.filledIconButtonColors(
                            containerColor = Color.White
                        )
                    ) {
                        Icon(
                            imageVector = if (timerState.isRunning) Icons.Default.Pause else Icons.Default.PlayArrow,
                            contentDescription = if (timerState.isRunning) stringResource(R.string.pause) else stringResource(R.string.play),
                            tint = backgroundColor,
                            modifier = Modifier.size(48.dp)
                        )
                    }

                    FilledIconButton(
                        onClick = { viewModel.skipToNextInterval() },
                        modifier = Modifier.size(56.dp),
                        colors = IconButtonDefaults.filledIconButtonColors(
                            containerColor = Color.White.copy(alpha = 0.2f)
                        )
                    ) {
                        Icon(
                            imageVector = Icons.Default.SkipNext,
                            contentDescription = stringResource(R.string.next),
                            tint = Color.White,
                            modifier = Modifier.size(32.dp)
                        )
                    }
                }

                Spacer(modifier = Modifier.height(32.dp))
            }
        }
    }

    if (showExitDialog) {
        AlertDialog(
            onDismissRequest = { showExitDialog = false },
            title = { Text(stringResource(R.string.exit_timer)) },
            text = { Text(stringResource(R.string.exit_timer_message)) },
            confirmButton = {
                TextButton(
                    onClick = {
                        viewModel.pauseTimer()
                        showExitDialog = false
                        onNavigateBack()
                    }
                ) {
                    Text(stringResource(R.string.exit), color = MaterialTheme.colorScheme.error)
                }
            },
            dismissButton = {
                TextButton(onClick = { showExitDialog = false }) {
                    Text(stringResource(R.string.continue_workout))
                }
            }
        )
    }
}
