package com.jiny.interval.data.remote.dto

import com.google.gson.annotations.SerializedName

/**
 * User Data Transfer Object
 */
data class UserDto(
    @SerializedName("id")
    val id: Int,

    @SerializedName("email")
    val email: String?,

    @SerializedName("name")
    val name: String?,

    @SerializedName("nickname")
    val nickname: String?,

    @SerializedName("profileImage")
    val profileImage: String?,

    @SerializedName("provider")
    val provider: String?
)
