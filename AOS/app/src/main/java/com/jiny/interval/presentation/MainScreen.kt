package com.jiny.interval.presentation

import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.FitnessCenter
import androidx.compose.material.icons.filled.People
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material.icons.outlined.FitnessCenter
import androidx.compose.material.icons.outlined.People
import androidx.compose.material.icons.outlined.Settings
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.res.stringResource
import androidx.navigation.NavDestination.Companion.hierarchy
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.NavHostController
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.navArgument
import com.jiny.interval.R
import com.jiny.interval.data.remote.GoogleAuthManager
import com.jiny.interval.presentation.auth.LoginScreen
import com.jiny.interval.presentation.community.ChallengeDetailScreen
import com.jiny.interval.presentation.community.CommunityScreen
import com.jiny.interval.presentation.community.CreateChallengeScreen
import com.jiny.interval.presentation.community.MileageHistoryScreen
import com.jiny.interval.presentation.editor.RoutineEditorScreen
import com.jiny.interval.presentation.home.HomeScreen
import com.jiny.interval.presentation.navigation.Screen
import com.jiny.interval.presentation.settings.SettingsScreen
import com.jiny.interval.presentation.template.TemplateSelectionScreen
import com.jiny.interval.presentation.timer.TimerScreen

sealed class BottomNavItem(
    val route: String,
    val titleResId: Int,
    val selectedIcon: ImageVector,
    val unselectedIcon: ImageVector
) {
    data object Home : BottomNavItem(
        route = Screen.Home.route,
        titleResId = R.string.nav_home,
        selectedIcon = Icons.Filled.FitnessCenter,
        unselectedIcon = Icons.Outlined.FitnessCenter
    )

    data object Challenge : BottomNavItem(
        route = Screen.Community.route,
        titleResId = R.string.challenge,
        selectedIcon = Icons.Filled.People,
        unselectedIcon = Icons.Outlined.People
    )

    data object Settings : BottomNavItem(
        route = Screen.Settings.route,
        titleResId = R.string.nav_settings,
        selectedIcon = Icons.Filled.Settings,
        unselectedIcon = Icons.Outlined.Settings
    )
}

private val bottomNavItems = listOf(
    BottomNavItem.Home,
    BottomNavItem.Challenge,
    BottomNavItem.Settings
)

// Routes that should show bottom navigation
private val bottomNavRoutes = listOf(
    Screen.Home.route,
    Screen.Community.route,
    Screen.Settings.route
)

