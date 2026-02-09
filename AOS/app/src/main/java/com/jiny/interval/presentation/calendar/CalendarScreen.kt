package com.jiny.interval.presentation.calendar

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CalendarToday
import androidx.compose.material.icons.filled.ChevronLeft
import androidx.compose.material.icons.filled.ChevronRight
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Timer
import androidx.compose.material.icons.filled.Repeat
import androidx.compose.material.icons.filled.WbSunny
import androidx.compose.material.icons.filled.HealthAndSafety
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
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
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import kotlinx.coroutines.launch
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.platform.LocalContext
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.hilt.navigation.compose.hiltViewModel
import com.jiny.interval.R
import com.jiny.interval.domain.model.WorkoutRecord
import com.jiny.interval.presentation.components.BackgroundDecoration
import com.jiny.interval.util.TimeFormatter
import java.time.DayOfWeek
import java.time.LocalDate
import java.time.YearMonth
import java.time.format.DateTimeFormatter
import java.time.format.TextStyle
import java.util.Locale

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CalendarScreen(
    onNavigateToLogin: () -> Unit,
    viewModel: CalendarViewModel = hiltViewModel()
) {
    val currentMonth by viewModel.currentMonth.collectAsState()
    val selectedDate by viewModel.selectedDate.collectAsState()
    val records by viewModel.records.collectAsState()
    val healthWorkouts by viewModel.healthWorkouts.collectAsState()
    val healthAvailable by viewModel.healthAvailable.collectAsState()
    val healthPermissionsGranted by viewModel.healthPermissionsGranted.collectAsState()
    val isLoggedIn by viewModel.isLoggedIn.collectAsState()
    val error by viewModel.error.collectAsState()

    val snackbarHostState = remember { SnackbarHostState() }
    var recordToDelete by remember { mutableStateOf<WorkoutRecord?>(null) }
    val context = LocalContext.current
    val healthManager = remember { HealthConnectManager(context) }

    val coroutineScope = rememberCoroutineScope()

    // Health Connect permission launcher using the new API
    val permissionLauncher = rememberLauncherForActivityResult(
        contract = androidx.health.connect.client.PermissionController.createRequestPermissionResultContract()
    ) { grantedPermissions ->
        coroutineScope.launch {
            val granted = grantedPermissions.containsAll(healthManager.permissionSet)
            viewModel.setHealthPermissionsGranted(granted)
        }
    }

    LaunchedEffect(error) {
        error?.let {
            snackbarHostState.showSnackbar(it)
            viewModel.clearError()
        }
    }

    LaunchedEffect(Unit) {
        val available = healthManager.isAvailable()
        viewModel.setHealthAvailability(available)
        if (available) {
            val granted = healthManager.hasPermissions()
            viewModel.setHealthPermissionsGranted(granted)
            if (!granted) {
                permissionLauncher.launch(healthManager.permissionSet)
            }
        }
    }

    LaunchedEffect(currentMonth, healthPermissionsGranted) {
        if (healthPermissionsGranted) {
            val items = healthManager.readMonthlyWorkouts(currentMonth)
            viewModel.setHealthWorkouts(items)
        } else {
            viewModel.setHealthWorkouts(emptyList())
        }
    }

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

    Scaffold(
        snackbarHost = { SnackbarHost(snackbarHostState) }
    ) { paddingValues ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(backgroundBrush)
                .padding(paddingValues)
        ) {
            BackgroundDecoration()
            LazyColumn(
                modifier = Modifier.fillMaxSize(),
                contentPadding = PaddingValues(bottom = 0.dp)
            ) {
                item {
                    MonthHeader(
                        currentMonth = currentMonth,
                        onPrev = { viewModel.goToMonth(currentMonth.minusMonths(1)) },
                        onNext = { viewModel.goToMonth(currentMonth.plusMonths(1)) },
                        onToday = { viewModel.goToMonth(YearMonth.now()); viewModel.selectDate(null) }
                    )
                }

                item {
                    CalendarGrid(
                        currentMonth = currentMonth,
                        selectedDate = selectedDate,
                        records = records,
                        healthWorkouts = healthWorkouts,
                        onDateSelected = { viewModel.selectDate(it) }
                    )
                }

                item {
                    MonthSummary(records = records, healthWorkouts = healthWorkouts)
                }

                if (!isLoggedIn) {
                    item {
                        LoginPromptCard(onNavigateToLogin = onNavigateToLogin)
                    }
                }

                if (healthAvailable && !healthPermissionsGranted) {
                    item {
                        HealthConnectPromptCard(
                            onRequest = {
                                permissionLauncher.launch(healthManager.permissionSet)
                            }
                        )
                    }
                }

                selectedDate?.let { date ->
                    item {
                        SelectedDateDetail(
                            date = date,
                            records = records.filter { it.workoutDate == date.toString() },
                            healthWorkouts = healthWorkouts.filter { HealthConnectManager.toLocalDate(it.startTime) == date },
                            onClear = { viewModel.selectDate(null) },
                            onDelete = { recordToDelete = it }
                        )
                    }
                }
            }
        }
    }

    recordToDelete?.let { record ->
        AlertDialog(
            onDismissRequest = { recordToDelete = null },
            title = { Text(stringResource(R.string.delete_record)) },
            text = { Text(stringResource(R.string.delete_record_confirm, record.routineName)) },
            confirmButton = {
                TextButton(
                    onClick = {
                        viewModel.deleteRecord(record.id)
                        recordToDelete = null
                    }
                ) {
                    Text(stringResource(R.string.delete), color = MaterialTheme.colorScheme.error)
                }
            },
            dismissButton = {
                TextButton(onClick = { recordToDelete = null }) {
                    Text(stringResource(R.string.cancel))
                }
            }
        )
    }
}

