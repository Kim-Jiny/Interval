package com.jiny.interval.presentation.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.height
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.jiny.interval.R

@Composable
fun TimerDisplay(
    timeRemaining: Int,
    modifier: Modifier = Modifier,
    textColor: Color = Color.White
) {
    val minutes = timeRemaining / 60000
    val seconds = (timeRemaining % 60000) / 1000
    val tenths = (timeRemaining % 1000) / 100

    Column(
        modifier = modifier,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Row(
            verticalAlignment = Alignment.Bottom,
            horizontalArrangement = Arrangement.Center
        ) {
            Text(
                text = String.format("%02d:%02d", minutes, seconds),
                style = MaterialTheme.typography.displayLarge.copy(
                    fontSize = 96.sp,
                    fontWeight = FontWeight.Bold
                ),
                color = textColor
            )
            Text(
                text = ".$tenths",
                style = MaterialTheme.typography.displayMedium.copy(
                    fontSize = 48.sp,
                    fontWeight = FontWeight.Normal
                ),
                color = textColor.copy(alpha = 0.7f)
            )
        }
    }
}

@Composable
fun TimerDisplayCompact(
    timeRemaining: Int,
    modifier: Modifier = Modifier,
    textColor: Color = MaterialTheme.colorScheme.onSurface
) {
    val minutes = timeRemaining / 60000
    val seconds = (timeRemaining % 60000) / 1000

    Text(
        text = String.format("%02d:%02d", minutes, seconds),
        style = MaterialTheme.typography.headlineMedium,
        color = textColor,
        modifier = modifier
    )
}

@Composable
fun RoundIndicator(
    currentRound: Int,
    totalRounds: Int,
    modifier: Modifier = Modifier,
    textColor: Color = Color.White
) {
    Column(
        modifier = modifier,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(
            text = stringResource(R.string.round),
            style = MaterialTheme.typography.titleSmall,
            color = textColor.copy(alpha = 0.7f)
        )
        Spacer(modifier = Modifier.height(4.dp))
        Text(
            text = stringResource(R.string.round_format, currentRound, totalRounds),
            style = MaterialTheme.typography.headlineMedium.copy(
                fontWeight = FontWeight.Bold
            ),
            color = textColor
        )
    }
}
