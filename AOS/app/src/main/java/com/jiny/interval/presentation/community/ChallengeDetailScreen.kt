package com.jiny.interval.presentation.community

import android.content.Intent
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.Share
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.jiny.interval.R
import com.jiny.interval.domain.model.Challenge
import com.jiny.interval.domain.model.ChallengeParticipant
import com.jiny.interval.domain.model.ChallengeStatus
import java.text.SimpleDateFormat
import java.util.Locale

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ChallengeDetailScreen(
    onNavigateBack: () -> Unit,
    onStartWorkout: (challengeId: Int) -> Unit,
    onNavigateToLogin: () -> Unit,
    viewModel: ChallengeDetailViewModel = hiltViewModel()
) {
    val challenge by viewModel.challenge.collectAsState()
    val participants by viewModel.participants.collectAsState()
    val isLoading by viewModel.isLoading.collectAsState()
    val isJoining by viewModel.isJoining.collectAsState()
    val isLoggedIn by viewModel.isLoggedIn.collectAsState()
    val mileageBalance by viewModel.mileageBalance.collectAsState()
    val error by viewModel.error.collectAsState()
    val message by viewModel.message.collectAsState()

    val snackbarHostState = remember { SnackbarHostState() }
    val context = LocalContext.current
    var showJoinDialog by remember { mutableStateOf(false) }
    var showLeaveDialog by remember { mutableStateOf(false) }

    val shareChallenge: () -> Unit = {
        challenge?.let { c ->
            val url = c.shareUrl ?: "http://kjiny.shop/Interval/challenge/?code=${c.shareCode}"
            val sendIntent = Intent().apply {
                action = Intent.ACTION_SEND
                putExtra(Intent.EXTRA_TEXT, url)
                type = "text/plain"
            }
            val shareIntent = Intent.createChooser(sendIntent, null)
            context.startActivity(shareIntent)
        }
    }

    LaunchedEffect(error) {
        error?.let {
            snackbarHostState.showSnackbar(it)
            viewModel.clearError()
        }
    }

    LaunchedEffect(message) {
        message?.let {
            snackbarHostState.showSnackbar(it)
            viewModel.clearMessage()
        }
    }

    if (showJoinDialog && challenge != null) {
        JoinChallengeDialog(
            challenge = challenge!!,
            mileageBalance = mileageBalance.balance,
            onConfirm = {
                showJoinDialog = false
                viewModel.joinChallenge()
            },
            onDismiss = { showJoinDialog = false }
        )
    }

    if (showLeaveDialog) {
        LeaveChallengeDialog(
            onConfirm = {
                showLeaveDialog = false
                viewModel.leaveChallenge()
            },
            onDismiss = { showLeaveDialog = false }
        )
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(stringResource(R.string.challenge_detail)) },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = stringResource(R.string.back))
                    }
                },
                actions = {
                    IconButton(onClick = shareChallenge) {
                        Icon(Icons.Default.Share, contentDescription = stringResource(R.string.share))
                    }
                }
            )
        },
        snackbarHost = { SnackbarHost(snackbarHostState) }
    ) { paddingValues ->
        if (isLoading && challenge == null) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(paddingValues),
                contentAlignment = Alignment.Center
            ) {
                CircularProgressIndicator()
            }
        } else if (challenge == null) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(paddingValues),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = "Challenge not found",
                    style = MaterialTheme.typography.bodyLarge,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        } else {
            LazyColumn(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(paddingValues),
                contentPadding = PaddingValues(bottom = 100.dp)
            ) {
                // Challenge Info Card
                item {
                    ChallengeInfoCard(
                        challenge = challenge!!,
                        modifier = Modifier.padding(16.dp)
                    )
                }

                // My Stats Card (if participating)
                if (challenge!!.isParticipating == true && challenge!!.myParticipation != null) {
                    item {
                        MyStatsCard(
                            rank = challenge!!.myRank,
                            stats = challenge!!.myParticipation!!,
                            modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp)
                        )
                    }
                }

                // Action Button
                item {
                    ActionButtons(
                        challenge = challenge!!,
                        isLoggedIn = isLoggedIn,
                        isJoining = isJoining,
                        onJoinClick = {
                            if (!isLoggedIn) {
                                onNavigateToLogin()
                            } else {
                                showJoinDialog = true
                            }
                        },
                        onLeaveClick = { showLeaveDialog = true },
                        onStartWorkout = { onStartWorkout(challenge!!.id) },
                        modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp)
                    )
                }

                // Participants Section
                item {
                    Text(
                        text = stringResource(R.string.participants),
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold,
                        modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp)
                    )
                }

                if (participants.isEmpty()) {
                    item {
                        Box(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(32.dp),
                            contentAlignment = Alignment.Center
                        ) {
                            Text(
                                text = stringResource(R.string.no_participants),
                                style = MaterialTheme.typography.bodyLarge,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    }
                } else {
                    items(participants, key = { it.rank }) { participant ->
                        ParticipantRow(
                            participant = participant,
                            modifier = Modifier.padding(horizontal = 16.dp)
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun ChallengeInfoCard(
    challenge: Challenge,
    modifier: Modifier = Modifier
) {
    val status = challenge.status
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
        modifier = modifier.fillMaxWidth(),
        shape = RoundedCornerShape(16.dp)
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(20.dp)
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = challenge.title,
                    style = MaterialTheme.typography.headlineSmall,
                    fontWeight = FontWeight.Bold,
                    modifier = Modifier.weight(1f)
                )
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
            }

            Spacer(modifier = Modifier.height(8.dp))

            Text(
                text = challenge.routineName,
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )

            if (!challenge.description.isNullOrBlank()) {
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    text = challenge.description,
                    style = MaterialTheme.typography.bodyMedium
                )
            }

            Spacer(modifier = Modifier.height(16.dp))

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceEvenly
            ) {
                InfoColumn(
                    label = stringResource(R.string.entry_fee),
                    value = challenge.formattedEntryFee
                )
                InfoColumn(
                    label = stringResource(R.string.prize_pool),
                    value = challenge.formattedPrizePool,
                    valueColor = MaterialTheme.colorScheme.primary
                )
                InfoColumn(
                    label = stringResource(R.string.participants),
                    value = "${challenge.participantCount}"
                )
            }

            Spacer(modifier = Modifier.height(16.dp))
            HorizontalDivider()
            Spacer(modifier = Modifier.height(16.dp))

            // Date info
            DateInfoRow(
                label = stringResource(R.string.challenge_period),
                startDate = challenge.challengeStartAt,
                endDate = challenge.challengeEndAt
            )
        }
    }
}

