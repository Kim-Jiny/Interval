package com.jiny.interval.data.remote

import okhttp3.HttpUrl.Companion.toHttpUrlOrNull
import okhttp3.Interceptor
import okhttp3.Response
import javax.inject.Inject
import javax.inject.Singleton

/**
 * OkHttp Interceptor that dynamically replaces the base URL
 * with the current URL from ConfigManager
 */
@Singleton
class BaseUrlInterceptor @Inject constructor(
    private val configManager: ConfigManager
) : Interceptor {

    companion object {
        // The placeholder path prefix used in Retrofit BASE_URL
        private const val PLACEHOLDER_PATH_PREFIX = "/api/"
    }

    override fun intercept(chain: Interceptor.Chain): Response {
        val originalRequest = chain.request()
        val originalUrl = originalRequest.url

        // Get current base URL from ConfigManager (e.g., "http://kjiny.shop/Interval/api")
        val newBaseUrl = configManager.apiBaseUrl.toHttpUrlOrNull()

        if (newBaseUrl != null) {
            // Get the original path (e.g., "/api/auth/social.php")
            val originalPath = originalUrl.encodedPath

            // Extract the relative path after "/api/" (e.g., "auth/social.php")
            val relativePath = if (originalPath.startsWith(PLACEHOLDER_PATH_PREFIX)) {
                originalPath.removePrefix(PLACEHOLDER_PATH_PREFIX)
            } else {
                originalPath.removePrefix("/")
            }

            // Build new path by combining base URL path with relative path
            // newBaseUrl.encodedPath = "/Interval/api"
            // relativePath = "auth/social.php"
            // result = "/Interval/api/auth/social.php"
            val basePath = newBaseUrl.encodedPath.trimEnd('/')
            val newPath = if (relativePath.isNotEmpty()) {
                "$basePath/$relativePath"
            } else {
                basePath
            }

            // Build new URL with the dynamic base and combined path
            val newUrl = originalUrl.newBuilder()
                .scheme(newBaseUrl.scheme)
                .host(newBaseUrl.host)
                .port(newBaseUrl.port)
                .encodedPath(newPath)
                .build()

            val newRequest = originalRequest.newBuilder()
                .url(newUrl)
                .build()

            return chain.proceed(newRequest)
        }

        return chain.proceed(originalRequest)
    }
}
