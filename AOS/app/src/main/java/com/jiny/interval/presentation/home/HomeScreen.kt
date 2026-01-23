package com.jiny.interval.presentation.home

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.background
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
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Tab
import androidx.compose.material3.TabRow
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
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import androidx.lifecycle.compose.LocalLifecycleOwner
import com.jiny.interval.R
import com.jiny.interval.domain.model.ChallengeListItem
import com.jiny.interval.domain.model.ChallengeStatus
import com.jiny.interval.domain.model.Routine
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
    val selectedTab by viewModel.selectedTab.collectAsState()
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

    val displayedRoutines = when (selectedTab) {
        HomeTab.CHALLENGE -> emptyList()
        HomeTab.FAVORITES -> favoriteRoutines
        HomeTab.ALL -> allRoutines
    }

    Scaffold(
        contentWindowInsets = WindowInsets(0, 0, 0, 0),
        topBar = {
            Column {
                TopAppBar(
                    title = { Text(stringResource(R.string.app_name)) },
                    actions = {
                        IconButton(onClick = onSettingsClick) {
                            Icon(
                                imageVector = Icons.Default.Settings,
                                contentDescription = stringResource(R.string.settings)
                            )
                        }
                    }
                )
                TabRow(
                    selectedTabIndex = selectedTab.ordinal
                ) {
                    Tab(
                        selected = selectedTab == HomeTab.CHALLENGE,
                        onClick = { viewModel.selectTab(HomeTab.CHALLENGE) },
                        text = { Text(stringResource(R.string.challenge)) }
                    )
                    Tab(
                        selected = selectedTab == HomeTab.FAVORITES,
                        onClick = { viewModel.selectTab(HomeTab.FAVORITES) },
                        text = { Text(stringResource(R.string.tab_favorites)) }
                    )
                    Tab(
                        selected = selectedTab == HomeTab.ALL,
                        onClick = { viewModel.selectTab(HomeTab.ALL) },
                        text = { Text(stringResource(R.string.tab_all)) }
                    )
                }
            }
        },
        floatingActionButton = {
            if (selectedTab != HomeTab.CHALLENGE) {
                FloatingActionButton(onClick = onAddRoutine) {
                    Icon(
                        imageVector = Icons.Default.Add,
                        contentDescription = stringResource(R.string.add_interval)
                    )
                }
            }
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .background(MaterialTheme.colorScheme.background)
                .padding(paddingValues)
        ) {
            // Challenge Tab Content
            AnimatedVisibility(
                visible = selectedTab == HomeTab.CHALLENGE,
                enter = fadeIn(),
                exit = fadeOut()
            ) {
                if (!isLoggedIn) {
                    LoginPromptContent(onNavigateToLogin = onNavigateToLogin)
                } else if (activeChallenges.isEmpty()) {
                    EmptyState(message = stringResource(R.string.no_active_challenges))
                } else {
                    LazyColumn(
                        modifier = Modifier.fillMaxSize(),
                        contentPadding = PaddingValues(
                            start = 16.dp,
                            end = 16.dp,
                            top = 8.dp,
                            bottom = 8.dp
                        ),
                        verticalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
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
                }
            }

            // Routines Tab Content (Favorites/All)
            AnimatedVisibility(
                visible = selectedTab != HomeTab.CHALLENGE && displayedRoutines.isEmpty(),
                enter = fadeIn(),
                exit = fadeOut()
            ) {
                EmptyState(
                    message = if (selectedTab == HomeTab.FAVORITES) {
                        stringResource(R.string.empty_favorites)
                    } else {
                        stringResource(R.string.empty_routines)
                    }
                )
            }

            AnimatedVisibility(
                visible = selectedTab != HomeTab.CHALLENGE && displayedRoutines.isNotEmpty(),
                enter = fadeIn(),
                exit = fadeOut()
            ) {
                LazyColumn(
                    modifier = Modifier.fillMaxSize(),
                    contentPadding = PaddingValues(
                        start = 16.dp,
                        end = 16.dp,
                        top = 8.dp,
                        bottom = 8.dp
                    ),
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    items(
                        items = displayedRoutines,
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
private fun EmptyState(
    message: String,
    modifier: Modifier = Modifier
) {
    Box(
        modifier = modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        Text(
            text = message,
            style = MaterialTheme.typography.bodyLarge,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            textAlign = TextAlign.Center
        )
    }
}

@Composable
private fun LoginPromptContent(
    onNavigateToLogin: () -> Unit,
    modifier: Modifier = Modifier
) {
    Box(
        modifier = modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(
                text = stringResource(R.string.login_to_join_challenges),
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            Spacer(modifier = Modifier.height(16.dp))
            Button(onClick = onNavigateToLogin) {
                Text(stringResource(R.string.login))
            }
        }
    }
}

@Composable
private fun ActiveChallengeCard(
    challenge: ChallengeListItem,
    onClick: () -> Unit,
    onStartWorkout: () -> Unit,
    modifier: Modifier = Modifier
) {
    val status = challenge.computedStatus
    val (statusColor, statusTextColor) = when (status) {
        ChallengeStatus.REGISTRATION -> Pair(Color(0xFF2196F3), Color.White)
        ChallengeStatus.ACTIVE -> Pair(Color(0xFF4CAF50), Color.White)
        ChallengeStatus.COMPLETED -> Pair(Color(0xFF9E9E9E), Color.White)
        ChallengeStatus.CANCELLED -> Pair(Color(0xFFF44336), Color.White)
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
            .clickable(onClick = onClick),
        shape = RoundedCornerShape(16.dp),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
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
                        .clip(RoundedCornerShape(4.dp))
                        .background(statusColor)
                        .padding(horizontal = 8.dp, vertical = 4.dp)
                ) {
                    Text(
                        text = statusText,
                        style = MaterialTheme.typography.labelSmall,
                        color = statusTextColor
                    )
                }

                // Today completed indicator
                if (challenge.todayCompleted == true) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(
                            Icons.Default.CheckCircle,
                            contentDescription = null,
                            tint = Color(0xFF4CAF50),
                            modifier = Modifier.size(16.dp)
                        )
                        Spacer(modifier = Modifier.width(4.dp))
                        Text(
                            text = stringResource(R.string.today_completed),
                            style = MaterialTheme.typography.labelSmall,
                            color = Color(0xFF4CAF50)
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
