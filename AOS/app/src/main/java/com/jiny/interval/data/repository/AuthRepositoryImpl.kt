package com.jiny.interval.data.repository

import com.jiny.interval.data.remote.TokenManager
import com.jiny.interval.data.remote.api.AuthApi
import com.jiny.interval.data.remote.dto.RefreshTokenRequest
import com.jiny.interval.data.remote.dto.SocialLoginRequest
import com.jiny.interval.data.remote.dto.UpdateNicknameRequest
import com.jiny.interval.domain.model.User
import com.jiny.interval.domain.repository.AuthRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class AuthRepositoryImpl @Inject constructor(
    private val authApi: AuthApi,
    private val tokenManager: TokenManager
) : AuthRepository {

    private val _isLoggedIn = MutableStateFlow(tokenManager.isLoggedIn)
    override val isLoggedIn: Flow<Boolean> = _isLoggedIn.asStateFlow()

    private val _currentUser = MutableStateFlow(loadUserFromStorage())
    override val currentUser: Flow<User?> = _currentUser.asStateFlow()

    override suspend fun socialLogin(
        provider: String,
        providerToken: String,
        email: String?,
        nickname: String?
    ): Result<User> {
        return try {
            val response = authApi.socialLogin(
                SocialLoginRequest(
                    provider = provider,
                    providerToken = providerToken,
                    email = email,
                    nickname = nickname
                )
            )

            if (response.isSuccessful && response.body()?.success == true) {
                val body = response.body()!!
                val userDto = body.user!!

                // Save tokens
                tokenManager.saveTokens(
                    accessToken = body.accessToken!!,
                    refreshToken = body.refreshToken!!
                )

                // Save user info
                tokenManager.saveUser(
                    id = userDto.id,
                    email = userDto.email,
                    nickname = userDto.nickname,
                    profileImage = userDto.profileImage,
                    provider = userDto.provider
                )

                val user = User(
                    id = userDto.id,
                    email = userDto.email,
                    name = userDto.name,
                    nickname = userDto.nickname,
                    profileImage = userDto.profileImage,
                    provider = userDto.provider
                )

                _isLoggedIn.value = true
                _currentUser.value = user

                Result.success(user)
            } else {
                val errorMsg = response.body()?.error ?: "Login failed"
                Result.failure(Exception(errorMsg))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun refreshToken(): Result<User> {
        val refreshToken = tokenManager.refreshToken
            ?: return Result.failure(Exception("No refresh token"))

        return try {
            val response = authApi.refreshToken(
                RefreshTokenRequest(refreshToken = refreshToken)
            )

            if (response.isSuccessful && response.body()?.success == true) {
                val body = response.body()!!
                val userDto = body.user!!

                // Save new tokens
                tokenManager.saveTokens(
                    accessToken = body.accessToken!!,
                    refreshToken = body.refreshToken!!
                )

                // Update user info
                tokenManager.saveUser(
                    id = userDto.id,
                    email = userDto.email,
                    nickname = userDto.nickname,
                    profileImage = userDto.profileImage,
                    provider = null // refresh doesn't return provider
                )

                val user = User(
                    id = userDto.id,
                    email = userDto.email,
                    name = null,
                    nickname = userDto.nickname,
                    profileImage = userDto.profileImage,
                    provider = tokenManager.userProvider
                )

                _currentUser.value = user
                Result.success(user)
            } else {
                // Token invalid, logout
                logout()
                Result.failure(Exception("Token refresh failed"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun logout() {
        tokenManager.clearAll()
        _isLoggedIn.value = false
        _currentUser.value = null
    }

    override suspend fun deleteAccount(): Result<Unit> {
        val authHeader = tokenManager.getAuthHeader()
            ?: return Result.failure(Exception("Not logged in"))

        return try {
            val response = authApi.deleteAccount(authHeader)

            if (response.isSuccessful && response.body()?.success == true) {
                logout()
                Result.success(Unit)
            } else {
                val errorMsg = response.body()?.error ?: "Delete account failed"
                Result.failure(Exception(errorMsg))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun updateNickname(nickname: String): Result<User> {
        val authHeader = tokenManager.getAuthHeader()
            ?: return Result.failure(Exception("Not logged in"))

        return try {
            val response = authApi.updateNickname(
                token = authHeader,
                request = UpdateNicknameRequest(nickname = nickname)
            )

            if (response.isSuccessful && response.body()?.success == true) {
                val body = response.body()!!
                val userDto = body.user!!

                // Update user info in storage
                tokenManager.saveUser(
                    id = userDto.id,
                    email = userDto.email,
                    nickname = userDto.nickname,
                    profileImage = userDto.profileImage,
                    provider = tokenManager.userProvider
                )

                val user = User(
                    id = userDto.id,
                    email = userDto.email,
                    name = userDto.name,
                    nickname = userDto.nickname,
                    profileImage = userDto.profileImage,
                    provider = tokenManager.userProvider
                )

                _currentUser.value = user
                Result.success(user)
            } else {
                val errorMsg = response.body()?.error ?: "Failed to update nickname"
                Result.failure(Exception(errorMsg))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override fun isUserLoggedIn(): Boolean {
        return tokenManager.isLoggedIn
    }

    override fun getCurrentUser(): User? {
        return loadUserFromStorage()
    }

    private fun loadUserFromStorage(): User? {
        if (!tokenManager.isLoggedIn) return null
        val userId = tokenManager.userId
        if (userId == 0) return null

        return User(
            id = userId,
            email = tokenManager.userEmail,
            name = null,
            nickname = tokenManager.userNickname,
            profileImage = tokenManager.userProfileImage,
            provider = tokenManager.userProvider
        )
    }
}
