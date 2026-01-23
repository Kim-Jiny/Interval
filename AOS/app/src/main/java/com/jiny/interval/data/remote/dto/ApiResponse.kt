package com.jiny.interval.data.remote.dto

import com.google.gson.annotations.SerializedName

/**
 * Generic API response wrapper
 */
data class ApiResponse<T>(
    @SerializedName("success")
    val success: Boolean,

    @SerializedName("data")
    val data: T? = null,

    @SerializedName("error")
    val error: String? = null,

    @SerializedName("message")
    val message: String? = null
)

/**
 * Simple success/error response
 */
data class SimpleResponse(
    @SerializedName("success")
    val success: Boolean,

    @SerializedName("error")
    val error: String? = null,

    @SerializedName("message")
    val message: String? = null
)