@Composable
fun MainScreen(
    navController: NavHostController,
    googleAuthManager: GoogleAuthManager,
    pendingShareCode: String? = null,
    onDeepLinkHandled: () -> Unit = {}
) {
    val navBackStackEntry by navController.currentBackStackEntryAsState()
    val currentDestination = navBackStackEntry?.destination
    val currentRoute = currentDestination?.route

    // Handle deep link navigation
    LaunchedEffect(pendingShareCode) {
        pendingShareCode?.let { code ->
            navController.navigate(Screen.ChallengeByCode.createRoute(code))
            onDeepLinkHandled()
        }
    }

    // Show bottom nav only on main screens
    val showBottomNav = currentRoute in bottomNavRoutes

    Scaffold(
        bottomBar = {
            if (showBottomNav) {
                NavigationBar {
                    bottomNavItems.forEach { item ->
                        val selected = currentDestination?.hierarchy?.any { it.route == item.route } == true

                        NavigationBarItem(
                            icon = {
                                Icon(
                                    imageVector = if (selected) item.selectedIcon else item.unselectedIcon,
                                    contentDescription = stringResource(item.titleResId)
                                )
                            },
                            label = { Text(stringResource(item.titleResId)) },
                            selected = selected,
                            onClick = {
                                navController.navigate(item.route) {
                                    popUpTo(navController.graph.findStartDestination().id) {
                                        saveState = true
                                    }
                                    launchSingleTop = true
                                    restoreState = true
                                }
                            }
                        )
                    }
                }
            }
        }
    ) { paddingValues ->
        NavHost(
            navController = navController,
            startDestination = Screen.Home.route,
            modifier = Modifier.padding(paddingValues)
        ) {
            composable(Screen.Home.route) {
                HomeScreen(
                    onRoutineClick = { routineId ->
                        navController.navigate(Screen.Timer.createRoute(routineId))
                    },
                    onEditRoutine = { routineId ->
                        navController.navigate(Screen.RoutineEditor.createRoute(routineId))
                    },
                    onAddRoutine = {
                        navController.navigate(Screen.TemplateSelection.route)
                    },
                    onSettingsClick = {
                        navController.navigate(Screen.Settings.route)
                    }
                )
            }

            composable(
                route = Screen.Timer.route,
                arguments = listOf(
                    navArgument("routineId") { type = NavType.StringType }
                )
            ) {
                TimerScreen(
                    onNavigateBack = { navController.popBackStack() }
                )
            }

            composable(
                route = Screen.RoutineEditor.route,
                arguments = listOf(
                    navArgument("routineId") {
                        type = NavType.StringType
                        nullable = true
                        defaultValue = null
                    }
                )
            ) {
                RoutineEditorScreen(
                    onNavigateBack = { navController.popBackStack() },
                    onSave = { navController.popBackStack() }
                )
            }

            composable(Screen.TemplateSelection.route) {
                TemplateSelectionScreen(
                    onTemplateSelected = { routine ->
                        navController.popBackStack()
                        navController.navigate(Screen.RoutineEditor.createRoute(routine.id))
                    },
                    onNavigateBack = { navController.popBackStack() }
                )
            }

            composable(Screen.Settings.route) {
                SettingsScreen(
                    onNavigateBack = {
                        navController.navigate(Screen.Home.route) {
                            popUpTo(navController.graph.findStartDestination().id) {
                                saveState = true
                            }
                            launchSingleTop = true
                            restoreState = true
                        }
                    },
                    onNavigateToLogin = {
                        navController.navigate(Screen.Login.route)
                    }
                )
            }

            composable(Screen.Login.route) {
                LoginScreen(
                    onLoginSuccess = { navController.popBackStack() },
                    onSkip = { navController.popBackStack() },
                    googleAuthManager = googleAuthManager
                )
            }

            composable(Screen.Community.route) {
                CommunityScreen(
                    onNavigateToLogin = {
                        navController.navigate(Screen.Login.route)
                    },
                    onNavigateToChallengeDetail = { challengeId ->
                        navController.navigate(Screen.ChallengeDetail.createRoute(challengeId))
                    },
                    onNavigateToCreateChallenge = {
                        navController.navigate(Screen.CreateChallenge.route)
                    },
                    onNavigateToMileageHistory = {
                        navController.navigate(Screen.MileageHistory.route)
                    }
                )
            }

            composable(Screen.CreateChallenge.route) {
                CreateChallengeScreen(
                    onNavigateBack = { navController.popBackStack() },
                    onChallengeCreated = {
                        navController.popBackStack()
                    }
                )
            }

            composable(
                route = Screen.ChallengeDetail.route,
                arguments = listOf(
                    navArgument("challengeId") { type = NavType.IntType }
                )
            ) {
                ChallengeDetailScreen(
                    onNavigateBack = { navController.popBackStack() },
                    onStartWorkout = { routineData ->
                        // TODO: Parse routine data and start workout
                    },
                    onNavigateToLogin = {
                        navController.navigate(Screen.Login.route)
                    }
                )
            }

            composable(Screen.MileageHistory.route) {
                MileageHistoryScreen(
                    onNavigateBack = { navController.popBackStack() }
                )
            }

            // Deep link route - challenge by share code
            composable(
                route = Screen.ChallengeByCode.route,
                arguments = listOf(
                    navArgument("shareCode") { type = NavType.StringType }
                )
            ) {
                ChallengeDetailScreen(
                    onNavigateBack = { navController.popBackStack() },
                    onStartWorkout = { routineData ->
                        // TODO: Parse routine data and start workout
                    },
                    onNavigateToLogin = {
                        navController.navigate(Screen.Login.route)
                    }
                )
            }
        }
    }
}
