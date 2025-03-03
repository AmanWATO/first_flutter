import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';

class DeviceUtils {
  static const MethodChannel _usageChannel = MethodChannel(
    'com.example.stealthguard/usage',
  );

  /// Get battery level as a percentage (0-100)
  static Future<int> getBatteryLevel() async {
    final battery = Battery();
    return await battery.batteryLevel;
  }

  /// Get current network connection status
  static Future<String> getNetworkStatus() async {
    final connectivity = Connectivity();
    final result = await connectivity.checkConnectivity();

    switch (result) {
      case ConnectivityResult.wifi:
        return "WiFi";
      case ConnectivityResult.mobile:
        return "Mobile Data";
      case ConnectivityResult.none:
        return "Offline";
      default:
        return "Unknown";
    }
  }

  /// Get total phone usage today
  static Future<Duration> getTotalUsageToday() async {
    try {
      final int totalUsageMillis = await _usageChannel.invokeMethod(
        'getTotalUsageToday',
      );
      return Duration(milliseconds: totalUsageMillis);
    } catch (e) {
      return Duration.zero;
    }
  }

  /// Get last active time
  static Future<DateTime> getLastActiveTime() async {
    try {
      final int lastActiveMillis = await _usageChannel.invokeMethod(
        'getLastActiveTime',
      );
      return DateTime.fromMillisecondsSinceEpoch(lastActiveMillis);
    } catch (e) {
      return DateTime.now();
    }
  }

  static String formatDuration(Duration duration) {
    int hours = duration.inHours;
    int minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '$hours hr ${minutes} min';
    } else {
      return '$minutes min';
    }
  }
}
