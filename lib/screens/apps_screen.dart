import 'package:flutter/material.dart';
import 'package:device_apps/device_apps.dart';
import 'package:app_usage/app_usage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_model.dart';
import '../widgets/app_list_item.dart';
import '../utils/usage_utils.dart';
import 'dart:ui';

class AppsScreen extends StatefulWidget {
  const AppsScreen({super.key});

  @override
  _AppsScreenState createState() => _AppsScreenState();
}

class _AppsScreenState extends State<AppsScreen> {
  List<AppInfoWithUsage> _apps = [];
  Map<String, List<AppInfoWithUsage>> _categorizedApps = {};
  final Map<String, List<AppInfoWithUsage>> _usageCategorizedApps = {};
  bool _isLoading = true;
  bool _hasUsagePermission = false;
  String _selectedCategory = "All";
  Map<String, AppUsageInfo> _usageInfo = {};
  // Default threshold in minutes (2 hours)
  int _overusedThreshold = 120;
  bool _hasSetThreshold = false;
  bool _showingThresholdModal = false;

  @override
  void initState() {
    super.initState();
    _loadThresholdAndCheckPermission();
  }

  Future<void> _loadThresholdAndCheckPermission() async {
    // Load saved threshold from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    _overusedThreshold = prefs.getInt('overused_threshold') ?? 120;
    _hasSetThreshold = prefs.getBool('has_set_threshold') ?? false;

    // Check for usage stats permission and load data
    await _checkPermissionAndLoadData();

    // Show threshold setting modal if not set before
    // Do this after loading data so we have content to blur
    if (!_hasSetThreshold) {
      // Must use a slight delay to ensure context is available
      Future.delayed(Duration.zero, () {
        if (mounted) {
          setState(() {
            _showingThresholdModal = true;
          });
          _showTimerSettingModal(context);
        }
      });
    }
  }

  Future<void> _checkPermissionAndLoadData() async {
    var status = await Permission.activityRecognition.status;
    if (status.isDenied) {
      await Permission.activityRecognition.request();
      status = await Permission.activityRecognition.status;
    }

    setState(() {
      _hasUsagePermission = status.isGranted;
    });

    if (_hasUsagePermission) {
      await _loadUsageStats();
    }

    await _loadApps();
  }

