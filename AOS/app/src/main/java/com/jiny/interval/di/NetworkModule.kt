package com.jiny.interval.di

import com.jiny.interval.data.remote.AuthInterceptor
import com.jiny.interval.data.remote.BaseUrlInterceptor
import com.jiny.interval.data.remote.ConfigManager
import com.jiny.interval.data.remote.TokenAuthenticator
import com.jiny.interval.data.remote.api.AuthApi
import com.jiny.interval.data.remote.api.ChallengeApi
import com.jiny.interval.data.remote.api.MileageApi
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory
import java.util.concurrent.TimeUnit
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object NetworkModule {

    // Placeholder URL - actual URL is set by BaseUrlInterceptor
    private const val BASE_URL = "http://placeholder.local/api/"

    @Provides
    @Singleton
    fun provideLoggingInterceptor(): HttpLoggingInterceptor {
        return HttpLoggingInterceptor().apply {
            level = HttpLoggingInterceptor.Level.BODY
        }
    }

    @Provides
    @Singleton
    fun provideOkHttpClient(
        loggingInterceptor: HttpLoggingInterceptor,
        authInterceptor: AuthInterceptor,
        baseUrlInterceptor: BaseUrlInterceptor,
        tokenAuthenticator: TokenAuthenticator
    ): OkHttpClient {
        return OkHttpClient.Builder()
            .addInterceptor(baseUrlInterceptor)  // Dynamic URL interceptor first
            .addInterceptor(authInterceptor)
            .addInterceptor(loggingInterceptor)
            .authenticator(tokenAuthenticator)
            .connectTimeout(30, TimeUnit.SECONDS)
            .readTimeout(30, TimeUnit.SECONDS)
            .writeTimeout(30, TimeUnit.SECONDS)
            .build()
    }

    @Provides
    @Singleton
    fun provideRetrofit(okHttpClient: OkHttpClient): Retrofit {
        return Retrofit.Builder()
            .baseUrl(BASE_URL)
            .client(okHttpClient)
            .addConverterFactory(GsonConverterFactory.create())
            .build()
    }

    @Provides
    @Singleton
    fun provideAuthApi(retrofit: Retrofit): AuthApi {
        return retrofit.create(AuthApi::class.java)
    }

    @Provides
    @Singleton
    fun provideChallengeApi(retrofit: Retrofit): ChallengeApi {
        return retrofit.create(ChallengeApi::class.java)
    }

    @Provides
    @Singleton
    fun provideMileageApi(retrofit: Retrofit): MileageApi {
        return retrofit.create(MileageApi::class.java)
    }
}
