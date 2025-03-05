import 'package:flutter/material.dart';
import 'package:app_usage/app_usage.dart';
import 'package:stealthguard/services/accessibility_service.dart';
import 'dart:ui';
import '../models/app_model.dart';
import '../widgets/app_list_item.dart';
import '../widgets/threshold_setting_modal.dart';
import '../widgets/permission_banner.dart';
import '../widgets/usage_category_section.dart';
import '../services/app_data_loader.dart';
import '../utils/app_categorizer.dart';

class AppsScreen extends StatefulWidget {
  const AppsScreen({super.key});

  @override
  _AppsScreenState createState() => _AppsScreenState();
}

class _AppsScreenState extends State<AppsScreen> {
  final AppDataLoader _dataLoader = AppDataLoader();

  List<AppInfoWithUsage> _apps = [];
  Map<String, List<AppInfoWithUsage>> _categorizedApps = {};
  Map<String, List<AppInfoWithUsage>> _usageCategorizedApps = {};
  bool _isLoading = true;
  bool _hasUsagePermission = false;
  String _selectedCategory = "All";
  Map<String, AppUsageInfo> _usageInfo = {};
  int _overusedThreshold = 120;
  bool _hasSetThreshold = false;
  bool _showingThresholdModal = false;

  Set<String> _blockedApps = {};

  late AppCategorizer _appCategorizer;

  @override
  void initState() {
    super.initState();
    _loadThresholdAndCheckPermission();
  }

  Future<void> _loadThresholdAndCheckPermission() async {
    // Load saved threshold from SharedPreferences
    _overusedThreshold = await _dataLoader.loadThreshold();
    _hasSetThreshold = await _dataLoader.hasSetThreshold();
    _appCategorizer = AppCategorizer(overusedThreshold: _overusedThreshold);

    // Check for usage stats permission and load data
    await _checkPermissionAndLoadData();

    // Show threshold setting modal if not set before
    if (!_hasSetThreshold) {
      // Must use a slight delay to ensure context is available
      Future.delayed(Duration.zero, () {
        if (mounted) {
          setState(() {
            _showingThresholdModal = true;
          });
          _showTimerSettingModal();
        }
      });
    }
  }

  Future<void> _checkPermissionAndLoadData() async {
    bool hasPermission = await _dataLoader.checkUsagePermission();

    setState(() {
      _hasUsagePermission = hasPermission;
    });

    if (_hasUsagePermission) {
      _usageInfo = await _dataLoader.loadUsageStats();
    }

    await _loadApps();
  }

  Future<void> _updateBlockedApps() async {
    _blockedApps.clear();

    for (var app in _apps) {
      if (_usageInfo.containsKey(app.packageName) &&
          _usageInfo[app.packageName]!.usage.inMinutes >= _overusedThreshold &&
          app.packageName != "com.example.stealthguard") {
        _blockedApps.add(app.packageName);
      }
    }

    // Save locally in SharedPreferences
    await _dataLoader.saveBlockedApps(_blockedApps.toList());

    // Load again to verify

    // Directly call the native AccessibilityLoggerService to update
    await AccessibilityService.updateBlockedApps(_blockedApps.toList());
  }

  Future<void> _loadApps() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load app data
      _apps = await _dataLoader.loadApps(
        hasUsagePermission: _hasUsagePermission,
        usageInfo: _usageInfo,
      );

      _categorizedApps = _appCategorizer.categorizeByCategory(_apps);

      // Clear the usage categorized apps
      _usageCategorizedApps = {};

      if (_hasUsagePermission) {
        // Categorize all apps by usage
        _usageCategorizedApps.addAll(_appCategorizer.categorizeByUsage(_apps));

        // Also categorize each app category by usage
        _categorizedApps.forEach((category, apps) {
          _usageCategorizedApps.addAll(
            _appCategorizer.categorizeByUsage(apps, categoryPrefix: category),
          );
        });
      }

