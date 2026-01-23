package com.jiny.interval.presentation.community

import android.app.DatePickerDialog
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
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.DateRange
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilterChip
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Slider
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Switch
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
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
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
    val dateFormat = remember { SimpleDateFormat("yyyy.MM.dd", Locale.getDefault()) }
    var showSuccessDialog by remember { mutableStateOf(false) }

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

    if (showSuccessDialog) {
        ChallengeCreatedDialog(
            shareUrl = createdShareUrl ?: "",
            onShare = {
                createdShareUrl?.let { shareChallenge(it) }
            },
            onDismiss = {
                showSuccessDialog = false
                onChallengeCreated()
            }
        )
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(stringResource(R.string.create_challenge)) },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = stringResource(R.string.back))
                    }
                }
            )
        },
        snackbarHost = { SnackbarHost(snackbarHostState) }
    ) { paddingValues ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .pointerInput(Unit) {
                    detectTapGestures(onTap = {
                        focusManager.clearFocus()
                    })
                },
            contentPadding = PaddingValues(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Mileage Balance Info
            item {
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    colors = CardDefaults.cardColors(
                        containerColor = MaterialTheme.colorScheme.surfaceVariant
                    )
                ) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(16.dp),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            text = stringResource(R.string.my_mileage),
                            style = MaterialTheme.typography.bodyMedium
                        )
                        Text(
                            text = mileageBalance.formattedBalance,
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold,
                            color = MaterialTheme.colorScheme.primary
                        )
                    }
                }
            }

            // Title Input
            item {
                SectionTitle(stringResource(R.string.challenge_title))
                Spacer(modifier = Modifier.height(8.dp))
                OutlinedTextField(
                    value = title,
                    onValueChange = viewModel::updateTitle,
                    modifier = Modifier.fillMaxWidth(),
                    placeholder = { Text(stringResource(R.string.challenge_title_hint)) },
                    singleLine = true
                )
            }

            // Description Input
            item {
                SectionTitle(stringResource(R.string.challenge_description))
                Spacer(modifier = Modifier.height(8.dp))
                OutlinedTextField(
                    value = description,
                    onValueChange = viewModel::updateDescription,
                    modifier = Modifier.fillMaxWidth(),
                    placeholder = { Text(stringResource(R.string.challenge_description_hint)) },
                    minLines = 3,
                    maxLines = 5
                )
            }

            // Routine Selection
            item {
                SectionTitle(stringResource(R.string.select_routine))
                Spacer(modifier = Modifier.height(8.dp))

                if (routines.isEmpty()) {
                    Text(
                        text = stringResource(R.string.no_routines_available),
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                } else {
                    LazyRow(
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        items(routines, key = { it.id }) { routine ->
                            RoutineChip(
                                routine = routine,
                                isSelected = selectedRoutine?.id == routine.id,
                                onClick = { viewModel.selectRoutine(routine) }
                            )
                        }
                    }
                }
            }

            // Registration End Date
            item {
                SectionTitle(stringResource(R.string.registration_end_date))
                Spacer(modifier = Modifier.height(8.dp))
                DatePickerField(
                    date = registrationEndDate,
                    dateFormat = dateFormat,
                    onClick = {
                        showDatePicker(context, registrationEndDate) { date ->
                            viewModel.updateRegistrationEndDate(date)
                        }
                    }
                )
            }

            // Challenge Period
            item {
                SectionTitle(stringResource(R.string.challenge_period))
                Spacer(modifier = Modifier.height(8.dp))
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    Column(modifier = Modifier.weight(1f)) {
                        Text(
                            text = stringResource(R.string.start_date),
                            style = MaterialTheme.typography.labelMedium
                        )
                        Spacer(modifier = Modifier.height(4.dp))
                        DatePickerField(
                            date = challengeStartDate,
                            dateFormat = dateFormat,
                            onClick = {
                                showDatePicker(context, challengeStartDate) { date ->
                                    viewModel.updateChallengeStartDate(date)
                                }
                            }
                        )
                    }
                    Column(modifier = Modifier.weight(1f)) {
                        Text(
                            text = stringResource(R.string.end_date),
                            style = MaterialTheme.typography.labelMedium
                        )
                        Spacer(modifier = Modifier.height(4.dp))
                        DatePickerField(
                            date = challengeEndDate,
                            dateFormat = dateFormat,
                            onClick = {
                                showDatePicker(context, challengeEndDate) { date ->
                                    viewModel.updateChallengeEndDate(date)
                                }
                            }
                        )
                    }
                }
            }

            // Entry Fee
            item {
                SectionTitle(stringResource(R.string.entry_fee_setting))
                Spacer(modifier = Modifier.height(8.dp))

                Text(
                    text = "${entryFee}M",
                    style = MaterialTheme.typography.headlineSmall,
                    fontWeight = FontWeight.Bold,
                    color = MaterialTheme.colorScheme.primary
                )

                Slider(
                    value = entryFee.toFloat(),
                    onValueChange = { viewModel.updateEntryFee(it.toInt()) },
                    valueRange = 0f..1000f,
                    steps = 19,
                    modifier = Modifier.fillMaxWidth()
                )

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Text("0M", style = MaterialTheme.typography.labelSmall)
                    Text("1000M", style = MaterialTheme.typography.labelSmall)
                }
            }

            // Public Toggle
            item {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Column {
                        Text(
                            text = stringResource(R.string.public_challenge),
                            style = MaterialTheme.typography.bodyLarge,
                            fontWeight = FontWeight.Medium
                        )
                        Text(
                            text = stringResource(R.string.public_challenge_desc),
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                    Switch(
                        checked = isPublic,
                        onCheckedChange = viewModel::updateIsPublic
                    )
                }
            }

            // Max Participants
            item {
                SectionTitle(stringResource(R.string.max_participants))
                Spacer(modifier = Modifier.height(8.dp))

                LazyRow(
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    item {
                        FilterChip(
                            selected = maxParticipants == null,
                            onClick = { viewModel.updateMaxParticipants(null) },
                            label = { Text(stringResource(R.string.unlimited)) }
                        )
                    }
                    items(listOf(5, 10, 20, 50, 100)) { count ->
                        FilterChip(
                            selected = maxParticipants == count,
                            onClick = { viewModel.updateMaxParticipants(count) },
                            label = { Text("$count") }
                        )
                    }
                }
            }

            // Create Button
            item {
                Spacer(modifier = Modifier.height(16.dp))
                Button(
                    onClick = { viewModel.createChallenge { showSuccessDialog = true } },
                    modifier = Modifier.fillMaxWidth(),
                    enabled = !isLoading && selectedRoutine != null && title.isNotBlank(),
                    contentPadding = PaddingValues(16.dp)
                ) {
                    if (isLoading) {
                        CircularProgressIndicator(
                            modifier = Modifier.size(20.dp),
                            strokeWidth = 2.dp
                        )
                    } else {
                        Text(stringResource(R.string.create_challenge))
                    }
                }
                Spacer(modifier = Modifier.height(32.dp))
            }
        }
    }
}

