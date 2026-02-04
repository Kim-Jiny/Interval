package com.jiny.interval.presentation.components

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import com.jiny.interval.presentation.theme.Primary
import com.jiny.interval.presentation.theme.PrimaryDark
import com.jiny.interval.presentation.theme.Secondary
import com.jiny.interval.presentation.theme.SecondaryDark

@Composable
fun BackgroundDecoration(
    modifier: Modifier = Modifier
) {
    val isDark = isSystemInDarkTheme()
    val primary = if (isDark) PrimaryDark else Primary
    val secondary = if (isDark) SecondaryDark else Secondary
    val primaryAlpha = if (isDark) 0.12f else 0.16f
    val secondaryAlpha = if (isDark) 0.10f else 0.14f

    Canvas(modifier = modifier.fillMaxSize()) {
        val width = size.width
        val height = size.height

        // Top-left soft blob
        drawCircle(
            color = primary.copy(alpha = primaryAlpha),
            radius = width * 0.55f,
            center = Offset(x = width * -0.05f, y = height * 0.15f)
        )

        // Bottom-right soft blob
        drawCircle(
            color = secondary.copy(alpha = secondaryAlpha),
            radius = width * 0.65f,
            center = Offset(x = width * 1.05f, y = height * 0.85f)
        )
    }
}
