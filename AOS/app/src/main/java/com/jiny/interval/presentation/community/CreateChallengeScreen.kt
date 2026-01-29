package com.jiny.interval.presentation.community

import android.content.Intent
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectTapGestures
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
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.CalendarMonth
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Remove
import androidx.compose.material.icons.filled.Schedule
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.DatePicker
import androidx.compose.material3.DatePickerDefaults
import androidx.compose.material3.SelectableDates
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilledIconButton
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.IconButtonDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.material3.rememberDatePickerState
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import com.jiny.interval.R
import com.jiny.interval.domain.model.Routine
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CreateChallengeScreen(
    onNavigateBack: () -> Unit,
    onChallengeCreated: () -> Unit,
    viewModel: CreateChallengeViewModel = hiltViewModel()
) {
    val title by viewModel.title.collectAsState()
    val description by viewModel.description.collectAsState()
    val selectedRoutine by viewModel.selectedRoutine.collectAsState()
    val routines by viewModel.routines.collectAsState()
    val registrationEndDate by viewModel.registrationEndDate.collectAsState()
    val challengeStartDate by viewModel.challengeStartDate.collectAsState()
    val challengeEndDate by viewModel.challengeEndDate.collectAsState()
    val entryFee by viewModel.entryFee.collectAsState()
    val isPublic by viewModel.isPublic.collectAsState()
    val maxParticipants by viewModel.maxParticipants.collectAsState()
    val mileageBalance by viewModel.mileageBalance.collectAsState()
    val isLoading by viewModel.isLoading.collectAsState()
    val error by viewModel.error.collectAsState()
    val createdShareUrl by viewModel.createdShareUrl.collectAsState()

    val snackbarHostState = remember { SnackbarHostState() }
    val context = LocalContext.current
    val focusManager = LocalFocusManager.current
    val dateTimeFormat = remember { SimpleDateFormat("M월 d일 (E) HH:mm", Locale.KOREAN) }
    var showSuccessDialog by remember { mutableStateOf(false) }
    var hasMaxParticipants by remember { mutableStateOf(maxParticipants != null) }

    // DateTime picker state
    var showDateTimePicker by remember { mutableStateOf(false) }
    var datePickerTarget by remember { mutableIntStateOf(0) } // 0: reg end, 1: start, 2: end
    var selectedDateForPicker by remember { mutableStateOf(Date()) }

    val shareChallenge: (String) -> Unit = { shareUrl ->
        val shareText = context.getString(R.string.share_challenge_text, title, shareUrl)
        val sendIntent = Intent().apply {
            action = Intent.ACTION_SEND
            putExtra(Intent.EXTRA_TEXT, shareText)
            type = "text/plain"
        }
        val shareIntent = Intent.createChooser(sendIntent, context.getString(R.string.share_challenge))
        context.startActivity(shareIntent)
    }

    LaunchedEffect(error) {
        error?.let {
            snackbarHostState.showSnackbar(it)
            viewModel.clearError()
        }
    }

    // Auto-update start date when registration end date changes (start = registration end + 1 min)
    LaunchedEffect(registrationEndDate) {
        val newStartDate = Date(registrationEndDate.time + 60 * 1000) // +1 minute
        if (challengeStartDate.before(newStartDate)) {
            viewModel.updateChallengeStartDate(newStartDate)
        }
    }

    // Auto-update end date when start date changes (end must be after start)
    LaunchedEffect(challengeStartDate) {
        if (challengeEndDate.before(challengeStartDate) || challengeEndDate == challengeStartDate) {
            // Set end date to start date + 1 day
            val newEndDate = Date(challengeStartDate.time + 24 * 60 * 60 * 1000)
            viewModel.updateChallengeEndDate(newEndDate)
        }
    }

    // Calculate minimum dates for each picker
    val minStartDate = remember(registrationEndDate) {
        Date(registrationEndDate.time + 60 * 1000) // registration end + 1 minute
    }
    val minEndDate = remember(challengeStartDate) {
        Date(challengeStartDate.time + 60 * 1000) // start date + 1 minute
    }

    if (showSuccessDialog) {
        ChallengeCreatedDialog(
            shareUrl = createdShareUrl ?: "",
            onShare = { createdShareUrl?.let { shareChallenge(it) } },
            onDismiss = {
                showSuccessDialog = false
                onChallengeCreated()
            }
        )
    }

    // Gradient background colors
    val gradientColors = listOf(
        Color(0xFF667eea),
        Color(0xFF764ba2)
    )

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(
                brush = Brush.verticalGradient(
                    colors = listOf(
                        MaterialTheme.colorScheme.primary.copy(alpha = 0.1f),
                        MaterialTheme.colorScheme.background
                    )
                )
            )
    ) {
        Scaffold(
            containerColor = Color.Transparent,
            topBar = {
                TopAppBar(
                    title = {
                        Text(
                            stringResource(R.string.create_challenge),
                            fontWeight = FontWeight.Bold
                        )
                    },
                    navigationIcon = {
                        IconButton(onClick = onNavigateBack) {
                            Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = stringResource(R.string.back))
                        }
                    },
                    colors = TopAppBarDefaults.topAppBarColors(
                        containerColor = Color.Transparent
                    )
                )
            },
            snackbarHost = { SnackbarHost(snackbarHostState) }
        ) { paddingValues ->
            LazyColumn(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(paddingValues)
                    .pointerInput(Unit) {
                        detectTapGestures(onTap = { focusManager.clearFocus() })
                    },
                contentPadding = PaddingValues(16.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                // Mileage Balance Card
                item {
                    GlassCard(
                        modifier = Modifier.fillMaxWidth(),
                        gradientColors = gradientColors
                    ) {
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(20.dp),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Column {
                                Text(
                                    text = stringResource(R.string.my_mileage),
                                    style = MaterialTheme.typography.bodyMedium,
                                    color = Color.White.copy(alpha = 0.8f)
                                )
                                Text(
                                    text = mileageBalance.formattedBalance,
                                    style = MaterialTheme.typography.headlineMedium,
                                    fontWeight = FontWeight.Bold,
                                    color = Color.White
                                )
                            }
                            Box(
                                modifier = Modifier
                                    .size(48.dp)
                                    .background(
                                        Color.White.copy(alpha = 0.2f),
                                        CircleShape
                                    ),
                                contentAlignment = Alignment.Center
                            ) {
                                Text("💎", fontSize = 24.sp)
                            }
                        }
                    }
                }

                // Basic Info
                item {
                    GlassSectionCard(title = stringResource(R.string.challenge_title)) {
                        OutlinedTextField(
                            value = title,
                            onValueChange = viewModel::updateTitle,
                            modifier = Modifier.fillMaxWidth(),
                            placeholder = { Text(stringResource(R.string.challenge_title_hint)) },
                            singleLine = true,
                            shape = RoundedCornerShape(16.dp),
                            colors = OutlinedTextFieldDefaults.colors(
                                focusedBorderColor = MaterialTheme.colorScheme.primary,
                                unfocusedBorderColor = MaterialTheme.colorScheme.outline.copy(alpha = 0.3f),
                                focusedContainerColor = MaterialTheme.colorScheme.surface,
                                unfocusedContainerColor = MaterialTheme.colorScheme.surface
                            )
                        )
                        Spacer(modifier = Modifier.height(12.dp))
                        OutlinedTextField(
                            value = description,
                            onValueChange = viewModel::updateDescription,
                            modifier = Modifier.fillMaxWidth(),
                            placeholder = { Text(stringResource(R.string.challenge_description_hint)) },
                            minLines = 2,
                            maxLines = 4,
                            shape = RoundedCornerShape(16.dp),
                            colors = OutlinedTextFieldDefaults.colors(
                                focusedBorderColor = MaterialTheme.colorScheme.primary,
                                unfocusedBorderColor = MaterialTheme.colorScheme.outline.copy(alpha = 0.3f),
                                focusedContainerColor = MaterialTheme.colorScheme.surface,
                                unfocusedContainerColor = MaterialTheme.colorScheme.surface
                            )
                        )
                    }
                }

                // Routine Selection
                item {
                    GlassSectionCard(title = stringResource(R.string.select_routine)) {
                        if (routines.isEmpty()) {
                            Text(
                                text = stringResource(R.string.no_routines_available),
                                style = MaterialTheme.typography.bodyMedium,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        } else {
                            LazyRow(
                                horizontalArrangement = Arrangement.spacedBy(10.dp)
                            ) {
                                items(routines, key = { it.id }) { routine ->
                                    ModernRoutineChip(
                                        routine = routine,
                                        isSelected = selectedRoutine?.id == routine.id,
                                        onClick = { viewModel.selectRoutine(routine) }
                                    )
                                }
                            }
                        }
                    }
                }

                // Schedule Section
                item {
                    GlassSectionCard(title = stringResource(R.string.challenge_period)) {
                        DateTimeButton(
                            label = stringResource(R.string.registration_end_date),
                            date = registrationEndDate,
                            dateFormat = dateTimeFormat,
                            onClick = {
                                datePickerTarget = 0
                                selectedDateForPicker = registrationEndDate
                                showDateTimePicker = true
                            }
                        )
                        Spacer(modifier = Modifier.height(12.dp))
                        DateTimeButton(
                            label = stringResource(R.string.start_date),
                            date = challengeStartDate,
                            dateFormat = dateTimeFormat,
                            onClick = {
                                datePickerTarget = 1
                                selectedDateForPicker = challengeStartDate
                                showDateTimePicker = true
                            }
                        )
                        Spacer(modifier = Modifier.height(12.dp))
                        DateTimeButton(
                            label = stringResource(R.string.end_date),
                            date = challengeEndDate,
                            dateFormat = dateTimeFormat,
                            onClick = {
                                datePickerTarget = 2
                                selectedDateForPicker = challengeEndDate
                                showDateTimePicker = true
                            }
                        )

                        val days = remember(challengeStartDate, challengeEndDate) {
                            val diff = challengeEndDate.time - challengeStartDate.time
                            (diff / (1000 * 60 * 60 * 24)).toInt() + 1
                        }
                        Spacer(modifier = Modifier.height(12.dp))
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .background(
                                    MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.3f),
                                    RoundedCornerShape(12.dp)
                                )
                                .padding(12.dp),
                            horizontalArrangement = Arrangement.Center
                        ) {
                            Text(
                                text = "📅 " + stringResource(R.string.challenge_duration_days, days),
                                style = MaterialTheme.typography.bodyMedium,
                                fontWeight = FontWeight.Medium,
                                color = MaterialTheme.colorScheme.primary
                            )
                        }
                    }
                }

                // Entry Fee
                item {
                    GlassSectionCard(title = stringResource(R.string.entry_fee_setting)) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.Center,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            ModernStepperButton(
                                onClick = { viewModel.updateEntryFee(entryFee - 50) },
                                enabled = entryFee >= 50,
                                isPlus = false
                            )

                            Column(
                                horizontalAlignment = Alignment.CenterHorizontally,
                                modifier = Modifier.padding(horizontal = 24.dp)
                            ) {
                                Text(
                                    text = "${entryFee}M",
                                    style = MaterialTheme.typography.displaySmall,
                                    fontWeight = FontWeight.Bold,
                                    color = MaterialTheme.colorScheme.primary
                                )
                                Text(
                                    text = "마일리지",
                                    style = MaterialTheme.typography.bodySmall,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant
                                )
                            }

                            ModernStepperButton(
                                onClick = { viewModel.updateEntryFee(entryFee + 50) },
                                enabled = entryFee < 10000,
                                isPlus = true
                            )
                        }

                        if (entryFee > mileageBalance.balance) {
                            Spacer(modifier = Modifier.height(12.dp))
                            Text(
                                text = "⚠️ " + stringResource(R.string.insufficient_balance),
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.error,
                                modifier = Modifier.fillMaxWidth(),
                                textAlign = TextAlign.Center
                            )
                        }
                    }
                }

                // Settings
                item {
                    GlassSectionCard(title = stringResource(R.string.settings)) {
                        SettingToggleRow(
                            title = stringResource(R.string.public_challenge),
                            subtitle = stringResource(R.string.public_challenge_desc),
                            checked = isPublic,
                            onCheckedChange = viewModel::updateIsPublic
                        )

                        Spacer(modifier = Modifier.height(16.dp))

                        SettingToggleRow(
                            title = stringResource(R.string.limit_participants),
                            subtitle = null,
                            checked = hasMaxParticipants,
                            onCheckedChange = { checked ->
                                hasMaxParticipants = checked
                                viewModel.updateMaxParticipants(if (checked) 10 else null)
                            }
                        )

                        if (hasMaxParticipants) {
                            Spacer(modifier = Modifier.height(16.dp))
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.Center,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                ModernStepperButton(
                                    onClick = {
                                        val current = maxParticipants ?: 10
                                        if (current > 2) viewModel.updateMaxParticipants(current - 1)
                                    },
                                    enabled = (maxParticipants ?: 10) > 2,
                                    isPlus = false,
                                    small = true
                                )

                                Text(
                                    text = stringResource(R.string.max_participants_count, maxParticipants ?: 10),
                                    style = MaterialTheme.typography.titleLarge,
                                    fontWeight = FontWeight.Bold,
                                    modifier = Modifier.padding(horizontal = 24.dp)
                                )

                                ModernStepperButton(
                                    onClick = {
                                        val current = maxParticipants ?: 10
                                        if (current < 100) viewModel.updateMaxParticipants(current + 1)
                                    },
                                    enabled = (maxParticipants ?: 10) < 100,
                                    isPlus = true,
                                    small = true
                                )
                            }
                        }
                    }
                }

                // Create Button
                item {
                    Spacer(modifier = Modifier.height(8.dp))
                    Button(
                        onClick = { viewModel.createChallenge { showSuccessDialog = true } },
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(56.dp),
                        enabled = !isLoading && selectedRoutine != null && title.isNotBlank() && entryFee <= mileageBalance.balance,
                        shape = RoundedCornerShape(16.dp),
                        colors = ButtonDefaults.buttonColors(
                            containerColor = MaterialTheme.colorScheme.primary
                        )
                    ) {
                        if (isLoading) {
                            CircularProgressIndicator(
                                modifier = Modifier.size(24.dp),
                                strokeWidth = 2.dp,
                                color = MaterialTheme.colorScheme.onPrimary
                            )
                        } else {
                            Text(
                                text = "🚀 " + stringResource(R.string.create_challenge),
                                style = MaterialTheme.typography.titleMedium,
                                fontWeight = FontWeight.Bold
                            )
                        }
                    }
                    Spacer(modifier = Modifier.height(32.dp))
                }
            }
        }
    }

    // DateTime Picker Bottom Sheet
    if (showDateTimePicker) {
        val minDateForPicker = when (datePickerTarget) {
            0 -> null // Registration end: only limit to current time (handled in component)
            1 -> minStartDate // Start date: must be after registration end
            2 -> minEndDate // End date: must be after start date
            else -> null
        }

        DateTimePickerBottomSheet(
            initialDate = selectedDateForPicker,
            minDate = minDateForPicker,
            onDismiss = { showDateTimePicker = false },
            onConfirm = { date ->
                when (datePickerTarget) {
                    0 -> viewModel.updateRegistrationEndDate(date)
                    1 -> viewModel.updateChallengeStartDate(date)
                    2 -> viewModel.updateChallengeEndDate(date)
                }
                showDateTimePicker = false
            }
        )
    }
}

