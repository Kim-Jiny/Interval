package com.jiny.interval.presentation.home

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.EmojiEvents
import androidx.compose.material.icons.filled.Star
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.Lifecycle
import java.util.Calendar
import androidx.lifecycle.LifecycleEventObserver
import androidx.lifecycle.compose.LocalLifecycleOwner
import com.jiny.interval.R
import com.jiny.interval.domain.model.ChallengeListItem
import com.jiny.interval.domain.model.ChallengeStatus
import com.jiny.interval.domain.model.Routine
import com.jiny.interval.presentation.components.BackgroundDecoration
import com.jiny.interval.presentation.components.RoutineCard

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HomeScreen(
    onRoutineClick: (String) -> Unit,
    onEditRoutine: (String) -> Unit,
    onAddRoutine: () -> Unit,
    onSettingsClick: () -> Unit,
    onChallengeClick: (Int) -> Unit = {},
    onNavigateToLogin: () -> Unit = {},
    onStartChallengeWorkout: (Int) -> Unit = {},
    viewModel: HomeViewModel = hiltViewModel()
) {
    val allRoutines by viewModel.allRoutines.collectAsState()
    val favoriteRoutines by viewModel.favoriteRoutines.collectAsState()
    val activeChallenges by viewModel.activeChallenges.collectAsState()
    val isLoggedIn by viewModel.isLoggedIn.collectAsState()

    val lifecycleOwner = LocalLifecycleOwner.current

    // Reload challenges when screen becomes visible
    DisposableEffect(lifecycleOwner) {
        val observer = LifecycleEventObserver { _, event ->
            if (event == Lifecycle.Event.ON_RESUME) {
                viewModel.loadChallenges()
            }
        }
        lifecycleOwner.lifecycle.addObserver(observer)
        onDispose {
            lifecycleOwner.lifecycle.removeObserver(observer)
        }
    }

    var routineToDelete by remember { mutableStateOf<Routine?>(null) }

    val regularRoutines = remember(allRoutines, favoriteRoutines) {
        val favoritesSet = favoriteRoutines.map { it.id }.toSet()
        allRoutines.filterNot { favoritesSet.contains(it.id) }
    }

    val greetingText = remember {
        val hour = Calendar.getInstance().get(Calendar.HOUR_OF_DAY)
        when {
            hour < 12 -> R.string.greeting_morning
            hour < 17 -> R.string.greeting_afternoon
            else -> R.string.greeting_evening
        }
    }

    Scaffold(
        contentWindowInsets = WindowInsets(0, 0, 0, 0),
        topBar = {
            TopAppBar(
                title = { Text(stringResource(greetingText)) }
            )
        },
        floatingActionButton = {
            FloatingActionButton(onClick = onAddRoutine) {
                Icon(
                    imageVector = Icons.Default.Add,
                    contentDescription = stringResource(R.string.add_interval)
                )
            }
        }
    ) { paddingValues ->
        val showEmpty = activeChallenges.isEmpty() && allRoutines.isEmpty()
        val isDarkTheme = isSystemInDarkTheme()
        val backgroundBrush = Brush.verticalGradient(
            colors = if (isDarkTheme) {
                listOf(
                    MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.35f),
                    MaterialTheme.colorScheme.background
                )
            } else {
                listOf(
                    MaterialTheme.colorScheme.primary.copy(alpha = 0.06f),
                    MaterialTheme.colorScheme.background
                )
            }
        )
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(backgroundBrush)
                .padding(paddingValues)
        ) {
            BackgroundDecoration()
            AnimatedVisibility(
                visible = showEmpty,
                enter = fadeIn(),
                exit = fadeOut()
            ) {
                EmptyHomeState(
                    onAddRoutine = onAddRoutine,
                    modifier = Modifier.fillMaxSize()
                )
            }

            AnimatedVisibility(
                visible = !showEmpty,
                enter = fadeIn(),
                exit = fadeOut()
            ) {
                LazyColumn(
                    modifier = Modifier.fillMaxSize(),
                    contentPadding = PaddingValues(
                        start = 16.dp,
                        end = 16.dp,
                        top = 8.dp,
                        bottom = 96.dp
                    ),
                    verticalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    if (!isLoggedIn) {
                        item {
                            LoginPromptCard(onNavigateToLogin = onNavigateToLogin)
                        }
                    }

                    if (isLoggedIn && activeChallenges.isNotEmpty()) {
                        item {
                            SectionHeader(
                                title = stringResource(R.string.challenge),
                                icon = Icons.Default.EmojiEvents,
                                tint = MaterialTheme.colorScheme.secondary
                            )
                        }
                        items(
                            items = activeChallenges,
                            key = { it.id }
                        ) { challenge ->
                            ActiveChallengeCard(
                                challenge = challenge,
                                onClick = { onChallengeClick(challenge.id) },
                                onStartWorkout = { onStartChallengeWorkout(challenge.id) }
                            )
                        }
                    }

                    if (favoriteRoutines.isNotEmpty()) {
                        item {
                            SectionHeader(
                                title = stringResource(R.string.tab_favorites),
                                icon = Icons.Default.Star,
                                tint = Color(0xFFFFC107)
                            )
                        }
                        items(
                            items = favoriteRoutines,
                            key = { it.id }
                        ) { routine ->
                            RoutineCard(
                                routine = routine,
                                onClick = { onRoutineClick(routine.id) },
                                onEdit = { onEditRoutine(routine.id) },
                                onDelete = { routineToDelete = routine },
                                onToggleFavorite = { viewModel.toggleFavorite(routine.id) }
                            )
                        }
                    }

                    if (regularRoutines.isNotEmpty()) {
                        item {
                            SectionHeader(
                                title = stringResource(R.string.tab_all),
                                icon = Icons.Default.PlayArrow,
                                tint = MaterialTheme.colorScheme.primary
                            )
                        }
                        items(
                            items = regularRoutines,
                            key = { it.id }
                        ) { routine ->
                            RoutineCard(
                                routine = routine,
                                onClick = { onRoutineClick(routine.id) },
                                onEdit = { onEditRoutine(routine.id) },
                                onDelete = { routineToDelete = routine },
                                onToggleFavorite = { viewModel.toggleFavorite(routine.id) }
                            )
                        }
                    }
                }
            }
        }
    }

    routineToDelete?.let { routine ->
        AlertDialog(
            onDismissRequest = { routineToDelete = null },
            title = { Text(stringResource(R.string.delete_routine)) },
            text = { Text(stringResource(R.string.delete_routine_confirm, routine.name)) },
            confirmButton = {
                TextButton(
                    onClick = {
                        viewModel.deleteRoutine(routine.id)
                        routineToDelete = null
                    }
                ) {
                    Text(stringResource(R.string.delete), color = MaterialTheme.colorScheme.error)
                }
            },
            dismissButton = {
                TextButton(onClick = { routineToDelete = null }) {
                    Text(stringResource(R.string.cancel))
                }
            }
        )
    }
}

