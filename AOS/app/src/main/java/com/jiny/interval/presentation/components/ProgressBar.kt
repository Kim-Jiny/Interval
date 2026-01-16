package com.jiny.interval.presentation.components

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp

@Composable
fun LinearProgressBar(
    progress: Float,
    modifier: Modifier = Modifier,
    backgroundColor: Color = Color.White.copy(alpha = 0.3f),
    progressColor: Color = Color.White
) {
    val animatedProgress by animateFloatAsState(
        targetValue = progress.coerceIn(0f, 1f),
        animationSpec = tween(durationMillis = 100),
        label = "progress"
    )

    Canvas(
        modifier = modifier
            .fillMaxWidth()
            .height(8.dp)
    ) {
        // Background
        drawRoundRect(
            color = backgroundColor,
            cornerRadius = CornerRadius(4.dp.toPx(), 4.dp.toPx())
        )

        // Progress
        drawRoundRect(
            color = progressColor,
            size = Size(size.width * animatedProgress, size.height),
            cornerRadius = CornerRadius(4.dp.toPx(), 4.dp.toPx())
        )
    }
}

@Composable
fun CircularProgressBar(
    progress: Float,
    modifier: Modifier = Modifier,
    backgroundColor: Color = Color.White.copy(alpha = 0.3f),
    progressColor: Color = Color.White,
    strokeWidth: Float = 12f
) {
    val animatedProgress by animateFloatAsState(
        targetValue = progress.coerceIn(0f, 1f),
        animationSpec = tween(durationMillis = 100),
        label = "progress"
    )

    Canvas(modifier = modifier.size(200.dp)) {
        val sweepAngle = 360 * animatedProgress
        val startAngle = -90f

        // Background circle
        drawArc(
            color = backgroundColor,
            startAngle = 0f,
            sweepAngle = 360f,
            useCenter = false,
            style = androidx.compose.ui.graphics.drawscope.Stroke(width = strokeWidth)
        )

        // Progress arc
        drawArc(
            color = progressColor,
            startAngle = startAngle,
            sweepAngle = sweepAngle,
            useCenter = false,
            style = androidx.compose.ui.graphics.drawscope.Stroke(width = strokeWidth)
        )
    }
}

@Composable
fun IntervalDotsIndicator(
    totalIntervals: Int,
    currentIntervalIndex: Int,
    modifier: Modifier = Modifier,
    activeColor: Color = Color.White,
    inactiveColor: Color = Color.White.copy(alpha = 0.3f)
) {
    Row(
        modifier = modifier.padding(horizontal = 16.dp),
        horizontalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        repeat(totalIntervals) { index ->
            Box(
                modifier = Modifier
                    .size(if (index == currentIntervalIndex) 12.dp else 8.dp)
                    .clip(CircleShape)
                    .background(
                        if (index <= currentIntervalIndex) activeColor else inactiveColor
                    )
            )
        }
    }
}

@Composable
fun RoundDotsIndicator(
    totalRounds: Int,
    currentRound: Int,
    modifier: Modifier = Modifier,
    activeColor: Color = Color.White,
    inactiveColor: Color = Color.White.copy(alpha = 0.3f)
) {
    Row(
        modifier = modifier,
        horizontalArrangement = Arrangement.spacedBy(6.dp)
    ) {
        repeat(totalRounds) { index ->
            val roundNumber = index + 1
            Box(
                modifier = Modifier
                    .size(8.dp)
                    .clip(CircleShape)
                    .background(
                        when {
                            roundNumber < currentRound -> activeColor
                            roundNumber == currentRound -> activeColor.copy(alpha = 0.8f)
                            else -> inactiveColor
                        }
                    )
            )
        }
    }
}
