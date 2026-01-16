package com.jiny.interval.presentation.navigation

import androidx.compose.runtime.Composable
import androidx.navigation.NavHostController
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.navArgument
import com.jiny.interval.presentation.editor.RoutineEditorScreen
import com.jiny.interval.presentation.home.HomeScreen
import com.jiny.interval.presentation.settings.SettingsScreen
import com.jiny.interval.presentation.template.TemplateSelectionScreen
import com.jiny.interval.presentation.timer.TimerScreen

@Composable
fun NavGraph(
    navController: NavHostController,
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
                onNavigateBack = { navController.popBackStack() }
            )
        }
    }
}