@Composable
private fun GlassCard(
    modifier: Modifier = Modifier,
    gradientColors: List<Color>,
    content: @Composable () -> Unit
) {
    Card(
        modifier = modifier,
        shape = RoundedCornerShape(20.dp),
        colors = CardDefaults.cardColors(containerColor = Color.Transparent)
    ) {
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .background(
                    brush = Brush.linearGradient(gradientColors),
                    shape = RoundedCornerShape(20.dp)
                )
        ) {
            content()
        }
    }
}

@Composable
private fun GlassSectionCard(
    title: String,
    content: @Composable () -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(20.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surface.copy(alpha = 0.9f)
        ),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(20.dp)
        ) {
            Text(
                text = title,
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold
            )
            Spacer(modifier = Modifier.height(16.dp))
            content()
        }
    }
}

@Composable
private fun DateTimeButton(
    label: String,
    date: Date,
    dateFormat: SimpleDateFormat,
    onClick: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(16.dp))
            .background(MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f))
            .clickable(onClick = onClick)
            .padding(16.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Column {
            Text(
                text = label,
                style = MaterialTheme.typography.labelMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            Spacer(modifier = Modifier.height(4.dp))
            Text(
                text = dateFormat.format(date),
                style = MaterialTheme.typography.bodyLarge,
                fontWeight = FontWeight.SemiBold
            )
        }
        Box(
            modifier = Modifier
                .size(40.dp)
                .background(
                    MaterialTheme.colorScheme.primary.copy(alpha = 0.1f),
                    CircleShape
                ),
            contentAlignment = Alignment.Center
        ) {
            Icon(
                Icons.Default.CalendarMonth,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.primary,
                modifier = Modifier.size(20.dp)
            )
        }
    }
}

