package com.jiny.interval.domain.model

/**
 * Domain model for User
 */
data class User(
    val id: Int,
    val email: String?,
    val name: String?,
    val nickname: String?,
    val profileImage: String?,
    val provider: String?
) {
    val displayName: String
        get() = nickname ?: name ?: "User"

    val initial: String
        get() = displayName.firstOrNull()?.uppercase() ?: "?"
}

/**
 * Authentication provider types
 */
enum class AuthProvider(val value: String) {
    GOOGLE("google"),
    APPLE("apple"),
    KAKAO("kakao");

    companion object {
        fun fromValue(value: String?): AuthProvider? {
            return entries.find { it.value == value }
        }
    }
}
