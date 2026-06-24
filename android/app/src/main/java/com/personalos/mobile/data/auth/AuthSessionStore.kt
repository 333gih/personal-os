package com.personalos.mobile.data.auth

import android.content.Context
import android.util.Log
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import com.squareup.moshi.Moshi

class AuthSessionStore(context: Context, private val moshi: Moshi) {
    private val appContext = context.applicationContext
    private val adapter = moshi.adapter(StoredAuthSession::class.java)

    @Volatile
    private var prefsInstance: android.content.SharedPreferences? = null
    private val prefsLock = Any()

    private fun prefs(): android.content.SharedPreferences {
        prefsInstance?.let { return it }
        return synchronized(prefsLock) {
            prefsInstance?.let { return it }
            createPrefsOrRecover().also { prefsInstance = it }
        }
    }

    fun save(session: StoredAuthSession) {
        try {
            val json = adapter.toJson(session)
            prefs().edit().putString(KEY_SESSION, json).commit()
        } catch (e: Exception) {
            Log.w(TAG, "save failed — resetting store", e)
            recoverAndReset()
        }
    }

    fun load(): StoredAuthSession? {
        return try {
            val raw = prefs().getString(KEY_SESSION, null) ?: return null
            adapter.fromJson(raw)
        } catch (e: Exception) {
            Log.w(TAG, "load failed — resetting store", e)
            recoverAndReset()
            null
        }
    }

    fun clear() {
        try {
            prefs().edit().clear().commit()
        } catch (e: Exception) {
            recoverAndReset()
        }
    }

    private fun createPrefsOrRecover(): android.content.SharedPreferences {
        return try {
            openEncryptedPrefs()
        } catch (e: Exception) {
            Log.w(TAG, "Keystore invalid — recreating encrypted prefs", e)
            appContext.deleteSharedPreferences(PREFS_NAME)
            openEncryptedPrefs()
        }
    }

    private fun openEncryptedPrefs(): android.content.SharedPreferences {
        val masterKey = MasterKey.Builder(appContext)
            .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
            .build()
        return EncryptedSharedPreferences.create(
            appContext,
            PREFS_NAME,
            masterKey,
            EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
            EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM,
        )
    }

    private fun recoverAndReset() {
        prefsInstance = null
        appContext.deleteSharedPreferences(PREFS_NAME)
    }

    companion object {
        private const val TAG = "AuthSessionStore"
        private const val PREFS_NAME = "com.personalos.mobile.auth"
        private const val KEY_SESSION = "session"
    }
}
