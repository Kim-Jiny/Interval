package com.jiny.interval.presentation.navigation

import androidx.compose.runtime.Composable
import androidx.navigation.NavHostController
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.navArgument
import com.jiny.interval.data.remote.GoogleAuthManager
import com.jiny.interval.presentation.auth.LoginScreen
import com.jiny.interval.presentation.community.ChallengeDetailScreen
import com.jiny.interval.presentation.community.CommunityScreen
import com.jiny.interval.presentation.community.CreateChallengeScreen
import com.jiny.interval.presentation.community.MileageHistoryScreen
import com.jiny.interval.presentation.editor.RoutineEditorScreen
import com.jiny.interval.presentation.home.HomeScreen
import com.jiny.interval.presentation.settings.SettingsScreen
import com.jiny.interval.presentation.template.TemplateSelectionScreen
import com.jiny.interval.presentation.timer.TimerScreen

@Composable
fun NavGraph(
    navController: NavHostController,
    googleAuthManager: GoogleAuthManager,
    startDestination: String = Screen.Home.route
) {
    NavHost(
        navController = navController,
        startDestination = startDestination
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
                onNavigateBack = { navController.popBackStack() },
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
    }
}