  Future<void> _loadUsageStats() async {
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

      setState(() {
        _usageInfo = usageMap;
      });
    } catch (e) {}
  }

  Future<void> _loadApps() async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<Application> installedApps =
          await DeviceApps.getInstalledApplications(
            includeAppIcons: true,
            includeSystemApps: true,
            onlyAppsWithLaunchIntent: true,
          );

      List<AppInfoWithUsage> appInfoList =
          installedApps.whereType<ApplicationWithIcon>().map((app) {
            return AppInfoWithUsage(
              name: app.appName,
              packageName: app.packageName,
              icon: app.icon,
              category: UsageUtils.capitalize(
                app.category.toString().split('.').last,
              ),
              usageTime:
                  _hasUsagePermission
                      ? _usageInfo[app.packageName]?.usage ?? Duration.zero
                      : Duration.zero,
              lastForeground:
                  _hasUsagePermission
                      ? _usageInfo[app.packageName]?.lastForeground ??
                          DateTime.fromMillisecondsSinceEpoch(0)
                      : DateTime.fromMillisecondsSinceEpoch(0),
            );
          }).toList();

      appInfoList.sort((a, b) => a.name.compareTo(b.name));

      _categorizedApps = {};

      // Categorize apps by their original categories
      for (var app in appInfoList) {
        _categorizedApps.putIfAbsent(app.category, () => []).add(app);
      }

      if (_hasUsagePermission) {
        // Categorize all apps by usage
        _categorizeAppsByUsage(appInfoList);

        // Also categorize each app category by usage
        _categorizedApps.forEach((category, apps) {
          _categorizeAppsByUsage(apps, categoryPrefix: category);
        });
      }

      setState(() {
        _apps = appInfoList;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _categorizeAppsByUsage(
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
      if (app.usageTime.inMinutes >= _overusedThreshold) {
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

    // Add to or update the main usage categorized apps map
    _usageCategorizedApps.addAll(categorizedByUsage);
  }

  void _showTimerSettingModal(BuildContext context) {
    int tempThreshold = _overusedThreshold;
    int tempHours = tempThreshold ~/ 60;
    int tempMinutes = tempThreshold % 60;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Set Usage Thresholds'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Set the time threshold for categorizing apps as heavily used:',
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 100,
                        child: TextField(
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(labelText: "Hours"),
                          controller: TextEditingController(
                            text: tempHours.toString(),
                          ),
                          onChanged: (value) {
                            setState(() {
                              tempHours = int.tryParse(value) ?? 0;
                              tempThreshold = (tempHours * 60) + tempMinutes;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(":", style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 100,
                        child: TextField(
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(
                            labelText: "Minutes",
                          ),
                          controller: TextEditingController(
                            text: tempMinutes.toString(),
                          ),
                          onChanged: (value) {
                            setState(() {
                              tempMinutes = int.tryParse(value) ?? 0;
                              tempThreshold = (tempHours * 60) + tempMinutes;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Apps used more than this threshold will be marked as "Heavy Usage"',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _showingThresholdModal = false;
                });
              },
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _showingThresholdModal = false;
                });
                _saveThresholdSettings(tempThreshold, true);
              },
              child: const Text('Set Threshold'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveThresholdSettings(int threshold, bool hasSet) async {
    // Save to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('overused_threshold', threshold);
    await prefs.setBool('has_set_threshold', hasSet);

    setState(() {
      _overusedThreshold = threshold;
      _hasSetThreshold = hasSet;
    });

    // Reload apps with new threshold
    if (_hasUsagePermission) {
      // Clear the current categorized apps to ensure fresh categorization
      _usageCategorizedApps.clear();

      // Recategorize all apps with the new threshold
      _categorizeAppsByUsage(_apps);

      // Also recategorize each app category
      _categorizedApps.forEach((category, apps) {
        _categorizeAppsByUsage(apps, categoryPrefix: category);
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
                  Padding(
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
                                _showTimerSettingModal(context);
                              },
                              icon: const Icon(
                                Icons.timer_outlined,
                                color: Colors.black,
                              ),
                              label:
                                  _hasSetThreshold
                                      ? Text(
                                        '${_overusedThreshold ~/ 60}h ${_overusedThreshold % 60}m',
                                        style: const TextStyle(
                                          color: Colors.black,
                                        ),
                                      )
                                      : const Text(
                                        'Set Usage',
                                        style: TextStyle(color: Colors.black),
                                      ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: Colors.purpleAccent.shade100,
                                  width: 1,
                                ), // Border color
                                backgroundColor:
                                    Colors
                                        .transparent, // Transparent background
                              ),
                            ),
                            if (!_hasSetThreshold)
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: 4.0,
                                  left: 8.0,
                                ),
                                child: Text(
                                  'Default: 2 hours',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
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
                  ),
                  !_hasUsagePermission
                      ? Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20.0,
                          vertical: 8.0,
                        ),
                        child: Card(
                          color: Colors.amber.shade100,
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                const Icon(Icons.warning, color: Colors.orange),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    'Usage stats permission not granted. Some features will be limited.',
                                    style: TextStyle(color: Colors.orange),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    await openAppSettings();
                                  },
                                  child: const Text('GRANT'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                      : const SizedBox.shrink(),
                  Expanded(
                    child:
                        _hasUsagePermission
                            ? _buildUsageCategorizedList()
                            : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                              ),
                              itemCount:
                                  _selectedCategory == "All"
                                      ? _apps.length
                                      : _categorizedApps[_selectedCategory]
                                              ?.length ??
                                          0,
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
                            ),
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
          Column(
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
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 20,
                ),
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
                        hasUsagePermission: _hasUsagePermission,
                      ),
                    ),
                  )
                  .toList(),
            ],
          ),
        );
      }
    }

    return sections.isEmpty
        ? const Center(child: Text('No usage data available for this category'))
        : ListView(children: sections);
  }
}