@Composable
private fun InfoColumn(
    label: String,
    value: String,
    valueColor: Color = MaterialTheme.colorScheme.onSurface
) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Text(
            text = label,
            style = MaterialTheme.typography.labelSmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        Text(
            text = value,
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.Bold,
            color = valueColor
        )
    }
}

@Composable
private fun DateInfoRow(
    label: String,
    startDate: String,
    endDate: String
) {
    val dateFormat = SimpleDateFormat("yyyy.MM.dd", Locale.getDefault())
    val parseFormat = SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.getDefault())

    val formattedStart = try {
        val date = parseFormat.parse(startDate)
        dateFormat.format(date!!)
    } catch (e: Exception) {
        startDate.take(10)
    }

    val formattedEnd = try {
        val date = parseFormat.parse(endDate)
        dateFormat.format(date!!)
    } catch (e: Exception) {
        endDate.take(10)
    }

    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = label,
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        Text(
            text = "$formattedStart ~ $formattedEnd",
            style = MaterialTheme.typography.bodyMedium,
            fontWeight = FontWeight.Medium
        )
    }
}

@Composable
private fun MyStatsCard(
    rank: Int?,
    stats: com.jiny.interval.domain.model.ParticipationStats,
    modifier: Modifier = Modifier
) {
    Card(
        modifier = modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.secondaryContainer
        ),
        shape = RoundedCornerShape(12.dp)
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp)
        ) {
            Text(
                text = stringResource(R.string.my_stats),
                style = MaterialTheme.typography.titleSmall,
                fontWeight = FontWeight.Bold
            )

            Spacer(modifier = Modifier.height(12.dp))

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceEvenly
            ) {
                StatItem(
                    label = stringResource(R.string.rank),
                    value = rank?.let { "#$it" } ?: "-"
                )
                StatItem(
                    label = stringResource(R.string.completion_count),
                    value = "${stats.completionCount}"
                )
                StatItem(
                    label = stringResource(R.string.attendance_rate),
                    value = stats.formattedAttendanceRate
                )
            }
        }
    }
}

@Composable
private fun StatItem(
    label: String,
    value: String
) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Text(
            text = value,
            style = MaterialTheme.typography.titleLarge,
            fontWeight = FontWeight.Bold,
            color = MaterialTheme.colorScheme.onSecondaryContainer
        )
        Text(
            text = label,
            style = MaterialTheme.typography.labelSmall,
            color = MaterialTheme.colorScheme.onSecondaryContainer.copy(alpha = 0.7f)
        )
    }
}