@Composable
private fun MonthHeader(
    currentMonth: YearMonth,
    onPrev: () -> Unit,
    onNext: () -> Unit,
    onToday: () -> Unit
) {
    val monthTitle = currentMonth.format(java.time.format.DateTimeFormatter.ofPattern("MMMM yyyy"))
    val showToday = currentMonth != YearMonth.now()

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 4.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        IconButton(onClick = onPrev) {
            Icon(Icons.Default.ChevronLeft, contentDescription = null)
        }

        Spacer(modifier = Modifier.width(8.dp))

        Text(
            text = monthTitle,
            style = MaterialTheme.typography.titleLarge,
            fontWeight = FontWeight.Bold,
            modifier = Modifier.weight(1f),
            textAlign = TextAlign.Center
        )

        Spacer(modifier = Modifier.width(8.dp))

        if (showToday) {
            IconButton(onClick = onToday) {
                Icon(Icons.Default.CalendarToday, contentDescription = null, tint = MaterialTheme.colorScheme.primary)
            }
        }

        IconButton(onClick = onNext) {
            Icon(Icons.Default.ChevronRight, contentDescription = null)
        }
    }
}

@Composable
private fun CalendarGrid(
    currentMonth: YearMonth,
    selectedDate: LocalDate?,
    records: List<WorkoutRecord>,
    healthWorkouts: List<HealthWorkout>,
    onDateSelected: (LocalDate) -> Unit
) {
    val days = buildMonthGrid(currentMonth)
    val workoutDays = records.map { LocalDate.parse(it.workoutDate) }.toSet()
    val healthDays = healthWorkouts.map { HealthConnectManager.toLocalDate(it.startTime) }.toSet()
    val today = LocalDate.now()

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp)
            .background(MaterialTheme.colorScheme.surface, RoundedCornerShape(16.dp))
            .border(
                width = 1.dp,
                color = MaterialTheme.colorScheme.outline.copy(alpha = if (isSystemInDarkTheme()) 0.9f else 0.6f),
                shape = RoundedCornerShape(16.dp)
            )
            .padding(12.dp)
    ) {
        val weekDays = listOf(
            DayOfWeek.SUNDAY,
            DayOfWeek.MONDAY,
            DayOfWeek.TUESDAY,
            DayOfWeek.WEDNESDAY,
            DayOfWeek.THURSDAY,
            DayOfWeek.FRIDAY,
            DayOfWeek.SATURDAY
        )
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            weekDays.forEach { day ->
                Text(
                    text = day.getDisplayName(TextStyle.SHORT, Locale.getDefault()),
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.weight(1f),
                    textAlign = TextAlign.Center
                )
            }
        }

        Spacer(modifier = Modifier.height(8.dp))

        days.chunked(7).forEach { week ->
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                week.forEach { date ->
                    DayCell(
                        date = date,
                        isCurrentMonth = date.month == currentMonth.month,
                        isSelected = selectedDate == date,
                        isToday = date == today,
                        hasAppWorkout = workoutDays.contains(date),
                        hasHealthWorkout = healthDays.contains(date),
                        onClick = { onDateSelected(date) },
                        modifier = Modifier.weight(1f)
                    )
                }
            }
            Spacer(modifier = Modifier.height(6.dp))
        }
    }
}

