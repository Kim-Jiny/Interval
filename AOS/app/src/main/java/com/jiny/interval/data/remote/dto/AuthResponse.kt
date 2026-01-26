package com.jiny.interval.data.remote.dto

import com.google.gson.annotations.SerializedName

/**
 * Response from social login and token refresh APIs
 */
data class AuthResponse(
    @SerializedName("success")
    val success: Boolean?,

    @SerializedName("user")
    val user: UserDto?,

    @SerializedName("accessToken")
    val accessToken: String?,

    @SerializedName("access_token")
    val access_token: String?,

    @SerializedName("refreshToken")
    val refreshToken: String?,

    @SerializedName("refresh_token")
    val refresh_token: String?,

    @SerializedName("error")
    val error: String?
)

/**
 * Request body for social login
 */
data class SocialLoginRequest(
    @SerializedName("provider")
    val provider: String,

    @SerializedName("providerToken")
    val providerToken: String,

    @SerializedName("email")
    val email: String? = null,

    @SerializedName("nickname")
    val nickname: String? = null
)

/**
 * Request body for token refresh
 */
data class RefreshTokenRequest(
    @SerializedName("refresh_token")
    val refreshToken: String
)

/**
 * Request body for nickname update
 */
data class UpdateNicknameRequest(
    @SerializedName("nickname")
    val nickname: String
)
