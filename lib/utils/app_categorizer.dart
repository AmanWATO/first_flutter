import '../models/app_model.dart';

class AppCategorizer {
  final int overusedThreshold;

  AppCategorizer({required this.overusedThreshold});

  Map<String, List<AppInfoWithUsage>> categorizeByCategory(
    List<AppInfoWithUsage> apps,
  ) {
    Map<String, List<AppInfoWithUsage>> categorizedApps = {};

    for (var app in apps) {
      categorizedApps.putIfAbsent(app.category, () => []).add(app);
    }

    return categorizedApps;
  }

  Map<String, List<AppInfoWithUsage>> categorizeByUsage(
    List<AppInfoWithUsage> apps, {
    String? categoryPrefix,
  }) {
    final String prefix = categoryPrefix != null ? '${categoryPrefix}_' : '';

    Map<String, List<AppInfoWithUsage>> categorizedByUsage = {
      '${prefix}Heavy Usage': [],
      '${prefix}Moderate Usage': [],
      '${prefix}Minimal Usage': [],
    };

    for (var app in apps) {
      if (app.usageTime.inMinutes >= overusedThreshold) {
        categorizedByUsage['${prefix}Heavy Usage']!.add(app);
      } else if (app.usageTime.inMinutes > 0) {
        categorizedByUsage['${prefix}Moderate Usage']!.add(app);
      } else {
        categorizedByUsage['${prefix}Minimal Usage']!.add(app);
      }
    }

    // Sort by usage time (descending)
    categorizedByUsage['${prefix}Heavy Usage']!.sort(
      (a, b) => b.usageTime.compareTo(a.usageTime),
    );
    categorizedByUsage['${prefix}Moderate Usage']!.sort(
      (a, b) => b.usageTime.compareTo(a.usageTime),
    );

    return categorizedByUsage;
  }
}