@Composable
private fun ModernRoutineChip(
    routine: Routine,
    isSelected: Boolean,
    onClick: () -> Unit
) {
    Card(
        modifier = Modifier
            .clickable(onClick = onClick)
            .then(
                if (isSelected) {
                    Modifier.border(
                        2.dp,
                        MaterialTheme.colorScheme.primary,
                        RoundedCornerShape(16.dp)
                    )
                } else Modifier
            ),
        colors = CardDefaults.cardColors(
            containerColor = if (isSelected)
                MaterialTheme.colorScheme.primaryContainer
            else
                MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f)
        ),
        shape = RoundedCornerShape(16.dp)
    ) {
        Row(
            modifier = Modifier.padding(14.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            if (isSelected) {
                Box(
                    modifier = Modifier
                        .size(20.dp)
                        .background(MaterialTheme.colorScheme.primary, CircleShape),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        Icons.Default.Check,
                        contentDescription = null,
                        modifier = Modifier.size(14.dp),
                        tint = MaterialTheme.colorScheme.onPrimary
                    )
                }
                Spacer(modifier = Modifier.width(8.dp))
            }
            Column {
                Text(
                    text = routine.name,
                    style = MaterialTheme.typography.bodyMedium,
                    fontWeight = FontWeight.SemiBold
                )
                Text(
                    text = "${routine.rounds}R • ${routine.intervals.size} intervals",
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
}

@Composable
private fun ModernStepperButton(
    onClick: () -> Unit,
    enabled: Boolean,
    isPlus: Boolean,
    small: Boolean = false
) {
    val size = if (small) 40.dp else 48.dp
    val iconSize = if (small) 20.dp else 24.dp

    FilledIconButton(
        onClick = onClick,
        enabled = enabled,
        modifier = Modifier.size(size),
        colors = IconButtonDefaults.filledIconButtonColors(
            containerColor = if (isPlus)
                MaterialTheme.colorScheme.primary
            else
                MaterialTheme.colorScheme.secondaryContainer,
            contentColor = if (isPlus)
                MaterialTheme.colorScheme.onPrimary
            else
                MaterialTheme.colorScheme.onSecondaryContainer
        )
    ) {
        Icon(
            if (isPlus) Icons.Default.Add else Icons.Default.Remove,
            contentDescription = null,
            modifier = Modifier.size(iconSize)
        )
    }
}

@Composable
private fun SettingToggleRow(
    title: String,
    subtitle: String?,
    checked: Boolean,
    onCheckedChange: (Boolean) -> Unit
) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = title,
                style = MaterialTheme.typography.bodyLarge,
                fontWeight = FontWeight.Medium
            )
            if (subtitle != null) {
                Text(
                    text = subtitle,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
        Switch(
            checked = checked,
            onCheckedChange = onCheckedChange
        )
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun DateTimePickerBottomSheet(
    initialDate: Date,
    minDate: Date? = null,
    onDismiss: () -> Unit,
    onConfirm: (Date) -> Unit
) {
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)

    val now = remember { Calendar.getInstance() }

    // Effective minimum date: either provided minDate or current time
    val effectiveMinDate = remember(minDate) {
        if (minDate != null && minDate.after(now.time)) {
            minDate
        } else {
            now.time
        }
    }

    val effectiveMinCalendar = remember(effectiveMinDate) {
        Calendar.getInstance().apply { time = effectiveMinDate }
    }

    val minDateStart = remember(effectiveMinDate) {
        Calendar.getInstance().apply {
            time = effectiveMinDate
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }.timeInMillis
    }

    val calendar = remember { Calendar.getInstance().apply { time = initialDate } }
    val datePickerState = rememberDatePickerState(
        initialSelectedDateMillis = maxOf(calendar.timeInMillis, minDateStart),
        selectableDates = object : SelectableDates {
            override fun isSelectableDate(utcTimeMillis: Long): Boolean {
                return utcTimeMillis >= minDateStart
            }
        }
    )

    var selectedHour by remember { mutableIntStateOf(calendar.get(Calendar.HOUR_OF_DAY)) }
    var selectedMinute by remember { mutableIntStateOf(calendar.get(Calendar.MINUTE)) }
    var showTimePicker by remember { mutableStateOf(false) }

    // Check if selected date is the minimum date's day
    val isMinDay = remember(datePickerState.selectedDateMillis, effectiveMinDate) {
        datePickerState.selectedDateMillis?.let { selectedMillis ->
            val selectedCal = Calendar.getInstance().apply { timeInMillis = selectedMillis }
            val minCal = Calendar.getInstance().apply { time = effectiveMinDate }
            selectedCal.get(Calendar.YEAR) == minCal.get(Calendar.YEAR) &&
                    selectedCal.get(Calendar.DAY_OF_YEAR) == minCal.get(Calendar.DAY_OF_YEAR)
        } ?: false
    }

    // Get minimum hour and minute from effective min date
    val minDateHour = remember(effectiveMinDate) { effectiveMinCalendar.get(Calendar.HOUR_OF_DAY) }
    val minDateMinute = remember(effectiveMinDate) { effectiveMinCalendar.get(Calendar.MINUTE) }

    // Calculate minimum hour and minute based on whether it's the min day
    val minHour = if (isMinDay) minDateHour else 0
    val minMinute = if (isMinDay && selectedHour == minDateHour) minDateMinute + 1 else 0

    // Auto-adjust time if it becomes invalid
    LaunchedEffect(isMinDay, minDateHour, minDateMinute, selectedHour) {
        if (isMinDay) {
            if (selectedHour < minDateHour) {
                selectedHour = minDateHour
                selectedMinute = minDateMinute + 1
                if (selectedMinute > 59) {
                    selectedMinute = 0
                    selectedHour = (selectedHour + 1).coerceAtMost(23)
                }
            } else if (selectedHour == minDateHour && selectedMinute <= minDateMinute) {
                selectedMinute = minDateMinute + 1
                if (selectedMinute > 59) {
                    selectedMinute = 0
                    selectedHour = (selectedHour + 1).coerceAtMost(23)
                }
            }
        }
    }

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        sheetState = sheetState,
        containerColor = MaterialTheme.colorScheme.surface
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp)
                .padding(bottom = 32.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            // Tab selector
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(bottom = 16.dp),
                horizontalArrangement = Arrangement.Center
            ) {
                TabButton(
                    text = "📅 날짜",
                    selected = !showTimePicker,
                    onClick = { showTimePicker = false }
                )
                Spacer(modifier = Modifier.width(8.dp))
                TabButton(
                    text = "⏰ 시간",
                    selected = showTimePicker,
                    onClick = { showTimePicker = true }
                )
            }

            if (!showTimePicker) {
                DatePicker(
                    state = datePickerState,
                    showModeToggle = false,
                    title = null,
                    headline = null,
                    colors = DatePickerDefaults.colors(
                        containerColor = MaterialTheme.colorScheme.surface
                    )
                )
            } else {
                Spacer(modifier = Modifier.height(24.dp))

                // Custom Time Picker with dropdowns
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.Center,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    // Hour Picker
                    TimeUnitPicker(
                        value = selectedHour,
                        onValueChange = { newHour ->
                            selectedHour = newHour
                            // Adjust minute if needed
                            if (isToday && newHour == currentHour && selectedMinute <= currentMinute) {
                                selectedMinute = currentMinute + 1
                                if (selectedMinute > 59) {
                                    selectedMinute = 0
                                }
                            }
                        },
                        range = minHour..23,
                        label = "시"
                    )

                    Text(
                        text = ":",
                        style = MaterialTheme.typography.displayMedium,
                        fontWeight = FontWeight.Bold,
                        modifier = Modifier.padding(horizontal = 16.dp)
                    )

                    // Minute Picker
                    TimeUnitPicker(
                        value = selectedMinute,
                        onValueChange = { selectedMinute = it },
                        range = minMinute..59,
                        label = "분"
                    )
                }

                Spacer(modifier = Modifier.height(24.dp))
            }

            Spacer(modifier = Modifier.height(16.dp))

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                TextButton(
                    onClick = onDismiss,
                    modifier = Modifier.weight(1f)
                ) {
                    Text(stringResource(R.string.cancel))
                }
                Button(
                    onClick = {
                        val selectedDate = Calendar.getInstance().apply {
                            timeInMillis = datePickerState.selectedDateMillis ?: System.currentTimeMillis()
                            set(Calendar.HOUR_OF_DAY, selectedHour)
                            set(Calendar.MINUTE, selectedMinute)
                            set(Calendar.SECOND, 0)
                            set(Calendar.MILLISECOND, 0)
                        }
                        onConfirm(selectedDate.time)
                    },
                    modifier = Modifier.weight(1f),
                    shape = RoundedCornerShape(12.dp)
                ) {
                    Text(stringResource(R.string.save))
                }
            }
        }
    }
}

