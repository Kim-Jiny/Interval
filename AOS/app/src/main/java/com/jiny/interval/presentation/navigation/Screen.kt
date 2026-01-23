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
    data object Login : Screen("login")
    data object Community : Screen("community")
    data object ChallengeDetail : Screen("challenge/{challengeId}") {
        fun createRoute(challengeId: Int) = "challenge/$challengeId"
    }
    data object MileageHistory : Screen("mileage-history")
    data object CreateChallenge : Screen("create-challenge")
    data object ChallengeByCode : Screen("challenge-code/{shareCode}") {
        fun createRoute(shareCode: String) = "challenge-code/$shareCode"
    }
}