@Composable
private fun DayCell(
    date: LocalDate,
    isCurrentMonth: Boolean,
    isSelected: Boolean,
    isToday: Boolean,
    hasAppWorkout: Boolean,
    hasHealthWorkout: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    val textColor = when {
        isSelected -> MaterialTheme.colorScheme.onPrimary
        isCurrentMonth -> MaterialTheme.colorScheme.onSurface
        else -> MaterialTheme.colorScheme.onSurfaceVariant
    }
    val backgroundColor = when {
        isSelected -> MaterialTheme.colorScheme.primary
        isToday -> MaterialTheme.colorScheme.primary.copy(alpha = 0.12f)
        else -> Color.Transparent
    }

    Box(
        modifier = modifier
            .aspectRatio(1f)
            .padding(2.dp)
            .clip(CircleShape)
            .background(backgroundColor)
            .clickable(onClick = onClick),
        contentAlignment = Alignment.Center
    ) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Text(
                text = date.dayOfMonth.toString(),
                style = MaterialTheme.typography.bodySmall,
                color = textColor
            )
            if (hasAppWorkout || hasHealthWorkout) {
                Spacer(modifier = Modifier.height(2.dp))
                Row(horizontalArrangement = Arrangement.spacedBy(3.dp)) {
                    if (hasHealthWorkout) {
                        Box(
                            modifier = Modifier
                                .size(5.dp)
                                .clip(CircleShape)
                                .background(Color(0xFF42A5F5))
                        )
                    }
                    if (hasAppWorkout) {
                        Box(
                            modifier = Modifier
                                .size(5.dp)
                                .clip(CircleShape)
                                .background(MaterialTheme.colorScheme.secondary)
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun MonthSummary(
    records: List<WorkoutRecord>,
    healthWorkouts: List<HealthWorkout>
) {
    val appDays = records.map { it.workoutDate }.toSet()
    val healthDays = healthWorkouts.map { HealthConnectManager.toLocalDate(it.startTime).toString() }.toSet()
    val workoutDays = (appDays + healthDays).size
    val totalDuration = records.sumOf { it.totalDuration } + healthWorkouts.sumOf { it.durationSeconds }

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 8.dp)
    ) {
        Card(
            modifier = Modifier
                .fillMaxWidth()
                .shadow(6.dp, RoundedCornerShape(16.dp), clip = false),
            shape = RoundedCornerShape(16.dp),
            colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)
        ) {
            Column(modifier = Modifier.padding(16.dp)) {
                Text(
                    text = stringResource(R.string.this_month),
                    style = MaterialTheme.typography.titleSmall,
                    fontWeight = FontWeight.Bold
                )

                Spacer(modifier = Modifier.height(12.dp))

                Row(horizontalArrangement = Arrangement.spacedBy(16.dp)) {
                    SummaryChip(
                        icon = Icons.Default.HealthAndSafety,
                        value = healthWorkouts.size.toString(),
                        label = stringResource(R.string.health_workouts),
                        color = Color(0xFF42A5F5),
                        modifier = Modifier.weight(1f)
                    )
                    SummaryChip(
                        icon = Icons.Default.Timer,
                        value = records.size.toString(),
                        label = stringResource(R.string.app_workouts),
                        color = MaterialTheme.colorScheme.primary,
                        modifier = Modifier.weight(1f)
                    )
                }
            }
        }

        // 운동 일수 & 총 시간 (카드 아래)
        if (workoutDays > 0 || totalDuration > 0) {
            Spacer(modifier = Modifier.height(10.dp))
            Row(
                modifier = Modifier.padding(start = 4.dp),
                horizontalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                // 운동 일수
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(
                        Icons.Default.CalendarToday,
                        contentDescription = null,
                        modifier = Modifier.size(16.dp),
                        tint = MaterialTheme.colorScheme.tertiary
                    )
                    Spacer(modifier = Modifier.width(4.dp))
                    Text(
                        text = "$workoutDays ${stringResource(R.string.workout_days)}",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }

                // 총 시간
                if (totalDuration > 0) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(
                            Icons.Default.Timer,
                            contentDescription = null,
                            modifier = Modifier.size(16.dp),
                            tint = Color(0xFF9C27B0)
                        )
                        Spacer(modifier = Modifier.width(4.dp))
                        Text(
                            text = stringResource(
                                R.string.total_time_format,
                                TimeFormatter.formatDuration(totalDuration)
                            ),
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun SummaryChip(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    value: String,
    label: String,
    color: Color,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier
            .background(MaterialTheme.colorScheme.surfaceVariant, RoundedCornerShape(12.dp))
            .padding(12.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(icon, contentDescription = null, tint = color)
        Spacer(modifier = Modifier.width(8.dp))
        Column {
            Text(text = value, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
            Text(text = label, style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
    }
}

@Composable
private fun LoginPromptCard(
    onNavigateToLogin: () -> Unit
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 8.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        shape = RoundedCornerShape(16.dp)
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(
                text = stringResource(R.string.login_to_view_calendar),
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                textAlign = TextAlign.Center
            )
            Spacer(modifier = Modifier.height(12.dp))
            TextButton(onClick = onNavigateToLogin) {
                Text(stringResource(R.string.login))
            }
        }
    }
}

@Composable
private fun HealthConnectPromptCard(
    onRequest: () -> Unit
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 8.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        shape = RoundedCornerShape(16.dp)
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(
                text = stringResource(R.string.health_connect_permission),
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                textAlign = TextAlign.Center
            )
            Spacer(modifier = Modifier.height(12.dp))
            TextButton(onClick = onRequest) {
                Text(stringResource(R.string.health_connect_grant))
            }
        }
    }
}

@Composable
private fun SelectedDateDetail(
    date: LocalDate,
    records: List<WorkoutRecord>,
    healthWorkouts: List<HealthWorkout>,
    onClear: () -> Unit,
    onDelete: (WorkoutRecord) -> Unit
) {
    val datePattern = stringResource(R.string.date_format_day)
    val dateFormatter = remember(datePattern) {
        java.time.format.DateTimeFormatter.ofPattern(datePattern)
    }
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 8.dp),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(
                    text = date.format(dateFormatter),
                    style = MaterialTheme.typography.titleSmall,
                    fontWeight = FontWeight.Bold,
                    modifier = Modifier.weight(1f)
                )
                IconButton(onClick = onClear) {
                    Icon(Icons.Default.Close, contentDescription = null)
                }
            }

            if (records.isEmpty() && healthWorkouts.isEmpty()) {
                Text(
                    text = stringResource(R.string.no_workouts_recorded),
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            } else {
                Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    healthWorkouts.forEach { workout ->
                        HealthWorkoutRow(workout = workout)
                    }
                    records.forEach { record ->
                        RecordRow(record = record, onDelete = { onDelete(record) })
                    }
                }
            }
        }
    }
}

@Composable
private fun RecordRow(
    record: WorkoutRecord,
    onDelete: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .background(MaterialTheme.colorScheme.surfaceVariant, RoundedCornerShape(12.dp))
            .padding(12.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(
            Icons.Default.Timer,
            contentDescription = null,
            tint = MaterialTheme.colorScheme.primary,
            modifier = Modifier
                .size(32.dp)
                .background(MaterialTheme.colorScheme.primary.copy(alpha = 0.1f), CircleShape)
                .padding(6.dp)
        )
        Spacer(modifier = Modifier.width(12.dp))
        Column(modifier = Modifier.weight(1f)) {
            Text(record.routineName, style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.Medium)
            Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(Icons.Default.Timer, contentDescription = null, modifier = Modifier.size(14.dp))
                    Spacer(modifier = Modifier.width(4.dp))
                    Text(TimeFormatter.formatDuration(record.totalDuration), style = MaterialTheme.typography.labelSmall)
                }
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(Icons.Default.Repeat, contentDescription = null, modifier = Modifier.size(14.dp))
                    Spacer(modifier = Modifier.width(4.dp))
                    Text("${record.roundsCompleted} ${stringResource(R.string.rounds)}", style = MaterialTheme.typography.labelSmall)
                }
            }
        }
        IconButton(onClick = onDelete) {
            Icon(Icons.Default.Delete, contentDescription = null, tint = MaterialTheme.colorScheme.error)
        }
    }
}

