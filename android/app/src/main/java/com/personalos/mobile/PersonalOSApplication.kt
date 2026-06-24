package com.personalos.mobile

import android.app.Application
import com.personalos.mobile.data.auth.AuthSessionStore
import com.personalos.mobile.data.auth.SessionManager
import com.personalos.mobile.data.repository.PersonalOSRepository
import com.personalos.mobile.network.AuthHttpClient
import com.personalos.mobile.network.MobileApiClient
import com.squareup.moshi.Moshi
import com.squareup.moshi.kotlin.reflect.KotlinJsonAdapterFactory

class PersonalOSApplication : Application() {
    val moshi: Moshi by lazy {
        Moshi.Builder()
            .add(KotlinJsonAdapterFactory())
            .build()
    }

    val sessionStore: AuthSessionStore by lazy { AuthSessionStore(this, moshi) }

    val authHttp: AuthHttpClient by lazy { AuthHttpClient(moshi) }

    val sessionManager: SessionManager by lazy {
        SessionManager(sessionStore, authHttp)
    }

    val apiClient: MobileApiClient by lazy {
        MobileApiClient(sessionManager)
    }

    val repository: PersonalOSRepository by lazy {
        PersonalOSRepository(apiClient, moshi)
    }
}
