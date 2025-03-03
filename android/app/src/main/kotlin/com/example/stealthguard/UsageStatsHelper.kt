package com.example.stealthguard.utils

import android.app.AppOpsManager
import android.app.usage.UsageStatsManager
import android.content.Context
import android.os.Build
import android.provider.Settings
import java.util.Calendar

class UsageStatsHelper(private val context: Context) {

    fun getTotalUsageToday(): Long {
        // 🔍 Check if the app has permission to access usage stats
        if (!hasUsageStatsPermission()) {
            return -1L // 🚨 Return -1 if permission is missing
        }

        val usageStatsManager = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val calendar = Calendar.getInstance()
        val endTime = calendar.timeInMillis
        calendar.set(Calendar.HOUR_OF_DAY, 0)
        calendar.set(Calendar.MINUTE, 0)
        calendar.set(Calendar.SECOND, 0)
        val startTime = calendar.timeInMillis

        val usageStatsList = usageStatsManager.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY, startTime, endTime
        )

        var totalUsageTime = 0L
        for (usageStats in usageStatsList) {
            totalUsageTime += usageStats.totalTimeInForeground
        }

        return totalUsageTime
    }

    // ✅ Check if the app has permission for Usage Stats
    private fun hasUsageStatsPermission(): Boolean {
        val appOps = context.getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = appOps.checkOpNoThrow(
            "android:get_usage_stats",
            android.os.Process.myUid(),
            context.packageName
        )
        return mode == AppOpsManager.MODE_ALLOWED
    }
}
