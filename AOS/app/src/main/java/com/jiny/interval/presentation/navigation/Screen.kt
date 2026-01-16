package com.jiny.interval.presentation.navigation

sealed class Screen(val route: String) {
    data object Home : Screen("home")
    data object Timer : Screen("timer/{routineId}") {
        fun createRoute(routineId: String) = "timer/$routineId"
    }
    data object RoutineEditor : Screen("editor?routineId={routineId}") {
        fun createRoute(routineId: String? = null) =
            if (routineId != null) "editor?routineId=$routineId" else "editor"
    }
    data object TemplateSelection : Screen("templates")
    data object Settings : Screen("settings")
}
