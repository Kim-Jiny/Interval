package com.jiny.interval.data.remote

import android.content.Context
import android.content.SharedPreferences
import android.util.Log
import com.google.gson.Gson
import com.google.gson.annotations.SerializedName
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.withContext
import java.net.URL
import javax.inject.Inject
import javax.inject.Singleton

private const val TAG = "ConfigManager"
private const val CONFIG_URL = "https://raw.githubusercontent.com/Kim-Jiny/Interval/refs/heads/main/Data/api.json"
private const val PREFS_NAME = "api_config"
private const val KEY_API_BASE_URL = "api_base_url"
private const val KEY_WEB_BASE_URL = "web_base_url"
private const val KEY_AD_MILEAGE = "ad_mileage"
private const val KEY_AD_DAILY_LIMIT = "ad_daily_limit"
private const val KEY_AD_BANNER_ENABLE = "ad_banner_enable"
private const val KEY_AD_REWARD_ENABLE = "ad_reward_enable"

// Default fallback URLs
private const val DEFAULT_API_BASE_URL = "http://kjiny.shop/Interval/api"
private const val DEFAULT_WEB_BASE_URL = "http://kjiny.shop/Interval"

/**
 * Remote config response model
 */
data class AppConfig(
    @SerializedName("api_base_url")
    val apiBaseUrl: String,
    @SerializedName("web_base_url")
    val webBaseUrl: String,
    @SerializedName("ad")
    val ad: AdConfig?
)

data class AdConfig(
    @SerializedName("mileage")
    val mileage: Int = 50,
    @SerializedName("daily_limit")
    val dailyLimit: Int = 7,
    @SerializedName("banner_enable")
    val bannerEnable: Boolean = true,
    @SerializedName("reward_enable")
    val rewardEnable: Boolean = true
)

/**
 * Manages remote configuration from GitHub
 * Fetches and caches API base URL and other config values
 */
@Singleton
class ConfigManager @Inject constructor(
    @ApplicationContext private val context: Context
) {
    private val prefs: SharedPreferences = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    private val gson = Gson()

    // Thread-safe URL storage using volatile
    @Volatile
    private var _apiBaseUrl: String = prefs.getString(KEY_API_BASE_URL, DEFAULT_API_BASE_URL) ?: DEFAULT_API_BASE_URL

    @Volatile
    private var _webBaseUrl: String = prefs.getString(KEY_WEB_BASE_URL, DEFAULT_WEB_BASE_URL) ?: DEFAULT_WEB_BASE_URL

    private val _isLoaded = MutableStateFlow(false)
    val isLoaded: StateFlow<Boolean> = _isLoaded.asStateFlow()

    // Ad config
    private val _adMileage = MutableStateFlow(prefs.getInt(KEY_AD_MILEAGE, 50))
    val adMileage: StateFlow<Int> = _adMileage.asStateFlow()

    private val _adDailyLimit = MutableStateFlow(prefs.getInt(KEY_AD_DAILY_LIMIT, 7))
    val adDailyLimit: StateFlow<Int> = _adDailyLimit.asStateFlow()

    private val _adBannerEnable = MutableStateFlow(prefs.getBoolean(KEY_AD_BANNER_ENABLE, true))
    val adBannerEnable: StateFlow<Boolean> = _adBannerEnable.asStateFlow()

    private val _adRewardEnable = MutableStateFlow(prefs.getBoolean(KEY_AD_REWARD_ENABLE, true))
    val adRewardEnable: StateFlow<Boolean> = _adRewardEnable.asStateFlow()

    /**
     * Get current API base URL (thread-safe)
     */
    val apiBaseUrl: String
        get() = _apiBaseUrl

    /**
     * Get current Web base URL (thread-safe)
     */
    val webBaseUrl: String
        get() = _webBaseUrl

    /**
     * Challenge share URL
     */
    val challengeShareUrl: String
        get() = "$webBaseUrl/challenge/?code="

    /**
     * Routine share URL
     */
    val routineShareUrl: String
        get() = "$webBaseUrl/share/?code="

    init {
        Log.d(TAG, "Initialized with cached URL: $apiBaseUrl")
    }

    /**
     * Load config from GitHub
     * Should be called on app startup
     */
    suspend fun loadConfig() {
        Log.d(TAG, "Loading config from GitHub...")
        fetchConfig()
        logCurrentConfig()
    }

    /**
     * Force refresh config
     */
    suspend fun refreshConfig() {
        fetchConfig()
    }

    private suspend fun fetchConfig() {
        withContext(Dispatchers.IO) {
            try {
                val url = URL(CONFIG_URL)
                val connection = url.openConnection()
                connection.connectTimeout = 10000
                connection.readTimeout = 10000

                val json = connection.getInputStream().bufferedReader().use { it.readText() }
                val config = gson.fromJson(json, AppConfig::class.java)

                // Update URLs
                _apiBaseUrl = config.apiBaseUrl
                _webBaseUrl = config.webBaseUrl

                // Update ad config
                config.ad?.let { ad ->
                    _adMileage.value = ad.mileage
                    _adDailyLimit.value = ad.dailyLimit
                    _adBannerEnable.value = ad.bannerEnable
                    _adRewardEnable.value = ad.rewardEnable
                }

                // Cache to SharedPreferences
                prefs.edit().apply {
                    putString(KEY_API_BASE_URL, config.apiBaseUrl)
                    putString(KEY_WEB_BASE_URL, config.webBaseUrl)
                    config.ad?.let { ad ->
                        putInt(KEY_AD_MILEAGE, ad.mileage)
                        putInt(KEY_AD_DAILY_LIMIT, ad.dailyLimit)
                        putBoolean(KEY_AD_BANNER_ENABLE, ad.bannerEnable)
                        putBoolean(KEY_AD_REWARD_ENABLE, ad.rewardEnable)
                    }
                    apply()
                }

                Log.d(TAG, "Config loaded successfully!")
                Log.d(TAG, "API URL: ${config.apiBaseUrl}")
                Log.d(TAG, "Web URL: ${config.webBaseUrl}")
                config.ad?.let { ad ->
                    Log.d(TAG, "Ad Config - Mileage: ${ad.mileage}, DailyLimit: ${ad.dailyLimit}, Banner: ${ad.bannerEnable}, Reward: ${ad.rewardEnable}")
                }

            } catch (e: Exception) {
                Log.e(TAG, "Failed to fetch config: ${e.message}")
                Log.d(TAG, "Using cached/fallback URL: $apiBaseUrl")
            } finally {
                _isLoaded.value = true
            }
        }
    }

    private fun logCurrentConfig() {
        Log.d(TAG, "========== Current Config ==========")
        Log.d(TAG, "API Base URL: $apiBaseUrl")
        Log.d(TAG, "Web Base URL: $webBaseUrl")
        Log.d(TAG, "Challenge Share URL: $challengeShareUrl")
        Log.d(TAG, "=====================================")
    }

    companion object {
        // For static access before DI is ready (fallback only)
        const val FALLBACK_API_URL = DEFAULT_API_BASE_URL
        const val FALLBACK_WEB_URL = DEFAULT_WEB_BASE_URL
    }
}