@Composable
private fun TimeUnitPicker(
    value: Int,
    onValueChange: (Int) -> Unit,
    range: IntRange,
    label: String
) {
    var expanded by remember { mutableStateOf(false) }
    var textValue by remember(value) { mutableStateOf(String.format("%02d", value)) }

    // Ensure value is within range
    LaunchedEffect(range) {
        if (value < range.first) {
            onValueChange(range.first)
        }
    }

    Column(
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        // Increase button
        FilledIconButton(
            onClick = {
                if (value < range.last) {
                    onValueChange(value + 1)
                }
            },
            enabled = value < range.last,
            modifier = Modifier.size(44.dp),
            colors = IconButtonDefaults.filledIconButtonColors(
                containerColor = MaterialTheme.colorScheme.primaryContainer,
                disabledContainerColor = MaterialTheme.colorScheme.surfaceVariant
            )
        ) {
            Icon(
                Icons.Default.Add,
                contentDescription = null,
                modifier = Modifier.size(20.dp)
            )
        }

        Spacer(modifier = Modifier.height(8.dp))

        // Value display / Input
        Box {
            OutlinedTextField(
                value = textValue,
                onValueChange = { newText ->
                    if (newText.length <= 2 && newText.all { it.isDigit() }) {
                        textValue = newText
                        newText.toIntOrNull()?.let { num ->
                            if (num in range) {
                                onValueChange(num)
                            }
                        }
                    }
                },
                modifier = Modifier
                    .width(80.dp),
                textStyle = MaterialTheme.typography.headlineMedium.copy(
                    textAlign = TextAlign.Center,
                    fontWeight = FontWeight.Bold
                ),
                singleLine = true,
                shape = RoundedCornerShape(16.dp),
                colors = OutlinedTextFieldDefaults.colors(
                    focusedBorderColor = MaterialTheme.colorScheme.primary,
                    unfocusedBorderColor = MaterialTheme.colorScheme.outline.copy(alpha = 0.3f)
                )
            )

            // Dropdown trigger
            Box(
                modifier = Modifier
                    .matchParentSize()
                    .clickable { expanded = true }
            )

            DropdownMenu(
                expanded = expanded,
                onDismissRequest = { expanded = false },
                modifier = Modifier.height(200.dp)
            ) {
                range.forEach { num ->
                    DropdownMenuItem(
                        text = {
                            Text(
                                text = String.format("%02d", num),
                                fontWeight = if (num == value) FontWeight.Bold else FontWeight.Normal,
                                color = if (num == value) MaterialTheme.colorScheme.primary
                                       else MaterialTheme.colorScheme.onSurface
                            )
                        },
                        onClick = {
                            onValueChange(num)
                            textValue = String.format("%02d", num)
                            expanded = false
                        }
                    )
                }
            }
        }

        Spacer(modifier = Modifier.height(8.dp))

        // Decrease button
        FilledIconButton(
            onClick = {
                if (value > range.first) {
                    onValueChange(value - 1)
                }
            },
            enabled = value > range.first,
            modifier = Modifier.size(44.dp),
            colors = IconButtonDefaults.filledIconButtonColors(
                containerColor = MaterialTheme.colorScheme.secondaryContainer,
                disabledContainerColor = MaterialTheme.colorScheme.surfaceVariant
            )
        ) {
            Icon(
                Icons.Default.Remove,
                contentDescription = null,
                modifier = Modifier.size(20.dp)
            )
        }

        Spacer(modifier = Modifier.height(4.dp))

        Text(
            text = label,
            style = MaterialTheme.typography.labelMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}

@Composable
private fun TabButton(
    text: String,
    selected: Boolean,
    onClick: () -> Unit
) {
    Box(
        modifier = Modifier
            .clip(RoundedCornerShape(12.dp))
            .background(
                if (selected) MaterialTheme.colorScheme.primaryContainer
                else MaterialTheme.colorScheme.surfaceVariant
            )
            .clickable(onClick = onClick)
            .padding(horizontal = 24.dp, vertical = 12.dp)
    ) {
        Text(
            text = text,
            style = MaterialTheme.typography.bodyMedium,
            fontWeight = if (selected) FontWeight.Bold else FontWeight.Normal,
            color = if (selected) MaterialTheme.colorScheme.onPrimaryContainer
            else MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}

@Composable
private fun ChallengeCreatedDialog(
    shareUrl: String,
    onShare: () -> Unit,
    onDismiss: () -> Unit
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = {
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                modifier = Modifier.fillMaxWidth()
            ) {
                Text("🎉", fontSize = 48.sp)
                Spacer(modifier = Modifier.height(12.dp))
                Text(
                    text = stringResource(R.string.challenge_created),
                    textAlign = TextAlign.Center,
                    fontWeight = FontWeight.Bold
                )
            }
        },
        text = {
            Text(
                text = stringResource(R.string.challenge_created_message),
                textAlign = TextAlign.Center,
                modifier = Modifier.fillMaxWidth()
            )
        },
        confirmButton = {
            Button(
                onClick = onShare,
                shape = RoundedCornerShape(12.dp)
            ) {
                Text("📤 " + stringResource(R.string.share))
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text(stringResource(R.string.close))
            }
        },
        shape = RoundedCornerShape(24.dp)
    )
}
