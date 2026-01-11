package com.example.peacekeeper

import androidx.multidex.MultiDexApplication
import android.content.Context

class MyApplication : MultiDexApplication() {
    override fun attachBaseContext(base: Context) {
        super.attachBaseContext(base)
        // MultiDex.install(this) is handled by MultiDexApplication superclass automatically
    }
}