@Composable
private fun ActionButtons(
    challenge: Challenge,
    isLoggedIn: Boolean,
    isJoining: Boolean,
    onJoinClick: () -> Unit,
    onLeaveClick: () -> Unit,
    onStartWorkout: () -> Unit,
    modifier: Modifier = Modifier
) {
    val isParticipating = challenge.isParticipating == true
    val canJoin = challenge.canJoin == true
    val canLeave = challenge.canLeave == true
    val isActive = challenge.status == ChallengeStatus.ACTIVE

    Column(modifier = modifier.fillMaxWidth()) {
        if (isParticipating && isActive) {
            Button(
                onClick = onStartWorkout,
                modifier = Modifier.fillMaxWidth(),
                contentPadding = PaddingValues(16.dp)
            ) {
                Icon(Icons.Default.PlayArrow, contentDescription = null)
                Spacer(modifier = Modifier.width(8.dp))
                Text(stringResource(R.string.start_workout))
            }
            Spacer(modifier = Modifier.height(8.dp))
        }

        if (!isParticipating && canJoin) {
            Button(
                onClick = onJoinClick,
                modifier = Modifier.fillMaxWidth(),
                enabled = !isJoining,
                contentPadding = PaddingValues(16.dp)
            ) {
                if (isJoining) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(20.dp),
                        strokeWidth = 2.dp
                    )
                } else {
                    Text(stringResource(R.string.join_challenge))
                }
            }
        }

        if (isParticipating && canLeave) {
            OutlinedButton(
                onClick = onLeaveClick,
                modifier = Modifier.fillMaxWidth(),
                enabled = !isJoining,
                colors = ButtonDefaults.outlinedButtonColors(
                    contentColor = MaterialTheme.colorScheme.error
                ),
                contentPadding = PaddingValues(16.dp)
            ) {
                if (isJoining) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(20.dp),
                        strokeWidth = 2.dp
                    )
                } else {
                    Text(stringResource(R.string.leave_challenge))
                }
            }
        }
    }
}

@Composable
private fun ParticipantRow(
    participant: ChallengeParticipant,
    modifier: Modifier = Modifier
) {
    Column(modifier = modifier) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(vertical = 12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Rank
            Text(
                text = "#${participant.rank}",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                modifier = Modifier.width(40.dp),
                textAlign = TextAlign.Center,
                color = when (participant.rank) {
                    1 -> Color(0xFFFFD700)
                    2 -> Color(0xFFC0C0C0)
                    3 -> Color(0xFFCD7F32)
                    else -> MaterialTheme.colorScheme.onSurface
                }
            )

            Spacer(modifier = Modifier.width(12.dp))

            // Profile
            Box(
                modifier = Modifier
                    .size(40.dp)
                    .clip(CircleShape)
                    .background(MaterialTheme.colorScheme.surfaceVariant),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    Icons.Default.Person,
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }

            Spacer(modifier = Modifier.width(12.dp))

            // Name
            Text(
                text = participant.displayName,
                style = MaterialTheme.typography.bodyMedium,
                fontWeight = FontWeight.Medium,
                modifier = Modifier.weight(1f)
            )

            // Stats
            Column(horizontalAlignment = Alignment.End) {
                Text(
                    text = "${participant.completionCount} ${stringResource(R.string.times)}",
                    style = MaterialTheme.typography.bodyMedium,
                    fontWeight = FontWeight.SemiBold
                )
                Text(
                    text = participant.formattedAttendanceRate,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
        HorizontalDivider(color = MaterialTheme.colorScheme.outlineVariant)
    }
}

@Composable
private fun JoinChallengeDialog(
    challenge: Challenge,
    mileageBalance: Int,
    onConfirm: () -> Unit,
    onDismiss: () -> Unit
) {
    val insufficientBalance = mileageBalance < challenge.entryFee

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(stringResource(R.string.join_challenge)) },
        text = {
            Column {
                Text(stringResource(R.string.join_challenge_confirm, challenge.title))
                Spacer(modifier = Modifier.height(16.dp))
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Text(stringResource(R.string.entry_fee))
                    Text(
                        text = challenge.formattedEntryFee,
                        fontWeight = FontWeight.Bold
                    )
                }
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Text(stringResource(R.string.your_balance))
                    Text(
                        text = "${mileageBalance}M",
                        fontWeight = FontWeight.Bold,
                        color = if (insufficientBalance) Color.Red else MaterialTheme.colorScheme.onSurface
                    )
                }
                if (insufficientBalance) {
                    Spacer(modifier = Modifier.height(8.dp))
                    Text(
                        text = stringResource(R.string.insufficient_balance),
                        color = Color.Red,
                        style = MaterialTheme.typography.bodySmall
                    )
                }
            }
        },
        confirmButton = {
            TextButton(
                onClick = onConfirm,
                enabled = !insufficientBalance
            ) {
                Text(stringResource(R.string.join))
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text(stringResource(R.string.cancel))
            }
        }
    )
}

@Composable
private fun LeaveChallengeDialog(
    onConfirm: () -> Unit,
    onDismiss: () -> Unit
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(stringResource(R.string.leave_challenge)) },
        text = { Text(stringResource(R.string.leave_challenge_confirm)) },
        confirmButton = {
            TextButton(onClick = onConfirm) {
                Text(stringResource(R.string.leave))
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text(stringResource(R.string.cancel))
            }
        }
    )
}
