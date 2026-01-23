package com.jiny.interval.data.remote

import android.content.Context
import android.util.Log
import androidx.credentials.CredentialManager
import androidx.credentials.CustomCredential
import androidx.credentials.GetCredentialRequest
import androidx.credentials.GetCredentialResponse
import androidx.credentials.exceptions.GetCredentialException
import com.google.android.libraries.identity.googleid.GetGoogleIdOption
import com.google.android.libraries.identity.googleid.GoogleIdTokenCredential
import com.google.android.libraries.identity.googleid.GoogleIdTokenParsingException
import dagger.hilt.android.qualifiers.ApplicationContext
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Manages Google Sign-In using Credential Manager API
 */
@Singleton
class GoogleAuthManager @Inject constructor(
    @ApplicationContext private val context: Context
) {
    companion object {
        private const val TAG = "GoogleAuthManager"
        // Web Client ID from Google Cloud Console
        // TODO: Replace with your actual Web Client ID
        const val WEB_CLIENT_ID = "446636530085-rfrt99lc5jkd8t3or0japvlqjd51ctc7.apps.googleusercontent.com"
    }

    private val credentialManager = CredentialManager.create(context)

    /**
     * Sign in with Google
     * @return Google ID Token on success, null on failure
     */
    suspend fun signIn(activityContext: Context): GoogleSignInResult {
        try {
            val googleIdOption = GetGoogleIdOption.Builder()
                .setFilterByAuthorizedAccounts(false)
                .setServerClientId(WEB_CLIENT_ID)
                .setAutoSelectEnabled(false)
                .build()

            val request = GetCredentialRequest.Builder()
                .addCredentialOption(googleIdOption)
                .build()

            val result = credentialManager.getCredential(
                request = request,
                context = activityContext
            )

            return handleSignInResult(result)
        } catch (e: GetCredentialException) {
            Log.e(TAG, "Google Sign-In failed", e)
            return GoogleSignInResult.Error(e.message ?: "Sign-in failed")
        } catch (e: Exception) {
            Log.e(TAG, "Google Sign-In error", e)
            return GoogleSignInResult.Error(e.message ?: "Unknown error")
        }
    }

    private fun handleSignInResult(result: GetCredentialResponse): GoogleSignInResult {
        val credential = result.credential

        return when (credential) {
            is CustomCredential -> {
                if (credential.type == GoogleIdTokenCredential.TYPE_GOOGLE_ID_TOKEN_CREDENTIAL) {
                    try {
                        val googleIdTokenCredential = GoogleIdTokenCredential.createFrom(credential.data)
                        GoogleSignInResult.Success(
                            idToken = googleIdTokenCredential.idToken,
                            email = googleIdTokenCredential.id,
                            displayName = googleIdTokenCredential.displayName,
                            profileImageUrl = googleIdTokenCredential.profilePictureUri?.toString()
                        )
                    } catch (e: GoogleIdTokenParsingException) {
                        Log.e(TAG, "Failed to parse Google ID token", e)
                        GoogleSignInResult.Error("Failed to parse Google credential")
                    }
                } else {
                    GoogleSignInResult.Error("Unexpected credential type")
                }
            }
            else -> {
                GoogleSignInResult.Error("Unexpected credential type")
            }
        }
    }
}

/**
 * Result of Google Sign-In attempt
 */
sealed class GoogleSignInResult {
    data class Success(
        val idToken: String,
        val email: String?,
        val displayName: String?,
        val profileImageUrl: String?
    ) : GoogleSignInResult()

    data class Error(val message: String) : GoogleSignInResult()

    data object Cancelled : GoogleSignInResult()
}