      await _updateBlockedApps();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showTimerSettingModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return ThresholdSettingModal(
          initialThreshold: _overusedThreshold,
          onSave: _saveThresholdSettings,
        );
      },
    ).then((_) {
      setState(() {
        _showingThresholdModal = false;
      });
    });
  }

  Future<void> _saveThresholdSettings(int threshold, bool hasSet) async {
    await _dataLoader.saveThresholdSettings(threshold, hasSet);

    setState(() {
      _overusedThreshold = threshold;
      _hasSetThreshold = hasSet;
      _appCategorizer = AppCategorizer(overusedThreshold: threshold);
    });

    // Reload apps with new threshold
    if (_hasUsagePermission) {
      // Clear the current categorized apps to ensure fresh categorization
      _usageCategorizedApps.clear();

      // Recategorize all apps with the new threshold
      _usageCategorizedApps.addAll(_appCategorizer.categorizeByUsage(_apps));

      // Also recategorize each app category
      _categorizedApps.forEach((category, apps) {
        _usageCategorizedApps.addAll(
          _appCategorizer.categorizeByUsage(apps, categoryPrefix: category),
        );
      });

      // Update the UI
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    List<String> categories = ["All"];

    // Add the other categories from _categorizedApps
    if (_categorizedApps.isNotEmpty) {
      categories.addAll(
        _categorizedApps.keys.where((c) => c != "All").toList()..sort(),
      );
    }

    Widget mainContent = Scaffold(
      appBar: AppBar(
        title: const Text('App Usage Stats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _checkPermissionAndLoadData,
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  _buildControlsSection(categories),
                  if (!_hasUsagePermission) const PermissionBanner(),
                  Expanded(
                    child:
                        _hasUsagePermission
                            ? _buildUsageCategorizedList()
                            : _buildSimpleAppList(),
                  ),
                ],
              ),
    );

    // If showing the threshold modal, wrap the content with a blur effect
    return _showingThresholdModal
        ? Stack(
          children: [
            mainContent,
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                color: Colors.black.withOpacity(0.3),
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ],
        )
        : mainContent;
  }

  Widget _buildControlsSection(List<String> categories) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Timer setting button
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _showingThresholdModal = true;
                  });
                  _showTimerSettingModal();
                },
                icon: const Icon(Icons.timer_outlined, color: Colors.black),
                label:
                    _hasSetThreshold
                        ? Text(
                          '${_overusedThreshold ~/ 60}h ${_overusedThreshold % 60}m',
                          style: const TextStyle(color: Colors.black),
                        )
                        : const Text(
                          'Set Usage',
                          style: TextStyle(color: Colors.black),
                        ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: Colors.purpleAccent.shade100,
                    width: 1,
                  ),
                  backgroundColor: Colors.transparent,
                ),
              ),
              if (!_hasSetThreshold)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0, left: 8.0),
                  child: Text(
                    'Default: 2 hours',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ),
            ],
          ),
          // Category dropdown
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: Colors.grey.shade300),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                borderRadius: BorderRadius.circular(4),
                value: _selectedCategory,
                hint: const Text('Category'),
                items:
                    categories
                        .map(
                          (category) => DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          ),
                        )
                        .toList(),
                onChanged: (newCategory) {
                  if (newCategory != null) {
                    setState(() {
                      _selectedCategory = newCategory;
                    });
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleAppList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount:
          _selectedCategory == "All"
              ? _apps.length
              : _categorizedApps[_selectedCategory]?.length ?? 0,
      itemBuilder: (context, index) {
        final app =
            _selectedCategory == "All"
                ? _apps[index]
                : _categorizedApps[_selectedCategory]![index];
        return AppListItemWithUsage(
          app: app,
          hasUsagePermission: _hasUsagePermission,
        );
      },
    );
  }

  Widget _buildUsageCategorizedList() {
    List<Widget> sections = [];

    // Get the relevant prefix for the current category
    String prefix = _selectedCategory == "All" ? "" : "${_selectedCategory}_";

    // These are the usage categories we'll be looking for
    List<String> usageCategories = [
      '${prefix}Heavy Usage',
      '${prefix}Moderate Usage',
      '${prefix}Minimal Usage',
    ];

    // For each usage category, check if it exists and has apps
    for (String fullCategoryName in usageCategories) {
      List<AppInfoWithUsage> apps =
          _usageCategorizedApps[fullCategoryName] ?? [];

      if (apps.isNotEmpty) {
        // Extract the display name (without the prefix)
        String displayName = fullCategoryName.replaceFirst('${prefix}', '');

        sections.add(
          UsageCategorySection(
            displayName: displayName,
            apps: apps,
            hasUsagePermission: _hasUsagePermission,
          ),
        );
      }
    }

    return sections.isEmpty
        ? const Center(child: Text('No usage data available for this category'))
        : ListView(children: sections);
  }
}
