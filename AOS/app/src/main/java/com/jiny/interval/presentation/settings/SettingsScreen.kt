package com.jiny.interval.presentation.settings

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.Logout
import androidx.compose.material.icons.filled.AccountCircle
import androidx.compose.material.icons.filled.DeleteForever
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.Login
import androidx.compose.material.icons.filled.MusicNote
import androidx.compose.material.icons.filled.RecordVoiceOver
import androidx.compose.material.icons.filled.Vibration
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
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
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.jiny.interval.R

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(
    onNavigateBack: () -> Unit,
    onNavigateToLogin: () -> Unit,
    viewModel: SettingsViewModel = hiltViewModel()
) {
    val settings by viewModel.settings.collectAsState()
    val isLoggedIn by viewModel.isLoggedIn.collectAsState()
    val currentUser by viewModel.currentUser.collectAsState()
    val deleteAccountState by viewModel.deleteAccountState.collectAsState()
    val updateNicknameState by viewModel.updateNicknameState.collectAsState()

    var showLogoutDialog by remember { mutableStateOf(false) }
    var showDeleteAccountDialog by remember { mutableStateOf(false) }
    var showNicknameDialog by remember { mutableStateOf(false) }
    var nicknameInput by remember { mutableStateOf("") }
    val snackbarHostState = remember { SnackbarHostState() }

    val deleteSuccessMessage = stringResource(R.string.delete_account_success)
    val nicknameSuccessMessage = stringResource(R.string.nickname_update_success)

    LaunchedEffect(deleteAccountState) {
        when (deleteAccountState) {
            is DeleteAccountState.Success -> {
                snackbarHostState.showSnackbar(deleteSuccessMessage)
                viewModel.resetDeleteAccountState()
            }
            is DeleteAccountState.Error -> {
                snackbarHostState.showSnackbar((deleteAccountState as DeleteAccountState.Error).message)
                viewModel.resetDeleteAccountState()
            }
            else -> {}
        }
    }

    LaunchedEffect(updateNicknameState) {
        when (updateNicknameState) {
            is UpdateNicknameState.Success -> {
                showNicknameDialog = false
                snackbarHostState.showSnackbar(nicknameSuccessMessage)
                viewModel.resetUpdateNicknameState()
            }
            is UpdateNicknameState.Error -> {
                snackbarHostState.showSnackbar((updateNicknameState as UpdateNicknameState.Error).message)
                viewModel.resetUpdateNicknameState()
            }
            else -> {}
        }
    }

    if (showLogoutDialog) {
        AlertDialog(
            onDismissRequest = { showLogoutDialog = false },
            title = { Text(stringResource(R.string.logout)) },
            text = { Text(stringResource(R.string.logout_confirm)) },
            confirmButton = {
                TextButton(onClick = {
                    viewModel.logout()
                    showLogoutDialog = false
                }) {
                    Text(stringResource(R.string.logout))
                }
            },
            dismissButton = {
                TextButton(onClick = { showLogoutDialog = false }) {
                    Text(stringResource(R.string.cancel))
                }
            }
        )
    }

    if (showDeleteAccountDialog) {
        AlertDialog(
            onDismissRequest = { showDeleteAccountDialog = false },
            title = { Text(stringResource(R.string.delete_account)) },
            text = { Text(stringResource(R.string.delete_account_confirm)) },
            confirmButton = {
                TextButton(onClick = {
                    viewModel.deleteAccount()
                    showDeleteAccountDialog = false
                }) {
                    Text(
                        stringResource(R.string.delete),
                        color = MaterialTheme.colorScheme.error
                    )
                }
            },
            dismissButton = {
                TextButton(onClick = { showDeleteAccountDialog = false }) {
                    Text(stringResource(R.string.cancel))
                }
            }
        )
    }

    if (showNicknameDialog) {
        AlertDialog(
            onDismissRequest = {
                if (updateNicknameState !is UpdateNicknameState.Loading) {
                    showNicknameDialog = false
                }
            },
            title = { Text(stringResource(R.string.change_nickname)) },
            text = {
                Column {
                    Text(
                        text = stringResource(R.string.nickname_requirements),
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Spacer(modifier = Modifier.height(12.dp))
                    OutlinedTextField(
                        value = nicknameInput,
                        onValueChange = { nicknameInput = it },
                        label = { Text(stringResource(R.string.nickname)) },
                        singleLine = true,
                        enabled = updateNicknameState !is UpdateNicknameState.Loading,
                        modifier = Modifier.fillMaxWidth()
                    )
                }
            },
            confirmButton = {
                TextButton(
                    onClick = { viewModel.updateNickname(nicknameInput) },
                    enabled = updateNicknameState !is UpdateNicknameState.Loading
                ) {
                    if (updateNicknameState is UpdateNicknameState.Loading) {
                        CircularProgressIndicator(
                            modifier = Modifier.size(16.dp),
                            strokeWidth = 2.dp
                        )
                    } else {
                        Text(stringResource(R.string.save))
                    }
                }
            },
            dismissButton = {
                TextButton(
                    onClick = { showNicknameDialog = false },
                    enabled = updateNicknameState !is UpdateNicknameState.Loading
                ) {
                    Text(stringResource(R.string.cancel))
                }
            }
        )
    }

    Scaffold(
        contentWindowInsets = WindowInsets(0, 0, 0, 0),
        topBar = {
            TopAppBar(
                title = { Text(stringResource(R.string.settings)) },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(
                            imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                            contentDescription = stringResource(R.string.back)
                        )
                    }
                }
            )
        },
        snackbarHost = { SnackbarHost(snackbarHostState) }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .verticalScroll(rememberScrollState())
        ) {
            // Account Section
            SectionHeader(title = stringResource(R.string.account))

            if (isLoggedIn && currentUser != null) {
                // Logged in state
                AccountItem(
                    icon = Icons.Default.AccountCircle,
                    title = currentUser?.displayName ?: "",
                    subtitle = currentUser?.email ?: ""
                )

                ActionItem(
                    icon = Icons.Default.Edit,
                    title = stringResource(R.string.change_nickname),
                    onClick = {
                        nicknameInput = currentUser?.nickname ?: ""
                        showNicknameDialog = true
                    }
                )

                ActionItem(
                    icon = Icons.AutoMirrored.Filled.Logout,
                    title = stringResource(R.string.logout),
                    onClick = { showLogoutDialog = true }
                )

                ActionItem(
                    icon = Icons.Default.DeleteForever,
                    title = stringResource(R.string.delete_account),
                    onClick = { showDeleteAccountDialog = true },
                    isDestructive = true,
                    isLoading = deleteAccountState is DeleteAccountState.Loading
                )
            } else {
                // Not logged in state
                ActionItem(
                    icon = Icons.Default.Login,
                    title = stringResource(R.string.login),
                    onClick = onNavigateToLogin
                )
            }

            HorizontalDivider(modifier = Modifier.padding(vertical = 16.dp))

            // Timer Settings Section
            SectionHeader(title = stringResource(R.string.timer_settings))

            SettingItem(
                icon = Icons.Default.Vibration,
                title = stringResource(R.string.vibration),
                description = stringResource(R.string.vibration_desc),
                checked = settings.vibrationEnabled,
                onCheckedChange = { viewModel.updateVibration(it) }
            )

            SettingItem(
                icon = Icons.Default.RecordVoiceOver,
                title = stringResource(R.string.voice_guidance),
                description = stringResource(R.string.voice_guidance_desc),
                checked = settings.voiceGuidanceEnabled,
                onCheckedChange = { viewModel.updateVoiceGuidance(it) }
            )

            SettingItem(
                icon = Icons.Default.MusicNote,
                title = stringResource(R.string.background_sound),
                description = stringResource(R.string.background_sound_desc),
                checked = settings.backgroundSoundEnabled,
                onCheckedChange = { viewModel.updateBackgroundSound(it) }
            )

            HorizontalDivider(modifier = Modifier.padding(vertical = 16.dp))

            // About Section
            SectionHeader(title = stringResource(R.string.about))

            AboutItem(
                icon = Icons.Default.Info,
                title = stringResource(R.string.version),
                value = "1.0.0"
            )

            Spacer(modifier = Modifier.height(32.dp))
        }
    }
}

