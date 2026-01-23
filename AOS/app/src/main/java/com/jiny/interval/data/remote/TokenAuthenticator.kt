package com.jiny.interval.data.remote

import android.util.Log
import com.jiny.interval.data.remote.api.AuthApi
import com.jiny.interval.data.remote.dto.RefreshTokenRequest
import kotlinx.coroutines.runBlocking
import okhttp3.Authenticator
import okhttp3.Request
import okhttp3.Response
import okhttp3.Route
import javax.inject.Inject
import javax.inject.Provider
import javax.inject.Singleton

private const val TAG = "TokenAuthenticator"

/**
 * OkHttp Authenticator that automatically refreshes the token when it expires
 */
@Singleton
class TokenAuthenticator @Inject constructor(
    private val tokenManager: TokenManager,
    private val authApiProvider: Provider<AuthApi>
) : Authenticator {

    override fun authenticate(route: Route?, response: Response): Request? {
        Log.d(TAG, "authenticate: Token expired, attempting refresh...")

        // Don't retry if we've already tried to refresh
        if (response.request.header("X-Retry-Auth") != null) {
            Log.e(TAG, "authenticate: Already retried, giving up")
            return null
        }

        val refreshToken = tokenManager.refreshToken
        if (refreshToken.isNullOrEmpty()) {
            Log.e(TAG, "authenticate: No refresh token available")
            return null
        }

        return runBlocking {
            try {
                val authApi = authApiProvider.get()
                val refreshResponse = authApi.refreshToken(RefreshTokenRequest(refreshToken))

                if (refreshResponse.isSuccessful && refreshResponse.body()?.success == true) {
                    val body = refreshResponse.body()!!
                    val newAccessToken = body.accessToken ?: body.access_token
                    val newRefreshToken = body.refreshToken ?: body.refresh_token

                    if (!newAccessToken.isNullOrEmpty()) {
                        Log.d(TAG, "authenticate: Token refreshed successfully")
                        tokenManager.saveTokens(
                            accessToken = newAccessToken,
                            refreshToken = newRefreshToken ?: refreshToken
                        )

                        // Retry the original request with the new token
                        response.request.newBuilder()
                            .header("Authorization", "Bearer $newAccessToken")
                            .header("X-Retry-Auth", "true")
                            .build()
                    } else {
                        Log.e(TAG, "authenticate: Refresh response missing access token")
                        null
                    }
                } else {
                    Log.e(TAG, "authenticate: Refresh failed: ${refreshResponse.errorBody()?.string()}")
                    // Clear tokens on refresh failure
                    tokenManager.clearAll()
                    null
                }
            } catch (e: Exception) {
                Log.e(TAG, "authenticate: Exception during refresh", e)
                null
            }
        }
    }
}