@Composable
private fun HealthWorkoutRow(
    workout: HealthWorkout
) {
    val timeFormatter = remember { DateTimeFormatter.ofPattern("HH:mm") }
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .background(MaterialTheme.colorScheme.surfaceVariant, RoundedCornerShape(12.dp))
            .padding(12.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(
            Icons.Default.HealthAndSafety,
            contentDescription = null,
            tint = Color(0xFF42A5F5),
            modifier = Modifier
                .size(32.dp)
                .background(Color(0xFF42A5F5).copy(alpha = 0.12f), CircleShape)
                .padding(6.dp)
        )
        Spacer(modifier = Modifier.width(12.dp))
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = stringResource(R.string.health_workout_label),
                style = MaterialTheme.typography.bodyMedium,
                fontWeight = FontWeight.Medium
            )
            Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(Icons.Default.Timer, contentDescription = null, modifier = Modifier.size(14.dp))
                    Spacer(modifier = Modifier.width(4.dp))
                    Text(TimeFormatter.formatDuration(workout.durationSeconds), style = MaterialTheme.typography.labelSmall)
                }
                Row(verticalAlignment = Alignment.CenterVertically) {
                    val time = HealthConnectManager.toLocalTime(workout.startTime)
                    Text(time.format(timeFormatter), style = MaterialTheme.typography.labelSmall)
                }
            }
        }
    }
}

private fun buildMonthGrid(month: YearMonth): List<LocalDate> {
    val firstDay = month.atDay(1)
    val lastDay = month.atEndOfMonth()
    val startOfGrid = firstDay.minusDays(((firstDay.dayOfWeek.value % 7).toLong()))
    val endOfGrid = lastDay.plusDays((6 - (lastDay.dayOfWeek.value % 7)).toLong())
    val days = mutableListOf<LocalDate>()
    var current = startOfGrid
    while (!current.isAfter(endOfGrid)) {
        days.add(current)
        current = current.plusDays(1)
    }
    return days
}
