package com.example.stealthguard

import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.stealthguard/accessibility"
    private val USAGE_CHANNEL = "com.example.stealthguard/usage"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Accessibility Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isAccessibilityServiceEnabled" -> {
                    result.success(isAccessibilityServiceEnabled())
                }
                "openAccessibilitySettings" -> {
                    openAccessibilitySettings()
                    result.success(null)
                }
                "updateBlockedApps" -> {
                    val blockedApps = (call.arguments as List<String>).toMutableList()
                    saveBlockedApps(blockedApps)
                    val intent = Intent(this, AccessibilityLoggerService::class.java)
                    intent.action = "UPDATE_BLOCKED_APPS"
                    startService(intent)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        // Usage Stats Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, USAGE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getTotalUsageToday" -> {
                    result.success(getTotalUsageToday())
                }
                "getLastActiveTime" -> {
                    result.success(getLastActiveTime())
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun isAccessibilityServiceEnabled(): Boolean {
        val accessibilityServiceName = "${packageName}/com.example.stealthguard.AccessibilityLoggerService"
        val enabledServices = Settings.Secure.getString(contentResolver, Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES)

        return enabledServices?.contains(accessibilityServiceName) == true
    }

    private fun openAccessibilitySettings() {
        val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
        startActivity(intent)
    }

    private fun getTotalUsageToday(): Long {
        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val now = System.currentTimeMillis()
        val startOfDay = now - (now % (24 * 60 * 60 * 1000))

        val stats = usageStatsManager.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY, startOfDay, now
        )

        val launcherPackage = getDefaultLauncherPackage()
        var totalUsageMillis: Long = 0

        for (usageStat in stats) {
            if (usageStat.packageName != launcherPackage) {
                totalUsageMillis += usageStat.totalTimeInForeground
            }
        }
        return totalUsageMillis
    }

    private fun getDefaultLauncherPackage(): String? {
        val intent = Intent(Intent.ACTION_MAIN)
        intent.addCategory(Intent.CATEGORY_HOME)

        val resolveInfo = packageManager.resolveActivity(intent, 0)
        return resolveInfo?.activityInfo?.packageName
    }

    private fun getLastActiveTime(): Long {
        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val now = System.currentTimeMillis()
        val startOfDay = now - (now % (24 * 60 * 60 * 1000))

        val stats = usageStatsManager.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY, startOfDay, now
        )

        var lastActiveTime: Long = 0
        for (usageStat in stats) {
            if (usageStat.lastTimeUsed > lastActiveTime) {
                lastActiveTime = usageStat.lastTimeUsed
            }
        }
        return lastActiveTime
    }

    private fun saveBlockedApps(blockedApps: List<String>) {
        val sharedPreferences = getSharedPreferences("BlockedAppsPrefs", Context.MODE_PRIVATE)
        sharedPreferences.edit().putStringSet("blocked_apps", blockedApps.toSet()).apply()
    }
}
