import 'dart:typed_data';

// lib/models/app_model.dart
class AppInfoWithUsage {
  final String name;
  final String packageName;
  final Uint8List icon;
  final String category;
  final Duration usageTime;
  bool isBlocked; // New field

  AppInfoWithUsage({
    required this.name,
    required this.packageName,
    required this.icon,
    required this.category,
    required this.usageTime,
    this.isBlocked = false,
  });
}
