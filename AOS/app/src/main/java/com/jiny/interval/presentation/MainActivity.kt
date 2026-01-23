package com.jiny.interval.presentation

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.runtime.mutableStateOf
import androidx.compose.ui.Modifier
import androidx.core.content.ContextCompat
import androidx.navigation.compose.rememberNavController
import com.jiny.interval.data.remote.GoogleAuthManager
import com.jiny.interval.presentation.theme.IntervalTheme
import dagger.hilt.android.AndroidEntryPoint
import javax.inject.Inject

@AndroidEntryPoint
class MainActivity : ComponentActivity() {

    @Inject
    lateinit var googleAuthManager: GoogleAuthManager

    // Pending deep link share code
    private val pendingShareCode = mutableStateOf<String?>(null)

    private val requestPermissionLauncher = registerForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { isGranted: Boolean ->
        // Handle permission result if needed
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        requestNotificationPermission()

        // Handle deep link from initial intent
        handleDeepLink(intent)

        setContent {
            IntervalTheme {
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = MaterialTheme.colorScheme.background
                ) {
                    val navController = rememberNavController()
                    MainScreen(
                        navController = navController,
                        googleAuthManager = googleAuthManager,
                        pendingShareCode = pendingShareCode.value,
                        onDeepLinkHandled = { pendingShareCode.value = null }
                    )
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleDeepLink(intent)
    }

    private fun handleDeepLink(intent: Intent?) {
        val uri = intent?.data ?: return

        // Handle both schemes:
        // - intervalapp://challenge/{code}
        // - https://interval.jinymus.com/challenge/{code}
        val pathSegments = uri.pathSegments
        val host = uri.host

        when {
            // Custom scheme: intervalapp://challenge/{code}
            uri.scheme == "intervalapp" && host == "challenge" -> {
                val code = pathSegments.firstOrNull()
                if (!code.isNullOrEmpty()) {
                    pendingShareCode.value = code
                }
            }
            // Web URL: http://kjiny.shop/Interval/challenge/?code={code}
            host == "kjiny.shop" && uri.path?.contains("/Interval/challenge") == true -> {
                val code = uri.getQueryParameter("code")
                if (!code.isNullOrEmpty()) {
                    pendingShareCode.value = code
                }
            }
        }
    }

    private fun requestNotificationPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            when {
                ContextCompat.checkSelfPermission(
                    this,
                    Manifest.permission.POST_NOTIFICATIONS
                ) == PackageManager.PERMISSION_GRANTED -> {
                    // Permission already granted
                }
                else -> {
                    requestPermissionLauncher.launch(Manifest.permission.POST_NOTIFICATIONS)
                }
            }
        }
    }
}
