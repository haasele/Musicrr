package com.haasele.musicrr.webserver

import android.content.Context
import android.content.SharedPreferences
import android.util.Log
import java.security.SecureRandom
import java.util.*

class TokenManager(private val context: Context) {
    
    companion object {
        private const val TAG = "TokenManager"
        private const val PREFS_NAME = "musicrr_remote_control"
        private const val KEY_PAIRING_TOKEN = "pairing_token"
        private const val KEY_ACCESS_TOKENS = "access_tokens"
        private const val PAIRING_TOKEN_LENGTH = 8
        private const val ACCESS_TOKEN_LENGTH = 32
        private const val PAIRING_TOKEN_EXPIRY_HOURS = 24
    }
    
    private val prefs: SharedPreferences = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    private val random = SecureRandom()
    
    /**
     * Generate a new pairing token
     */
    fun generatePairingToken(): String {
        val token = generateRandomToken(PAIRING_TOKEN_LENGTH)
        val expiryTime = System.currentTimeMillis() + (PAIRING_TOKEN_EXPIRY_HOURS * 60 * 60 * 1000)
        
        prefs.edit()
            .putString(KEY_PAIRING_TOKEN, token)
            .putLong("${KEY_PAIRING_TOKEN}_expiry", expiryTime)
            .apply()
        
        Log.d(TAG, "Generated pairing token: $token")
        return token
    }
    
    /**
     * Get current pairing token, generating one if it doesn't exist or is expired
     */
    fun getPairingToken(): String {
        val token = prefs.getString(KEY_PAIRING_TOKEN, null)
        val expiryTime = prefs.getLong("${KEY_PAIRING_TOKEN}_expiry", 0)
        
        if (token == null || System.currentTimeMillis() > expiryTime) {
            return generatePairingToken()
        }
        
        return token
    }
    
    /**
     * Regenerate pairing token
     */
    fun regeneratePairingToken(): String {
        return generatePairingToken()
    }
    
    /**
     * Validate pairing token and generate access token
     */
    fun validatePairingToken(pairingToken: String): String? {
        val storedToken = getPairingToken()
        
        if (storedToken == null || storedToken != pairingToken) {
            Log.w(TAG, "Invalid pairing token")
            return null
        }
        
        // Generate access token
        val accessToken = generateRandomToken(ACCESS_TOKEN_LENGTH)
        val tokens = getAccessTokens().toMutableSet()
        tokens.add(accessToken)
        saveAccessTokens(tokens)
        
        // Invalidate pairing token after first use
        prefs.edit()
            .remove(KEY_PAIRING_TOKEN)
            .remove("${KEY_PAIRING_TOKEN}_expiry")
            .apply()
        
        Log.d(TAG, "Generated access token from pairing token")
        return accessToken
    }
    
    /**
     * Validate access token
     */
    fun validateAccessToken(token: String): Boolean {
        val tokens = getAccessTokens()
        return tokens.contains(token)
    }
    
    /**
     * Revoke all tokens (force re-pairing)
     */
    fun revokeAllTokens() {
        prefs.edit()
            .remove(KEY_PAIRING_TOKEN)
            .remove("${KEY_PAIRING_TOKEN}_expiry")
            .remove(KEY_ACCESS_TOKENS)
            .apply()
        Log.d(TAG, "All tokens revoked")
    }
    
    private fun generateRandomToken(length: Int): String {
        val chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return (1..length)
            .map { chars[random.nextInt(chars.length)] }
            .joinToString("")
    }
    
    private fun getAccessTokens(): Set<String> {
        val tokensString = prefs.getString(KEY_ACCESS_TOKENS, null)
        return if (tokensString != null) {
            tokensString.split(",").toSet()
        } else {
            emptySet()
        }
    }
    
    private fun saveAccessTokens(tokens: Set<String>) {
        prefs.edit()
            .putString(KEY_ACCESS_TOKENS, tokens.joinToString(","))
            .apply()
    }
}
