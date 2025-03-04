import 'package:device_apps/device_apps.dart';
import 'package:app_usage/app_usage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_model.dart';
import '../utils/usage_utils.dart';

class AppDataLoader {
  Future<bool> checkUsagePermission() async {
    var status = await Permission.activityRecognition.status;
    if (status.isDenied) {
      await Permission.activityRecognition.request();
      status = await Permission.activityRecognition.status;
    }
    return status.isGranted;
  }

  Future<Map<String, AppUsageInfo>> loadUsageStats() async {
    try {
      DateTime now = DateTime.now();
      DateTime startDate = DateTime(
        now.year,
        now.month,
        now.day,
        0,
        0,
        0,
      ); // Today at 00:00
      DateTime endDate = now; // Current time

      List<AppUsageInfo> usageInfoList = await AppUsage().getAppUsage(
        startDate,
        endDate,
      );

      Map<String, AppUsageInfo> usageMap = {};
      for (var info in usageInfoList) {
        usageMap[info.packageName] = info;
      }

      return usageMap;
    } catch (e) {
      return {};
    }
  }

  Future<List<AppInfoWithUsage>> loadApps({
    required bool hasUsagePermission,
    required Map<String, AppUsageInfo> usageInfo,
  }) async {
    try {
      List<Application> installedApps =
          await DeviceApps.getInstalledApplications(
            includeAppIcons: true,
            includeSystemApps: true,
            onlyAppsWithLaunchIntent: true,
          );

      List<AppInfoWithUsage> appInfoList =
          installedApps.whereType<ApplicationWithIcon>().map((app) {
            final appWithIcon = app;
            return AppInfoWithUsage(
              name: appWithIcon.appName,
              packageName: appWithIcon.packageName,
              icon: appWithIcon.icon,
              category: UsageUtils.capitalize(
                appWithIcon.category.toString().split('.').last,
              ),
              usageTime:
                  hasUsagePermission
                      ? usageInfo[appWithIcon.packageName]?.usage ??
                          Duration.zero
                      : Duration.zero,
              lastForeground:
                  hasUsagePermission
                      ? usageInfo[appWithIcon.packageName]?.lastForeground ??
                          DateTime.fromMillisecondsSinceEpoch(0)
                      : DateTime.fromMillisecondsSinceEpoch(0),
              installationDate: DateTime.fromMillisecondsSinceEpoch(
                appWithIcon.installTimeMillis,
              ),
            );
          }).toList();

      appInfoList.sort(
        (a, b) => b.installationDate.compareTo(a.installationDate),
      ); // Sort by recent installs
      return appInfoList;
    } catch (e) {
      return [];
    }
  }

  Future<int> loadThreshold() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('overused_threshold') ?? 120;
  }

  Future<bool> hasSetThreshold() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('has_set_threshold') ?? false;
  }

  Future<void> saveThresholdSettings(int threshold, bool hasSet) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('overused_threshold', threshold);
    await prefs.setBool('has_set_threshold', hasSet);
  }
}
