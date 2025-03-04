import 'package:flutter/material.dart';
import 'package:app_usage/app_usage.dart';
import 'package:device_apps/device_apps.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:typed_data';

class AppUsagePanel extends StatefulWidget {
  const AppUsagePanel({super.key});

  @override
  State<AppUsagePanel> createState() => _AppUsagePanelState();
}

class _AppUsagePanelState extends State<AppUsagePanel> {
  List<Map<String, dynamic>> _topApps = [];
  int _overusedThreshold = 120; // Default to 120 minutes

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _fetchAppUsage();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _overusedThreshold = prefs.getInt('overused_threshold') ?? 120;
    });
  }

  Future<void> _fetchAppUsage() async {
    try {
      DateTime now = DateTime.now();
      DateTime startOfDay = DateTime(now.year, now.month, now.day);
      List<AppUsageInfo> usage = await AppUsage().getAppUsage(startOfDay, now);

      List<Application> installedApps =
          await DeviceApps.getInstalledApplications(
            includeAppIcons: true,
            includeSystemApps: true,
            onlyAppsWithLaunchIntent: true,
          );

      List<Map<String, dynamic>> appList = [];

      for (var app in installedApps) {
        var appUsageInfo = usage.firstWhere(
          (info) => info.packageName == app.packageName,
          orElse:
              () => AppUsageInfo(
                app.packageName,
                0.0,
                DateTime.now(),
                DateTime.now(),
                DateTime.now(),
              ),
        );

        Duration usageTime = Duration(
          milliseconds: appUsageInfo.usage.inMilliseconds,
        );

        Uint8List? iconBytes;
        if (app is ApplicationWithIcon) {
          iconBytes = app.icon;
        }

        appList.add({
          'name': app.appName,
          'icon': iconBytes,
          'usage': usageTime,
          'isBlocked': usageTime.inMinutes > _overusedThreshold,
        });
      }

      appList.sort((a, b) => b['usage'].compareTo(a['usage']));

      setState(() {
        _topApps = appList.take(6).toList();
      });
    } catch (e) {
      print("Error fetching app usage: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade700, Colors.blue.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'App Usage',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,

            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.7, // **Increased height for each grid card**
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _topApps.length,
            itemBuilder: (context, index) {
              var app = _topApps[index];
              return Container(
                padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
                decoration: BoxDecoration(
                  color: Colors.white24.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    app['icon'] != null
                        ? Image.memory(
                          app['icon'],
                          width: 35,
                          height: 35,
                          fit: BoxFit.contain,
                        )
                        : const Icon(Icons.apps, size: 50, color: Colors.grey),
                    const SizedBox(height: 8),
                    Text(
                      app['name'],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: app['isBlocked'] ? Colors.red : Colors.black,
                        height: 1.0,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textWidthBasis: TextWidthBasis.parent,
                    ),

                    const SizedBox(height: 2),
                    Text(
                      app['usage'].inHours > 0
                          ? "${app['usage'].inHours}hr : ${app['usage'].inMinutes % 60}min"
                          : "${app['usage'].inMinutes} min",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color:
                            app['isBlocked']
                                ? Colors.red
                                : Colors.blue.shade800,
                      ),
                    ),
                    if (app['isBlocked'])
                      Container(
                        margin: const EdgeInsets.only(top: 10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: const Text(
                          'Blocked',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
