package com.jiny.interval.domain.provider

interface StringProvider {
    // Template Names
    fun templateEmpty(): String
    fun templateTabata(): String
    fun templateRunning(): String
    fun templatePlank(): String
    fun templateLegRaises(): String
    fun templateHiit(): String
    fun templateStretching(): String

    // Interval Names
    fun intervalWorkout(): String
    fun intervalWork(): String
    fun intervalRest(): String
    fun intervalWarmup(): String
    fun intervalCooldown(): String
    fun intervalRun(): String
    fun intervalWalk(): String
    fun intervalPlank(): String
    fun intervalLegRaises(): String
    fun intervalBurpees(): String
    fun intervalJumpSquats(): String
    fun intervalMountainClimbers(): String
    fun intervalPushUps(): String
    fun intervalNeckStretch(): String
    fun intervalShoulderStretch(): String
    fun intervalArmStretch(): String
    fun intervalBackStretch(): String
    fun intervalHipStretch(): String
    fun intervalLegStretch(): String
    fun intervalCalfStretch(): String
}
