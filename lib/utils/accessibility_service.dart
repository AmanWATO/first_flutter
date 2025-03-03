import 'package:flutter/services.dart';

class AccessibilityService {
  static const platform = MethodChannel(
    'com.example.stealthguard/accessibility',
  );

  // Check if the accessibility service is enabled
  static Future<bool> isEnabled() async {
    try {
      final bool result = await platform.invokeMethod(
        'isAccessibilityServiceEnabled',
      );
      return result;
    } on PlatformException catch (e) {
      print("Failed to check accessibility service: ${e.message}");
      return false;
    }
  }

  // Open the accessibility settings page
  static Future<void> openSettings() async {
    try {
      await platform.invokeMethod('openAccessibilitySettings');
    } on PlatformException catch (e) {
      print("Failed to open accessibility settings: ${e.message}");
    }
  }
}
