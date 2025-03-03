import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import './stat_tile_widget.dart';
import '../utils/device_utils.dart';

class DeviceStatsPanel extends StatelessWidget {
  final int batteryLevel;
  final String networkStatus;
  final DateTime lastActive;
  final Duration totalUsageToday;

  const DeviceStatsPanel({
    super.key,
    required this.batteryLevel,
    required this.networkStatus,
    required this.lastActive,
    required this.totalUsageToday,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Row(
              children: [
                Icon(
                  Icons.analytics_rounded,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 12),
                Text(
                  'Device Statistics',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Battery level
          StatTileWidget(
            icon: Icons.battery_full,
            iconColor: batteryLevel < 20 ? Colors.red : Colors.green.shade600,
            title: 'Battery Level',
            value: '$batteryLevel%',
            valueColor: batteryLevel < 20 ? Colors.red : Colors.green.shade600,
            progressValue: batteryLevel / 100,
            progressColor:
                batteryLevel < 20 ? Colors.red : Colors.green.shade600,
          ),
          // Network Status
          StatTileWidget(
            icon:
                networkStatus == 'WiFi'
                    ? Icons.wifi
                    : Icons.signal_cellular_alt,
            iconColor:
                networkStatus == 'Offline' ? Colors.red : Colors.blue.shade600,
            title: 'Network Status',
            value: networkStatus,
            valueColor:
                networkStatus == 'Offline' ? Colors.red : Colors.blue.shade600,
            showProgress: false,
          ),
          // Last Active
          StatTileWidget(
            icon: Icons.access_time,
            iconColor: Colors.purple.shade600,
            title: 'Last Active',
            value: DateFormat('MMM dd, HH:mm').format(lastActive),
            valueColor: Colors.purple.shade600,
            showProgress: false,
          ),
          // Total Usage
          StatTileWidget(
            icon: Icons.timer_outlined,
            iconColor:
                totalUsageToday.inMinutes > 120
                    ? Colors.orange.shade700
                    : Colors.green.shade600,
            title: 'Total Usage Today',
            value: DeviceUtils.formatDuration(totalUsageToday),
            valueColor:
                totalUsageToday.inMinutes > 120
                    ? Colors.orange.shade700
                    : Colors.green.shade600,
            progressValue: totalUsageToday.inMinutes / (120 * 2),
            progressColor:
                totalUsageToday.inMinutes > 120
                    ? Colors.orange.shade700
                    : Colors.green.shade600,
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