@Composable
private fun SectionHeader(
    title: String,
    modifier: Modifier = Modifier
) {
    Text(
        text = title,
        style = MaterialTheme.typography.titleSmall,
        color = MaterialTheme.colorScheme.primary,
        modifier = modifier.padding(horizontal = 16.dp, vertical = 8.dp)
    )
}

@Composable
private fun SettingItem(
    icon: ImageVector,
    title: String,
    description: String,
    checked: Boolean,
    onCheckedChange: (Boolean) -> Unit,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(
            imageVector = icon,
            contentDescription = null,
            tint = MaterialTheme.colorScheme.onSurfaceVariant
        )

        Column(
            modifier = Modifier
                .weight(1f)
                .padding(horizontal = 16.dp)
        ) {
            Text(
                text = title,
                style = MaterialTheme.typography.bodyLarge
            )
            Text(
                text = description,
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }

        Switch(
            checked = checked,
            onCheckedChange = onCheckedChange
        )
    }
}

@Composable
private fun AboutItem(
    icon: ImageVector,
    title: String,
    value: String,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(
            imageVector = icon,
            contentDescription = null,
            tint = MaterialTheme.colorScheme.onSurfaceVariant
        )

        Text(
            text = title,
            style = MaterialTheme.typography.bodyLarge,
            modifier = Modifier
                .weight(1f)
                .padding(horizontal = 16.dp)
        )

        Text(
            text = value,
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}

@Composable
private fun AccountItem(
    icon: ImageVector,
    title: String,
    subtitle: String,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(
            imageVector = icon,
            contentDescription = null,
            tint = MaterialTheme.colorScheme.primary,
            modifier = Modifier.size(40.dp)
        )

        Column(
            modifier = Modifier
                .weight(1f)
                .padding(horizontal = 16.dp)
        ) {
            Text(
                text = title,
                style = MaterialTheme.typography.bodyLarge
            )
            if (subtitle.isNotEmpty()) {
                Text(
                    text = subtitle,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
}

@Composable
private fun ActionItem(
    icon: ImageVector,
    title: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    isDestructive: Boolean = false,
    isLoading: Boolean = false
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .clickable(enabled = !isLoading) { onClick() }
            .padding(horizontal = 16.dp, vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(
            imageVector = icon,
            contentDescription = null,
            tint = if (isDestructive) MaterialTheme.colorScheme.error else MaterialTheme.colorScheme.onSurfaceVariant
        )

        Text(
            text = title,
            style = MaterialTheme.typography.bodyLarge,
            color = if (isDestructive) MaterialTheme.colorScheme.error else MaterialTheme.colorScheme.onSurface,
            modifier = Modifier
                .weight(1f)
                .padding(horizontal = 16.dp)
        )

        if (isLoading) {
            CircularProgressIndicator(
                modifier = Modifier.size(24.dp),
                strokeWidth = 2.dp
            )
        }
    }
}
