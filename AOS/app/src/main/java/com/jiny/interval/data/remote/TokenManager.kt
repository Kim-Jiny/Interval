package com.jiny.interval.data.remote

import android.content.Context
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import dagger.hilt.android.qualifiers.ApplicationContext
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Manages authentication tokens securely using EncryptedSharedPreferences
 */
@Singleton
class TokenManager @Inject constructor(
    @ApplicationContext private val context: Context
) {
    private val masterKey = MasterKey.Builder(context)
        .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
        .build()

    private val sharedPreferences = EncryptedSharedPreferences.create(
        context,
        "interval_secure_prefs",
        masterKey,
        EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
        EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
    )

    companion object {
        private const val KEY_ACCESS_TOKEN = "access_token"
        private const val KEY_REFRESH_TOKEN = "refresh_token"
        private const val KEY_USER_ID = "user_id"
        private const val KEY_USER_EMAIL = "user_email"
        private const val KEY_USER_NICKNAME = "user_nickname"
        private const val KEY_USER_PROFILE_IMAGE = "user_profile_image"
        private const val KEY_USER_PROVIDER = "user_provider"
    }

    var accessToken: String?
        get() = sharedPreferences.getString(KEY_ACCESS_TOKEN, null)
        set(value) = sharedPreferences.edit().putString(KEY_ACCESS_TOKEN, value).apply()

    var refreshToken: String?
        get() = sharedPreferences.getString(KEY_REFRESH_TOKEN, null)
        set(value) = sharedPreferences.edit().putString(KEY_REFRESH_TOKEN, value).apply()

    var userId: Int
        get() = sharedPreferences.getInt(KEY_USER_ID, 0)
        set(value) = sharedPreferences.edit().putInt(KEY_USER_ID, value).apply()

    var userEmail: String?
        get() = sharedPreferences.getString(KEY_USER_EMAIL, null)
        set(value) = sharedPreferences.edit().putString(KEY_USER_EMAIL, value).apply()

    var userNickname: String?
        get() = sharedPreferences.getString(KEY_USER_NICKNAME, null)
        set(value) = sharedPreferences.edit().putString(KEY_USER_NICKNAME, value).apply()

    var userProfileImage: String?
        get() = sharedPreferences.getString(KEY_USER_PROFILE_IMAGE, null)
        set(value) = sharedPreferences.edit().putString(KEY_USER_PROFILE_IMAGE, value).apply()

    var userProvider: String?
        get() = sharedPreferences.getString(KEY_USER_PROVIDER, null)
        set(value) = sharedPreferences.edit().putString(KEY_USER_PROVIDER, value).apply()

    val isLoggedIn: Boolean
        get() = !accessToken.isNullOrEmpty() && !refreshToken.isNullOrEmpty()

    fun saveTokens(accessToken: String, refreshToken: String) {
        this.accessToken = accessToken
        this.refreshToken = refreshToken
    }

    fun saveUser(
        id: Int,
        email: String?,
        nickname: String?,
        profileImage: String?,
        provider: String?
    ) {
        userId = id
        userEmail = email
        userNickname = nickname
        userProfileImage = profileImage
        userProvider = provider
    }

    fun clearAll() {
        sharedPreferences.edit().clear().apply()
    }

    fun getAuthHeader(): String? {
        return accessToken?.let { "Bearer $it" }
    }
}
