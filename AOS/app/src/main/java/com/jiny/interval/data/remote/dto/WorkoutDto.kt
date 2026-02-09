package com.jiny.interval.data.remote.dto

import com.google.gson.JsonElement
import com.google.gson.annotations.SerializedName

data class WorkoutHistoryResponse(
    @SerializedName("success")
    val success: Boolean,
    @SerializedName("year")
    val year: Int? = null,
    @SerializedName("month")
    val month: Int? = null,
    @SerializedName("records")
    val records: List<WorkoutRecordDto>? = null,
    @SerializedName("totalWorkouts")
    val totalWorkouts: Int? = null,
    @SerializedName("workoutDays")
    val workoutDays: Int? = null,
    @SerializedName("error")
    val error: String? = null
)

data class WorkoutRecordDto(
    @SerializedName("id")
    val id: Int,
    @SerializedName("routineName")
    val routineName: String,
    @SerializedName("routineData")
    val routineData: JsonElement? = null,
    @SerializedName("totalDuration")
    val totalDuration: Int,
    @SerializedName("roundsCompleted")
    val roundsCompleted: Int,
    @SerializedName("workoutDate")
    val workoutDate: String,
    @SerializedName("createdAt")
    val createdAt: String? = null
)
