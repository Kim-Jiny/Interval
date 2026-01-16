package com.jiny.interval.presentation.editor

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Remove
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilterChip
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.jiny.interval.R
import com.jiny.interval.domain.model.IntervalType
import com.jiny.interval.presentation.components.IntervalItem

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun RoutineEditorScreen(
    onNavigateBack: () -> Unit,
    onSave: () -> Unit,
    viewModel: RoutineEditorViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val editingInterval by viewModel.editingInterval.collectAsState()

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        if (uiState.isEditing) stringResource(R.string.edit_routine)
                        else stringResource(R.string.new_routine)
                    )
                },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(
                            imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                            contentDescription = stringResource(R.string.back)
                        )
                    }
                },
                actions = {
                    TextButton(
                        onClick = { viewModel.saveRoutine(onSave) },
                        enabled = viewModel.canSave()
                    ) {
                        Text(stringResource(R.string.save))
                    }
                }
            )
        },
        floatingActionButton = {
            FloatingActionButton(
                onClick = { viewModel.startEditingInterval() }
            ) {
                Icon(
                    imageVector = Icons.Default.Add,
                    contentDescription = stringResource(R.string.add_interval)
                )
            }
        }
    ) { paddingValues ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues),
            contentPadding = PaddingValues(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Routine name
            item {
                OutlinedTextField(
                    value = uiState.name,
                    onValueChange = { viewModel.updateName(it) },
                    label = { Text(stringResource(R.string.routine_name)) },
                    modifier = Modifier.fillMaxWidth(),
                    singleLine = true
                )
            }

            // Rounds selector
            item {
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(12.dp)
                ) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(16.dp),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            text = stringResource(R.string.rounds),
                            style = MaterialTheme.typography.titleMedium
                        )

                        Row(
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            IconButton(
                                onClick = { viewModel.decrementRounds() },
                                enabled = uiState.rounds > 1
                            ) {
                                Icon(
                                    imageVector = Icons.Default.Remove,
                                    contentDescription = stringResource(R.string.decrease_rounds)
                                )
                            }

                            Text(
                                text = "${uiState.rounds}",
                                style = MaterialTheme.typography.headlineSmall,
                                modifier = Modifier.width(48.dp),
                                textAlign = androidx.compose.ui.text.style.TextAlign.Center
                            )

                            IconButton(
                                onClick = { viewModel.incrementRounds() },
                                enabled = uiState.rounds < 99
                            ) {
                                Icon(
                                    imageVector = Icons.Default.Add,
                                    contentDescription = stringResource(R.string.increase_rounds)
                                )
                            }
                        }
                    }
                }
            }

            // Intervals header
            item {
                Text(
                    text = stringResource(R.string.intervals),
                    style = MaterialTheme.typography.titleMedium,
                    modifier = Modifier.padding(top = 8.dp)
                )
            }

            // Interval list
            if (uiState.intervals.isEmpty()) {
                item {
                    Text(
                        text = stringResource(R.string.no_intervals),
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }

            itemsIndexed(
                items = uiState.intervals,
                key = { _, interval -> interval.id }
            ) { index, interval ->
                IntervalItem(
                    interval = interval,
                    onDelete = { viewModel.deleteInterval(index) },
                    onClick = { viewModel.startEditingInterval(index) }
                )
            }

            // Bottom spacing for FAB
            item {
                Spacer(modifier = Modifier.height(80.dp))
            }
        }
    }

    // Interval editing dialog
    editingInterval?.let { editing ->
        IntervalEditDialog(
            editing = editing,
            onNameChange = { viewModel.updateEditingIntervalName(it) },
            onDurationChange = { viewModel.updateEditingIntervalDuration(it) },
            onTypeChange = { viewModel.updateEditingIntervalType(it) },
            onSave = { viewModel.saveEditingInterval() },
            onDismiss = { viewModel.cancelEditingInterval() }
        )
    }
}

