import 'package:flutter/material.dart';
import '../screens/apps_screen.dart';

class AppListItem extends StatelessWidget {
  final AppInfo app;

  const AppListItem({super.key, required this.app});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Image.memory(app.icon, width: 40, height: 40),
      title: Text(app.name),
    );
  }
}
