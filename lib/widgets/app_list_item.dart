import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/app_model.dart';
import '../utils/usage_utils.dart';

class AppListItemWithUsage extends StatelessWidget {
  final AppInfoWithUsage app;
  final bool hasUsagePermission;

  const AppListItemWithUsage({
    super.key,
    required this.app,
    required this.hasUsagePermission,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(app.icon, width: 48, height: 48),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    app.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    app.category,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.download, size: 16, color: Colors.green),
                      const SizedBox(width: 4),
                      Text(
                        'Installed: ${DateFormat('dd-MM-yyyy').format(app.installationDate)}',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  if (hasUsagePermission) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 16,
                            color: UsageUtils.getUsageColor(app.usageTime),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Used: ${UsageUtils.formatDuration(app.usageTime)}',
                            style: TextStyle(
                              color: UsageUtils.getUsageColor(
                                app.usageTime,
                              ).withOpacity(0.9),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.history,
                            size: 16,
                            color: Colors.blueGrey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Last Active: ${UsageUtils.formatLastActive(app.lastForeground)}',
                            style: const TextStyle(
                              color: Colors.blueGrey,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
