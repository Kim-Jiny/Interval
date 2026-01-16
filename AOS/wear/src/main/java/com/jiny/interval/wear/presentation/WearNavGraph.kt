package com.jiny.interval.wear.presentation

import androidx.compose.runtime.Composable
import androidx.wear.compose.navigation.SwipeDismissableNavHost
import androidx.wear.compose.navigation.composable
import androidx.wear.compose.navigation.rememberSwipeDismissableNavController
import com.jiny.interval.wear.presentation.home.WearHomeScreen
import com.jiny.interval.wear.presentation.timer.WearTimerScreen

sealed class WearScreen(val route: String) {
    data object Home : WearScreen("home")
    data object Timer : WearScreen("timer/{routineIndex}") {
        fun createRoute(routineIndex: Int) = "timer/$routineIndex"
    }
}

@Composable
fun WearNavGraph(startDestination: String = WearScreen.Home.route) {
    val navController = rememberSwipeDismissableNavController()

    SwipeDismissableNavHost(
        navController = navController,
        startDestination = startDestination
    ) {
        composable(WearScreen.Home.route) {
            WearHomeScreen(
                onRoutineClick = { routineIndex ->
                    navController.navigate(WearScreen.Timer.createRoute(routineIndex))
                }
            )
        }

        composable(WearScreen.Timer.route) { backStackEntry ->
            val routineIndex = backStackEntry.arguments?.getString("routineIndex")?.toIntOrNull() ?: 0
            WearTimerScreen(
                routineIndex = routineIndex,
                onNavigateBack = { navController.popBackStack() }
            )
        }
    }
}
