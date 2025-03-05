import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'screens/home_screen.dart';
import 'screens/apps_screen.dart';
import 'screens/history_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stealth Guard',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.purpleAccent),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // Now includes HistoryScreen
  static final List<Widget> _screens = [
    const HomeScreen(),
    const AppsScreen(),
    const HistoryScreen(), // Added History Tab
  ];

  @override
  void initState() {
    super.initState();
    _requestSystemAlertPermission();
  }

  Future<void> _requestSystemAlertPermission() async {
    final status = await Permission.systemAlertWindow.request();

    if (status.isPermanentlyDenied) {
      // If denied permanently, open app settings
      openAppSettings();
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.apps), label: "Apps"),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: "History",
          ), // New Tab
        ],
      ),
    );
  }
}
