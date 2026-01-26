package com.jiny.interval.domain.repository

import com.jiny.interval.domain.model.User
import kotlinx.coroutines.flow.Flow

/**
 * Repository interface for authentication operations
 */
interface AuthRepository {

    /**
     * Current login state as Flow
     */
    val isLoggedIn: Flow<Boolean>

    /**
     * Current user as Flow
     */
    val currentUser: Flow<User?>

    /**
     * Social login with provider token
     */
    suspend fun socialLogin(
        provider: String,
        providerToken: String,
        email: String? = null,
        nickname: String? = null
    ): Result<User>

    /**
     * Refresh access token using refresh token
     */
    suspend fun refreshToken(): Result<User>

    /**
     * Logout (clear local tokens)
     */
    suspend fun logout()

    /**
     * Delete account (withdrawal)
     */
    suspend fun deleteAccount(): Result<Unit>

    /**
     * Update nickname
     */
    suspend fun updateNickname(nickname: String): Result<User>

    /**
     * Check if user is currently logged in
     */
    fun isUserLoggedIn(): Boolean

    /**
     * Get current user synchronously
     */
    fun getCurrentUser(): User?
}
