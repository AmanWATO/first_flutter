import 'package:flutter/material.dart';
import 'package:device_apps/device_apps.dart';
import 'package:app_usage/app_usage.dart';
import 'dart:typed_data';
import 'package:permission_handler/permission_handler.dart';

class AppsScreen extends StatefulWidget {
  const AppsScreen({super.key});

  @override
  _AppsScreenState createState() => _AppsScreenState();
}

class _AppsScreenState extends State<AppsScreen> {
  List<AppInfoWithUsage> _apps = [];
  Map<String, List<AppInfoWithUsage>> _categorizedApps = {};
  Map<String, List<AppInfoWithUsage>> _usageCategorizedApps = {};
  bool _isLoading = true;
  bool _hasUsagePermission = false;
  String _selectedCategory = "All";
  Map<String, AppUsageInfo> _usageInfo = {};

  @override
  void initState() {
    super.initState();
    _checkPermissionAndLoadData();
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
    } catch (e) {
      print('Failed to get usage stats: $e');
    }
  }

  Future<void> _loadApps() async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<Application> installedApps =
          await DeviceApps.getInstalledApplications(
            includeAppIcons: true,
            includeSystemApps: false,
            onlyAppsWithLaunchIntent: true,
          );

      List<AppInfoWithUsage> appInfoList =
          installedApps
              .whereType<ApplicationWithIcon>()
              .map(
                (app) => AppInfoWithUsage(
                  name: app.appName,
                  packageName: app.packageName,
                  icon: app.icon,
                  category: _capitalize(
                    app.category.toString().split('.').last,
                  ),
                  usageTime:
                      _hasUsagePermission
                          ? _usageInfo[app.packageName]?.usage ?? Duration.zero
                          : Duration.zero,
                ),
              )
              .toList();

      appInfoList.sort((a, b) => a.name.compareTo(b.name));

      _categorizedApps = {};

      for (var app in appInfoList) {
        _categorizedApps.putIfAbsent(app.category, () => []).add(app);
      }

      if (_hasUsagePermission) {
        _usageCategorizedApps = {
          'Over Used Apps': [],
          'Used Apps': [],
          'Not Used Recently': [],
        };

        for (var app in appInfoList) {
          if (app.usageTime.inMinutes >= 120) {
            _usageCategorizedApps['Over Used Apps']!.add(app);
          } else if (app.usageTime.inMinutes > 0) {
            _usageCategorizedApps['Used Apps']!.add(app);
          } else {
            _usageCategorizedApps['Not Used Recently']!.add(app);
          }
        }

        _usageCategorizedApps['Over Used Apps']!.sort(
          (a, b) => b.usageTime.compareTo(a.usageTime),
        );
        _usageCategorizedApps['Used Apps']!.sort(
          (a, b) => b.usageTime.compareTo(a.usageTime),
        );
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

  @override
  Widget build(BuildContext context) {
    List<String> categories = [
      "All",
      ...(_categorizedApps.keys.toList()..sort()),
    ];

    return Scaffold(
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
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      width: double.infinity,
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          borderRadius: BorderRadius.circular(4),
                          isExpanded: true,
                          value: _selectedCategory,
                          hint: const Text('Select Category'),
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
                            setState(() {
                              _selectedCategory = newCategory!;
                            });
                          },
                        ),
                      ),
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
                        _selectedCategory == "All" && _hasUsagePermission
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
  }

  Widget _buildUsageCategorizedList() {
    List<Widget> sections = [];

    // Add each usage category as a section with header
    _usageCategorizedApps.forEach((category, apps) {
      if (apps.isNotEmpty) {
        sections.add(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: _getUsageCategoryColor(category).withOpacity(0.1),
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
                  category,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: _getUsageCategoryColor(category),
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
    });

    return sections.isEmpty
        ? const Center(child: Text('No usage data available'))
        : ListView(children: sections);
  }

  Color _getUsageCategoryColor(String category) {
    switch (category) {
      case 'Over Used Apps':
        return Colors.red;
      case 'Used Apps':
        return Colors.blue;
      case 'Not Used Recently':
        return Colors.grey;
      default:
        return Colors.black;
    }
  }

  String _capitalize(String? text) {
    if (text == null || text.isEmpty) return "Unknown";
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }
}

class AppInfoWithUsage {
  final String name;
  final String packageName;
  final Uint8List icon;
  final String category;
  final Duration usageTime;

  AppInfoWithUsage({
    required this.name,
    required this.packageName,
    required this.icon,
    required this.category,
    required this.usageTime,
  });
}

class AppListItemWithUsage extends StatelessWidget {
  final AppInfoWithUsage app;
  final bool hasUsagePermission;

  const AppListItemWithUsage({
    super.key,
    required this.app,
    required this.hasUsagePermission,
  });

  String _formatDuration(Duration duration) {
    int hours = duration.inHours;
    int minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '$hours h:${minutes > 0 ? '$minutes min' : ''}';
    } else if (minutes > 0) {
      return '$minutes min';
    } else {
      return 'Less than 1 min';
    }
  }

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
                  if (hasUsagePermission)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 16,
                            color: _getUsageColor(app.usageTime),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Used: ${_formatDuration(app.usageTime)}',
                            style: TextStyle(
                              color: _getUsageColor(
                                app.usageTime,
                              ).withOpacity(0.9),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getUsageColor(Duration duration) {
    if (duration.inMinutes >= 120) {
      return Colors.red.shade700;
    } else if (duration.inMinutes >= 90) {
      return Colors.deepOrange.shade700;
    } else if (duration.inMinutes >= 60) {
      return Colors.deepOrangeAccent.shade700;
    } else if (duration.inMinutes > 30) {
      return Colors.orange.shade700;
    } else if (duration.inMinutes > 10) {
      return Colors.blue.shade700;
    } else if (duration.inMinutes > 0) {
      return Colors.blue.shade500;
    } else {
      return Colors.grey.shade700;
    }
  }
}
