package com.jiny.interval.wear.presentation.theme

import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.wear.compose.material.Colors
import androidx.wear.compose.material.MaterialTheme

val Primary = Color(0xFF4CAF50)
val PrimaryVariant = Color(0xFF388E3C)
val Secondary = Color(0xFF03DAC6)
val Background = Color(0xFF121212)
val Surface = Color(0xFF1E1E1E)
val OnPrimary = Color(0xFFFFFFFF)
val OnSecondary = Color(0xFF000000)
val OnBackground = Color(0xFFE0E0E0)
val OnSurface = Color(0xFFE0E0E0)

val WorkoutColor = Color(0xFF4CAF50)
val RestColor = Color(0xFF2196F3)
val WarmupColor = Color(0xFFFF9800)
val CooldownColor = Color(0xFF9C27B0)

private val WearColorPalette = Colors(
    primary = Primary,
    primaryVariant = PrimaryVariant,
    secondary = Secondary,
    background = Background,
    surface = Surface,
    onPrimary = OnPrimary,
    onSecondary = OnSecondary,
    onBackground = OnBackground,
    onSurface = OnSurface
)

@Composable
fun WearIntervalTheme(
    content: @Composable () -> Unit
) {
    MaterialTheme(
        colors = WearColorPalette,
        content = content
    )
}