@Composable
private fun SectionTitle(text: String) {
    Text(
        text = text,
        style = MaterialTheme.typography.titleMedium,
        fontWeight = FontWeight.Bold
    )
}

@Composable
private fun RoutineChip(
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
                        RoundedCornerShape(12.dp)
                    )
                } else Modifier
            ),
        colors = CardDefaults.cardColors(
            containerColor = if (isSelected)
                MaterialTheme.colorScheme.primaryContainer
            else
                MaterialTheme.colorScheme.surfaceVariant
        ),
        shape = RoundedCornerShape(12.dp)
    ) {
        Row(
            modifier = Modifier.padding(12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            if (isSelected) {
                Icon(
                    Icons.Default.Check,
                    contentDescription = null,
                    modifier = Modifier.size(16.dp),
                    tint = MaterialTheme.colorScheme.primary
                )
                Spacer(modifier = Modifier.width(4.dp))
            }
            Column {
                Text(
                    text = routine.name,
                    style = MaterialTheme.typography.bodyMedium,
                    fontWeight = FontWeight.Medium
                )
                Text(
                    text = "${routine.rounds} rounds • ${routine.intervals.size} intervals",
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
}

@Composable
private fun DatePickerField(
    date: Date,
    dateFormat: SimpleDateFormat,
    onClick: () -> Unit
) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(8.dp))
            .background(MaterialTheme.colorScheme.surfaceVariant)
            .clickable(onClick = onClick)
            .padding(16.dp)
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = dateFormat.format(date),
                style = MaterialTheme.typography.bodyLarge
            )
            Icon(
                Icons.Default.DateRange,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}

private fun showDatePicker(
    context: android.content.Context,
    initialDate: Date,
    onDateSelected: (Date) -> Unit
) {
    val calendar = Calendar.getInstance()
    calendar.time = initialDate

    DatePickerDialog(
        context,
        { _, year, month, dayOfMonth ->
            val selectedCalendar = Calendar.getInstance()
            selectedCalendar.set(year, month, dayOfMonth)
            onDateSelected(selectedCalendar.time)
        },
        calendar.get(Calendar.YEAR),
        calendar.get(Calendar.MONTH),
        calendar.get(Calendar.DAY_OF_MONTH)
    ).apply {
        datePicker.minDate = System.currentTimeMillis()
    }.show()
}

@Composable
private fun ChallengeCreatedDialog(
    shareUrl: String,
    onShare: () -> Unit,
    onDismiss: () -> Unit
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(stringResource(R.string.challenge_created)) },
        text = {
            Column {
                Text(stringResource(R.string.challenge_created_message))
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    text = shareUrl,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.primary
                )
            }
        },
        confirmButton = {
            Button(onClick = {
                onShare()
            }) {
                Text(stringResource(R.string.share))
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text(stringResource(R.string.close))
            }
        }
    )
}