@Composable
private fun EmptyHomeState(
    onAddRoutine: () -> Unit,
    modifier: Modifier = Modifier
) {
    Box(
        modifier = modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Box(
                modifier = Modifier
                    .size(120.dp)
                    .clip(RoundedCornerShape(60.dp))
                    .background(MaterialTheme.colorScheme.primary.copy(alpha = 0.12f)),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = Icons.Default.PlayArrow,
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.primary,
                    modifier = Modifier.size(48.dp)
                )
            }
            Spacer(modifier = Modifier.height(20.dp))
            Text(
                text = stringResource(R.string.empty_routines).replace("\n", " "),
                style = MaterialTheme.typography.titleMedium,
                color = MaterialTheme.colorScheme.onSurface,
                textAlign = TextAlign.Center,
                modifier = Modifier.padding(horizontal = 32.dp)
            )
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = stringResource(R.string.no_active_challenges),
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                textAlign = TextAlign.Center,
                modifier = Modifier.padding(horizontal = 40.dp)
            )
            Spacer(modifier = Modifier.height(20.dp))
            Button(onClick = onAddRoutine) {
                Text(stringResource(R.string.add_interval))
            }
        }
    }
}

@Composable
private fun LoginPromptCard(
    onNavigateToLogin: () -> Unit,
    modifier: Modifier = Modifier
) {
    val borderColor = MaterialTheme.colorScheme.outline.copy(
        alpha = if (isSystemInDarkTheme()) 0.9f else 0.6f
    )
    Card(
        modifier = modifier
            .fillMaxWidth()
            .shadow(6.dp, RoundedCornerShape(18.dp), clip = false)
            .border(
                width = 1.dp,
                color = borderColor,
                shape = RoundedCornerShape(18.dp)
            ),
        shape = RoundedCornerShape(18.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(
                text = stringResource(R.string.login_to_join_challenges),
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                textAlign = TextAlign.Center
            )
            Spacer(modifier = Modifier.height(12.dp))
            Button(onClick = onNavigateToLogin) {
                Text(stringResource(R.string.login))
            }
        }
    }
}

@Composable
private fun SectionHeader(
    title: String,
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    tint: Color,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .padding(top = 4.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(
            imageVector = icon,
            contentDescription = null,
            tint = tint,
            modifier = Modifier.size(18.dp)
        )
        Spacer(modifier = Modifier.width(8.dp))
        Text(
            text = title,
            style = MaterialTheme.typography.titleSmall,
            color = MaterialTheme.colorScheme.onSurface
        )
    }
}

