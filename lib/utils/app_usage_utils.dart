import 'package:app_usage/app_usage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class AppUsageUtils {
  static Future<bool> checkAndRequestPermission() async {
    var status = await Permission.activityRecognition.status;
    if (status.isDenied) {
      status = await Permission.activityRecognition.request();
    }
    return status.isGranted;
  }

  static Future<List<AppUsageInfo>> getAppUsageStats() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day, 0, 0, 0);
      return await AppUsage().getAppUsage(startOfDay, now);
    } catch (e) {
      debugPrint("Error loading app usage: $e");
      return [];
    }
  }

  static Future<List<String>> getBlockedApps() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('blocked_apps') ?? [];
  }

  static Future<void> blockApp(
    String packageName,
    String appName,
    BuildContext context,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> blockedApps = prefs.getStringList('blocked_apps') ?? [];

    if (!blockedApps.contains(packageName)) {
      blockedApps.add(packageName);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$appName has been blocked'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    await prefs.setStringList('blocked_apps', blockedApps);
  }

  static Future<void> unblockApp(String packageName) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> blockedApps = prefs.getStringList('blocked_apps') ?? [];

    blockedApps.remove(packageName);
    await prefs.setStringList('blocked_apps', blockedApps);
  }

  static Future<int> getOverusedThreshold() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('overused_threshold') ?? 120; // Default: 2 hours
  }
}
