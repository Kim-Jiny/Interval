package com.jiny.interval.data.remote

import okhttp3.Interceptor
import okhttp3.Response
import javax.inject.Inject
import javax.inject.Singleton

/**
 * OkHttp Interceptor that adds Authorization header to requests
 */
@Singleton
class AuthInterceptor @Inject constructor(
    private val tokenManager: TokenManager
) : Interceptor {

    override fun intercept(chain: Interceptor.Chain): Response {
        val originalRequest = chain.request()

        // Skip auth header for certain endpoints
        val path = originalRequest.url.encodedPath
        if (path.contains("social.php") || path.contains("refresh.php")) {
            return chain.proceed(originalRequest)
        }

        val token = tokenManager.accessToken
        if (token.isNullOrEmpty()) {
            return chain.proceed(originalRequest)
        }

        val authenticatedRequest = originalRequest.newBuilder()
            .header("Authorization", "Bearer $token")
            .build()

        return chain.proceed(authenticatedRequest)
    }
}
