import 'dart:typed_data';

class AppInfoWithUsage {
  final String name;
  final String packageName;
  final Uint8List icon;
  final String category;
  final Duration usageTime;
  final DateTime lastForeground; // New field for last active time
  final DateTime installationDate;
  bool isBlocked; // New field for blocking apps

  AppInfoWithUsage({
    required this.name,
    required this.packageName,
    required this.icon,
    required this.category,
    required this.usageTime,
    required this.lastForeground, // Make sure it's initialized
    required this.installationDate,
    this.isBlocked = false,
  });
}
