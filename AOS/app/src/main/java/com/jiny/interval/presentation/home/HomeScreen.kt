package com.jiny.interval.presentation.home

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.AlertDialog
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
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.jiny.interval.R
import com.jiny.interval.domain.model.Routine
import com.jiny.interval.presentation.components.RoutineCard

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HomeScreen(
    onRoutineClick: (String) -> Unit,
    onEditRoutine: (String) -> Unit,
    onAddRoutine: () -> Unit,
    onSettingsClick: () -> Unit,
    viewModel: HomeViewModel = hiltViewModel()
) {
    val selectedTab by viewModel.selectedTab.collectAsState()
    val allRoutines by viewModel.allRoutines.collectAsState()
    val favoriteRoutines by viewModel.favoriteRoutines.collectAsState()

    var routineToDelete by remember { mutableStateOf<Routine?>(null) }

    val displayedRoutines = when (selectedTab) {
        HomeTab.FAVORITES -> favoriteRoutines
        HomeTab.ALL -> allRoutines
    }

    Scaffold(
        topBar = {
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
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            TabRow(
                selectedTabIndex = selectedTab.ordinal
            ) {
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

            AnimatedVisibility(
                visible = displayedRoutines.isEmpty(),
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
                visible = displayedRoutines.isNotEmpty(),
                enter = fadeIn(),
                exit = fadeOut()
            ) {
                LazyColumn(
                    contentPadding = PaddingValues(16.dp),
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
