package com.example.stealthguard

import android.accessibilityservice.AccessibilityService
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import android.widget.Toast
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.content.Context
import android.content.Intent
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class AccessibilityLoggerService : AccessibilityService() {

    companion object {
        private const val TAG = "AccessibilityService"
        private const val PREFS_NAME = "BlockedAppsPrefs"
        private const val BLOCKED_APPS_KEY = "blocked_apps"

        var blockedApps: MutableList<String> = mutableListOf()
    }

    private lateinit var dbHelper: DatabaseHelper
    private var lastLoggedUrl: String = ""

    override fun onCreate() {
        super.onCreate()
        dbHelper = DatabaseHelper(applicationContext)
        loadBlockedApps()
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return

        val packageName = event.packageName?.toString() ?: return

        // **1️⃣ App Blocking Logic**
        if (blockedApps.contains(packageName)) {
            blockApp(packageName)
            return
        }

        // **2️⃣ Chrome URL Logging Logic**
        if (packageName == "com.android.chrome") {
            logChromeHistory(event)
        }
    }

    // **🚫 Block App & Send to Home Screen**
    private fun blockApp(packageName: String) {
        Log.d(TAG, "🚨 Attempting to block: $packageName")

        // Show Toast on Main Thread
        Handler(Looper.getMainLooper()).post {
            Toast.makeText(this, "This app is blocked!", Toast.LENGTH_SHORT).show()
        }

        // Simulate Home Button (Works for most cases)
        performGlobalAction(GLOBAL_ACTION_HOME)

        // Kill Background Process (Works for most non-system apps)
        try {
            val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as android.app.ActivityManager
            activityManager.killBackgroundProcesses(packageName)
            Log.d(TAG, "🚫 App Force Stopped: $packageName")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error stopping app: ${e.message}")
        }
    }

    // **🔗 Extract & Log Chrome URLs**
    private fun logChromeHistory(event: AccessibilityEvent) {
        if (event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED &&
            event.eventType != AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED
        ) return

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

    private fun findUrl(node: AccessibilityNodeInfo): String? {
        val urlBars = node.findAccessibilityNodeInfosByViewId("com.android.chrome:id/url_bar")
        if (urlBars.isNotEmpty() && urlBars[0].text != null) return urlBars[0].text.toString()

        val omniboxes = node.findAccessibilityNodeInfosByViewId("com.android.chrome:id/omnibox_text_field")
        if (omniboxes.isNotEmpty() && omniboxes[0].text != null) return omniboxes[0].text.toString()

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
        return url.contains(".") && (url.startsWith("http") || url.startsWith("www") || !url.contains(" "))
    }

    private fun getFaviconUrl(url: String): String {
        val domain = try {
            if (url.startsWith("http")) url.split("//")[1].split("/")[0] else url.split("/")[0]
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
        loadBlockedApps()
    }

    // **📌 Load Blocked Apps from SharedPreferences**
    private fun loadBlockedApps() {
        val sharedPreferences = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        blockedApps = sharedPreferences.getStringSet(BLOCKED_APPS_KEY, emptySet())?.toMutableList() ?: mutableListOf()
        Log.d(TAG, "🔄 Blocked Apps Loaded: $blockedApps")
    }

    // **📌 Update Blocked Apps (Called from MainActivity)**
    fun updateBlockedApps(newBlockedApps: List<String>) {
        blockedApps.clear()
        blockedApps.addAll(newBlockedApps)
        saveBlockedApps()
        
        // Force reload to ensure updated list is active
        loadBlockedApps()
    }

    // **📌 Save Blocked Apps to SharedPreferences**
    private fun saveBlockedApps() {
        val sharedPreferences = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        sharedPreferences.edit().putStringSet(BLOCKED_APPS_KEY, blockedApps.toSet()).apply()
        Log.d(TAG, "✅ Blocked Apps Saved: $blockedApps")
    }

    // **Handle External Updates (from MainActivity)**
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == "UPDATE_BLOCKED_APPS") {
            Log.d(TAG, "🔄 Received Update Blocked Apps Intent")
            loadBlockedApps()  // Reload blocked apps from SharedPreferences
        }
        return super.onStartCommand(intent, flags, startId)
    }
}
