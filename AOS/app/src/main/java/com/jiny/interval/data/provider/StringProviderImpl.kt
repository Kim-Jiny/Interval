package com.jiny.interval.data.provider

import android.content.Context
import com.jiny.interval.R
import com.jiny.interval.domain.provider.StringProvider
import dagger.hilt.android.qualifiers.ApplicationContext
import javax.inject.Inject

class StringProviderImpl @Inject constructor(
    @ApplicationContext private val context: Context
) : StringProvider {

    // Template Names
    override fun templateEmpty(): String = context.getString(R.string.template_empty)
    override fun templateTabata(): String = context.getString(R.string.template_tabata)
    override fun templateRunning(): String = context.getString(R.string.template_running)
    override fun templatePlank(): String = context.getString(R.string.template_plank)
    override fun templateLegRaises(): String = context.getString(R.string.template_leg_raises)
    override fun templateHiit(): String = context.getString(R.string.template_hiit)
    override fun templateStretching(): String = context.getString(R.string.template_stretching)

    // Interval Names
    override fun intervalWorkout(): String = context.getString(R.string.interval_workout)
    override fun intervalWork(): String = context.getString(R.string.interval_work)
    override fun intervalRest(): String = context.getString(R.string.interval_rest)
    override fun intervalWarmup(): String = context.getString(R.string.interval_warmup)
    override fun intervalCooldown(): String = context.getString(R.string.interval_cooldown)
    override fun intervalRun(): String = context.getString(R.string.interval_run)
    override fun intervalWalk(): String = context.getString(R.string.interval_walk)
    override fun intervalPlank(): String = context.getString(R.string.interval_plank)
    override fun intervalLegRaises(): String = context.getString(R.string.interval_leg_raises)
    override fun intervalBurpees(): String = context.getString(R.string.interval_burpees)
    override fun intervalJumpSquats(): String = context.getString(R.string.interval_jump_squats)
    override fun intervalMountainClimbers(): String = context.getString(R.string.interval_mountain_climbers)
    override fun intervalPushUps(): String = context.getString(R.string.interval_push_ups)
    override fun intervalNeckStretch(): String = context.getString(R.string.interval_neck_stretch)
    override fun intervalShoulderStretch(): String = context.getString(R.string.interval_shoulder_stretch)
    override fun intervalArmStretch(): String = context.getString(R.string.interval_arm_stretch)
    override fun intervalBackStretch(): String = context.getString(R.string.interval_back_stretch)
    override fun intervalHipStretch(): String = context.getString(R.string.interval_hip_stretch)
    override fun intervalLegStretch(): String = context.getString(R.string.interval_leg_stretch)
    override fun intervalCalfStretch(): String = context.getString(R.string.interval_calf_stretch)
}
