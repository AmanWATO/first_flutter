import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/user_onboarding_widget.dart';
import '../widgets/device_stats_panel_widget.dart';
import '../widgets/app_usage_panel.dart';
import '../utils/device_utils.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _userName = "";
  final TextEditingController _nameController = TextEditingController();
  bool _isNameEntered = false;

  int _batteryLevel = 0;
  String _networkStatus = "Unknown";
  DateTime _lastActive = DateTime.now();
  Duration _totalUsageToday = Duration.zero;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _updateDeviceStats();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? "";
      _isNameEntered = _userName.isNotEmpty;
      _nameController.text = _userName;
    });
  }

  Future<void> _saveUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
    setState(() {
      _userName = name;
      _isNameEntered = true;
    });
  }

  Future<void> _updateDeviceStats() async {
    final batteryLevel = await DeviceUtils.getBatteryLevel();
    final networkStatus = await DeviceUtils.getNetworkStatus();
    final totalUsageToday = await DeviceUtils.getTotalUsageToday();
    final lastActive = await DeviceUtils.getLastActiveTime();

    setState(() {
      _batteryLevel = batteryLevel;
      _networkStatus = networkStatus;
      _totalUsageToday = totalUsageToday;
      _lastActive = lastActive;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title:
            _isNameEntered
                ? Text(
                  'Hello, $_userName!',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                )
                : const Text(
                  'Stealth Guard',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!_isNameEntered)
                UserOnboardingWidget(
                  nameController: _nameController,
                  onSaveUserName: _saveUserName,
                ),
              DeviceStatsPanel(
                batteryLevel: _batteryLevel,
                networkStatus: _networkStatus,
                lastActive: _lastActive,
                totalUsageToday: _totalUsageToday,
              ),
              AppUsagePanel(),
            ],
          ),
        ),
      ),
    );
  }
}
