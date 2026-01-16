package com.jiny.interval.util

import android.content.Context
import android.media.AudioAttributes
import android.media.SoundPool
import android.speech.tts.TextToSpeech
import dagger.hilt.android.qualifiers.ApplicationContext
import java.util.Locale
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class SoundManager @Inject constructor(
    @ApplicationContext private val context: Context
) {
    private var soundPool: SoundPool? = null
    private var textToSpeech: TextToSpeech? = null
    private var isTtsReady = false

    private var beepSoundId: Int = 0
    private var endSoundId: Int = 0

    init {
        initializeSoundPool()
        initializeTts()
    }

    private fun initializeSoundPool() {
        val audioAttributes = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_GAME)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()

        soundPool = SoundPool.Builder()
            .setMaxStreams(2)
            .setAudioAttributes(audioAttributes)
            .build()

        // Load sounds from resources if available
        // For now, we'll use system sounds through TTS
    }

    private fun initializeTts() {
        textToSpeech = TextToSpeech(context) { status ->
            if (status == TextToSpeech.SUCCESS) {
                textToSpeech?.language = Locale.US
                isTtsReady = true
            }
        }
    }

    fun playBeep() {
        if (beepSoundId != 0) {
            soundPool?.play(beepSoundId, 1f, 1f, 1, 0, 1f)
        }
    }

    fun playEndSound() {
        if (endSoundId != 0) {
            soundPool?.play(endSoundId, 1f, 1f, 1, 0, 1f)
        }
    }

    fun speak(text: String) {
        if (isTtsReady) {
            textToSpeech?.speak(text, TextToSpeech.QUEUE_FLUSH, null, "interval_speech")
        }
    }

    fun announceInterval(intervalName: String) {
        speak(intervalName)
    }

    fun announceRound(currentRound: Int, totalRounds: Int) {
        speak("Round $currentRound of $totalRounds")
    }

    fun announceCountdown(seconds: Int) {
        if (seconds in 1..3) {
            speak(seconds.toString())
        }
    }

    fun announceWorkoutComplete() {
        speak("Workout complete. Great job!")
    }

    fun release() {
        soundPool?.release()
        soundPool = null

        textToSpeech?.stop()
        textToSpeech?.shutdown()
        textToSpeech = null
    }
}
