import 'package:flutter/material.dart';
import 'package:device_apps/device_apps.dart';
import 'dart:typed_data';

class AppsScreen extends StatefulWidget {
  const AppsScreen({super.key});

  @override
  _AppsScreenState createState() => _AppsScreenState();
}

class _AppsScreenState extends State<AppsScreen> {
  List<AppInfo> _apps = [];
  Map<String, List<AppInfo>> _categorizedApps = {};
  bool _isLoading = true;
  String _selectedCategory = "All";

  @override
  void initState() {
    super.initState();
    _loadApps();
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
            onlyAppsWithLaunchIntent: false,
          );

      List<AppInfo> appInfoList =
          installedApps
              .whereType<ApplicationWithIcon>()
              .map(
                (app) => AppInfo(
                  name: app.appName,
                  icon: app.icon,
                  category: app.category.toString().split('.').last,
                ),
              )
              .toList();

      appInfoList.sort((a, b) => a.name.compareTo(b.name));

      _categorizedApps = {};
      for (var app in appInfoList) {
        _categorizedApps.putIfAbsent(app.category, () => []).add(app);
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
    List<String> categories = ["All", ..._categorizedApps.keys.toList()];
    List<AppInfo> appsToShow =
        _selectedCategory == "All"
            ? _apps
            : _categorizedApps[_selectedCategory] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Installed Applications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadApps, // Refresh button
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: DropdownButton<String>(
                      value: _selectedCategory,
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
                  Expanded(
                    child: ListView.builder(
                      itemCount: appsToShow.length,
                      itemBuilder: (context, index) {
                        return AppListItem(app: appsToShow[index]);
                      },
                    ),
                  ),
                ],
              ),
    );
  }
}

class AppInfo {
  final String name;
  final Uint8List icon;
  final String category;

  AppInfo({required this.name, required this.icon, required this.category});
}

class AppListItem extends StatelessWidget {
  final AppInfo app;
  const AppListItem({super.key, required this.app});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Image.memory(app.icon, width: 40, height: 40),
      title: Text(
        app.name,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(app.category, style: const TextStyle(color: Colors.grey)),
    );
  }
}
