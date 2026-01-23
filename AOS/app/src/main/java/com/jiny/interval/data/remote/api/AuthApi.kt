package com.jiny.interval.data.remote.api

import com.jiny.interval.data.remote.dto.AuthResponse
import com.jiny.interval.data.remote.dto.RefreshTokenRequest
import com.jiny.interval.data.remote.dto.SimpleResponse
import com.jiny.interval.data.remote.dto.SocialLoginRequest
import retrofit2.Response
import retrofit2.http.Body
import retrofit2.http.DELETE
import retrofit2.http.Header
import retrofit2.http.POST

/**
 * Auth API interface for Retrofit
 */
interface AuthApi {

    /**
     * Social login (Google, Apple, Kakao)
     */
    @POST("auth/social.php")
    suspend fun socialLogin(
        @Body request: SocialLoginRequest
    ): Response<AuthResponse>

    /**
     * Refresh access token
     */
    @POST("auth/refresh.php")
    suspend fun refreshToken(
        @Body request: RefreshTokenRequest
    ): Response<AuthResponse>

    /**
     * Delete account (withdrawal)
     */
    @DELETE("auth/delete.php")
    suspend fun deleteAccount(
        @Header("Authorization") token: String
    ): Response<SimpleResponse>
}
