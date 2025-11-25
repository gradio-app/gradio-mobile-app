package com.example.gradio_mobile_app

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.util.Log

class OAuthRedirectActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        Log.d("OAuthRedirect", "Received redirect: ${intent.data}")

        // Forward the intent to MainActivity
        val mainIntent = Intent(this, MainActivity::class.java).apply {
            data = intent.data
            addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        }

        startActivity(mainIntent)
        finish()
    }
}