@Composable
private fun ActiveChallengeCard(
    challenge: ChallengeListItem,
    onClick: () -> Unit,
    onStartWorkout: () -> Unit,
    modifier: Modifier = Modifier
) {
    val borderColor = MaterialTheme.colorScheme.outline.copy(
        alpha = if (isSystemInDarkTheme()) 0.9f else 0.6f
    )
    val status = challenge.computedStatus
    val statusColor = when (status) {
        ChallengeStatus.REGISTRATION -> MaterialTheme.colorScheme.primary
        ChallengeStatus.ACTIVE -> MaterialTheme.colorScheme.tertiary
        ChallengeStatus.COMPLETED -> MaterialTheme.colorScheme.onSurfaceVariant
        ChallengeStatus.CANCELLED -> MaterialTheme.colorScheme.error
    }

    val statusText = when (status) {
        ChallengeStatus.REGISTRATION -> stringResource(R.string.status_registration)
        ChallengeStatus.ACTIVE -> stringResource(R.string.status_active)
        ChallengeStatus.COMPLETED -> stringResource(R.string.status_completed)
        ChallengeStatus.CANCELLED -> stringResource(R.string.status_cancelled)
    }

    Card(
        modifier = modifier
            .fillMaxWidth()
            .shadow(6.dp, RoundedCornerShape(18.dp), clip = false)
            .border(
                width = 1.dp,
                color = borderColor,
                shape = RoundedCornerShape(18.dp)
            )
            .clickable(onClick = onClick),
        shape = RoundedCornerShape(18.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        elevation = CardDefaults.cardElevation(defaultElevation = 0.dp)
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                // Status Badge
                Box(
                    modifier = Modifier
                        .clip(RoundedCornerShape(999.dp))
                        .background(statusColor.copy(alpha = 0.12f))
                        .padding(horizontal = 10.dp, vertical = 4.dp)
                ) {
                    Text(
                        text = statusText,
                        style = MaterialTheme.typography.labelSmall,
                        color = statusColor
                    )
                }

                // Today completed indicator
                if (challenge.todayCompleted == true) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(
                            Icons.Default.CheckCircle,
                            contentDescription = null,
                            tint = MaterialTheme.colorScheme.tertiary,
                            modifier = Modifier.size(16.dp)
                        )
                        Spacer(modifier = Modifier.width(4.dp))
                        Text(
                            text = stringResource(R.string.today_completed),
                            style = MaterialTheme.typography.labelSmall,
                            color = MaterialTheme.colorScheme.tertiary
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(12.dp))

            // Title
            Text(
                text = challenge.title,
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )

            // Routine Name
            Text(
                text = challenge.routineName,
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )

            Spacer(modifier = Modifier.height(12.dp))

            // Stats Row
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                // Participants & Prize
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(
                        Icons.Default.Person,
                        contentDescription = null,
                        modifier = Modifier.size(16.dp),
                        tint = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Spacer(modifier = Modifier.width(4.dp))
                    Text(
                        text = "${challenge.participantCount}",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Spacer(modifier = Modifier.width(16.dp))
                    Text(
                        text = challenge.formattedPrizePool,
                        style = MaterialTheme.typography.bodyMedium,
                        fontWeight = FontWeight.Bold,
                        color = MaterialTheme.colorScheme.primary
                    )
                }

                // Start button (only for active challenges)
                if (status == ChallengeStatus.ACTIVE) {
                    Button(
                        onClick = onStartWorkout,
                        contentPadding = PaddingValues(horizontal = 16.dp, vertical = 8.dp)
                    ) {
                        Icon(
                            Icons.Default.PlayArrow,
                            contentDescription = null,
                            modifier = Modifier.size(18.dp)
                        )
                        Spacer(modifier = Modifier.width(4.dp))
                        Text(stringResource(R.string.start))
                    }
                }
            }

            // My Stats (if available)
            challenge.myStats?.let { stats ->
                Spacer(modifier = Modifier.height(8.dp))
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(8.dp))
                        .background(MaterialTheme.colorScheme.surfaceVariant)
                        .padding(12.dp),
                    horizontalArrangement = Arrangement.SpaceEvenly
                ) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Text(
                            text = "${stats.completionCount}",
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold
                        )
                        Text(
                            text = stringResource(R.string.completion_count),
                            style = MaterialTheme.typography.labelSmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Text(
                            text = stats.formattedAttendanceRate,
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold
                        )
                        Text(
                            text = stringResource(R.string.attendance_rate),
                            style = MaterialTheme.typography.labelSmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }
            }
        }
    }
}
