import 'package:flutter/material.dart';
import '../models/app_model.dart';
import '../widgets/app_list_item.dart';
import '../utils/usage_utils.dart';

class UsageCategorySection extends StatelessWidget {
  final String displayName;
  final List<AppInfoWithUsage> apps;
  final bool hasUsagePermission;

  const UsageCategorySection({
    super.key,
    required this.displayName,
    required this.apps,
    required this.hasUsagePermission,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            color: UsageUtils.getUsageCategoryColor(
              displayName,
            ).withOpacity(0.1),
          ),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          margin: const EdgeInsets.only(
            top: 12,
            bottom: 10,
            right: 20,
            left: 20,
          ),
          child: Text(
            displayName,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: UsageUtils.getUsageCategoryColor(displayName),
            ),
          ),
        ),
        ...apps
            .map(
              (app) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: AppListItemWithUsage(
                  app: app,
                  hasUsagePermission: hasUsagePermission,
                ),
              ),
            )
            .toList(),
      ],
    );
  }
}
