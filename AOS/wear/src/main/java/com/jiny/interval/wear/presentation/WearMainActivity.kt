package com.jiny.interval.wear.presentation

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import com.jiny.interval.wear.presentation.theme.WearIntervalTheme
import dagger.hilt.android.AndroidEntryPoint

@AndroidEntryPoint
class WearMainActivity : ComponentActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        setContent {
            WearIntervalTheme {
                WearNavGraph()
            }
        }
    }
}