@Composable
private fun IntervalEditDialog(
    editing: EditingInterval,
    onNameChange: (String) -> Unit,
    onDurationChange: (Int) -> Unit,
    onTypeChange: (IntervalType) -> Unit,
    onSave: () -> Unit,
    onDismiss: () -> Unit
) {
    val minutes = editing.duration / 60
    val seconds = editing.duration % 60

    AlertDialog(
        onDismissRequest = onDismiss,
        title = {
            Text(
                if (editing.index != null) stringResource(R.string.edit_interval_title)
                else stringResource(R.string.add_interval_title)
            )
        },
        text = {
            Column(
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                OutlinedTextField(
                    value = editing.name,
                    onValueChange = onNameChange,
                    label = { Text(stringResource(R.string.interval_name)) },
                    modifier = Modifier.fillMaxWidth(),
                    singleLine = true
                )

                // Duration input with minutes and seconds
                Column {
                    Text(
                        text = stringResource(R.string.duration),
                        style = MaterialTheme.typography.bodyMedium
                    )
                    Spacer(modifier = Modifier.height(8.dp))
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.Center,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        // Minutes
                        Column(
                            horizontalAlignment = Alignment.CenterHorizontally
                        ) {
                            IconButton(
                                onClick = { onDurationChange(editing.duration + 60) },
                                enabled = editing.duration < 3540 // max 59 minutes
                            ) {
                                Icon(Icons.Default.Add, contentDescription = stringResource(R.string.add_minute))
                            }
                            OutlinedTextField(
                                value = minutes.toString(),
                                onValueChange = { value ->
                                    val newMinutes = value.toIntOrNull()?.coerceIn(0, 59) ?: 0
                                    onDurationChange(newMinutes * 60 + seconds)
                                },
                                modifier = Modifier.width(72.dp),
                                textStyle = MaterialTheme.typography.headlineSmall.copy(
                                    textAlign = androidx.compose.ui.text.style.TextAlign.Center
                                ),
                                singleLine = true,
                                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number)
                            )
                            IconButton(
                                onClick = { onDurationChange((editing.duration - 60).coerceAtLeast(1)) },
                                enabled = minutes > 0
                            ) {
                                Icon(Icons.Default.Remove, contentDescription = stringResource(R.string.remove_minute))
                            }
                            Text(stringResource(R.string.min), style = MaterialTheme.typography.labelSmall)
                        }

                        Text(
                            text = ":",
                            style = MaterialTheme.typography.headlineMedium,
                            modifier = Modifier.padding(horizontal = 8.dp)
                        )

                        // Seconds
                        Column(
                            horizontalAlignment = Alignment.CenterHorizontally
                        ) {
                            IconButton(
                                onClick = {
                                    val newSeconds = if (seconds >= 59) 0 else seconds + 1
                                    val newMinutes = if (seconds >= 59) minutes + 1 else minutes
                                    onDurationChange((newMinutes * 60 + newSeconds).coerceIn(1, 3599))
                                }
                            ) {
                                Icon(Icons.Default.Add, contentDescription = stringResource(R.string.add_seconds))
                            }
                            OutlinedTextField(
                                value = String.format("%02d", seconds),
                                onValueChange = { value ->
                                    val newSeconds = value.toIntOrNull()?.coerceIn(0, 59) ?: 0
                                    val totalDuration = minutes * 60 + newSeconds
                                    onDurationChange(totalDuration.coerceAtLeast(1))
                                },
                                modifier = Modifier.width(72.dp),
                                textStyle = MaterialTheme.typography.headlineSmall.copy(
                                    textAlign = androidx.compose.ui.text.style.TextAlign.Center
                                ),
                                singleLine = true,
                                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number)
                            )
                            IconButton(
                                onClick = {
                                    val newSeconds = if (seconds == 0) 59 else seconds - 1
                                    val newMinutes = if (seconds == 0) (minutes - 1).coerceAtLeast(0) else minutes
                                    onDurationChange((newMinutes * 60 + newSeconds).coerceAtLeast(1))
                                },
                                enabled = editing.duration > 1
                            ) {
                                Icon(Icons.Default.Remove, contentDescription = stringResource(R.string.remove_seconds))
                            }
                            Text(stringResource(R.string.sec), style = MaterialTheme.typography.labelSmall)
                        }
                    }
                }

                // Interval type
                Column {
                    Text(
                        text = stringResource(R.string.type),
                        style = MaterialTheme.typography.bodyMedium
                    )
                    Spacer(modifier = Modifier.height(8.dp))
                    Row(
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        IntervalType.entries.take(2).forEach { type ->
                            FilterChip(
                                selected = editing.type == type,
                                onClick = { onTypeChange(type) },
                                label = { Text(type.toLocalizedString()) }
                            )
                        }
                    }
                    Spacer(modifier = Modifier.height(4.dp))
                    Row(
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        IntervalType.entries.drop(2).forEach { type ->
                            FilterChip(
                                selected = editing.type == type,
                                onClick = { onTypeChange(type) },
                                label = { Text(type.toLocalizedString()) }
                            )
                        }
                    }
                }
            }
        },
        confirmButton = {
            Button(onClick = onSave) {
                Icon(
                    imageVector = Icons.Default.Check,
                    contentDescription = null
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text(stringResource(R.string.save))
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
private fun IntervalType.toLocalizedString(): String {
    return when (this) {
        IntervalType.WORKOUT -> stringResource(R.string.type_workout)
        IntervalType.REST -> stringResource(R.string.type_rest)
        IntervalType.WARMUP -> stringResource(R.string.type_warmup)
        IntervalType.COOLDOWN -> stringResource(R.string.type_cooldown)
    }
}
