package com.example.stealthguard

import android.accessibilityservice.AccessibilityService
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import android.content.Context
import android.util.Log
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class AccessibilityLoggerService : AccessibilityService() {
    
    companion object {
        private const val TAG = "AccessibilityLogger"
    }

    private var lastLoggedUrl: String = ""
    private lateinit var dbHelper: DatabaseHelper
    
    override fun onCreate() {
        super.onCreate()
        dbHelper = DatabaseHelper(applicationContext)
        // Log.d(TAG, "Service created, database initialized")
    }
    
    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return

        if (event.packageName != "com.android.chrome") return
        
        when (event.eventType) {
            AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED, 
            AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED -> {
                val rootNode = rootInActiveWindow ?: return
                
                try {
                    findUrl(rootNode)?.let { url ->
                        if (url != lastLoggedUrl && isValidUrl(url)) {
                            lastLoggedUrl = url
                            
                            val faviconUrl = getFaviconUrl(url)
                            val timestamp = getCurrentTimestamp()

                            Log.d(TAG, "URL Detected: $url")
                            Log.d(TAG, "Favicon: $faviconUrl")
                            Log.d(TAG, "Timestamp: $timestamp")

                            saveHistoryToDatabase(url, faviconUrl, timestamp)
                        }
                    }
                } finally {
                    rootNode.recycle()
                }
            }
        }
    }

    private fun findUrl(node: AccessibilityNodeInfo): String? {
        val urlBars = node.findAccessibilityNodeInfosByViewId("com.android.chrome:id/url_bar")
        if (urlBars.isNotEmpty() && urlBars[0].text != null) {
            return urlBars[0].text.toString()
        }
        
        val omniboxes = node.findAccessibilityNodeInfosByViewId("com.android.chrome:id/omnibox_text_field")
        if (omniboxes.isNotEmpty() && omniboxes[0].text != null) {
            return omniboxes[0].text.toString()
        }
        
        for (i in 0 until node.childCount) {
            val childNode = node.getChild(i) ?: continue
            try {
                findUrl(childNode)?.let { return it }
            } finally {
                childNode.recycle()
            }
        }
        
        return null
    }
    
    private fun isValidUrl(url: String): Boolean {
        return url.contains(".") && 
               (url.startsWith("http") || 
                url.startsWith("www") || 
                !url.contains(" "))
    }

    private fun getFaviconUrl(url: String): String {
        val domain = try {
            if (url.startsWith("http")) {
                url.split("//")[1].split("/")[0]
            } else {
                url.split("/")[0]
            }
        } catch (e: Exception) {
            url
        }
        return "https://www.google.com/s2/favicons?domain=$domain"
    }

    private fun getCurrentTimestamp(): String {
        val sdf = SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.getDefault())
        return sdf.format(Date())
    }

    private fun saveHistoryToDatabase(url: String, favicon: String, timestamp: String) {
        try {
            val id = dbHelper.addHistoryEntry(url, favicon, timestamp)
            Log.d(TAG, "History saved to database with ID: $id")
        } catch (e: Exception) {
            Log.e(TAG, "Error saving to database: ${e.message}", e)
        }
    }

    override fun onInterrupt() {
        Log.d(TAG, "Service Interrupted")
    }
    
    override fun onServiceConnected() {
        super.onServiceConnected()
        Log.d(TAG, "Service Connected")
    }
    
    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "Service Destroyed")
    }
}
