import 'package:flutter/material.dart';

class StatTileWidget extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final Color valueColor;
  final bool showProgress;
  final double progressValue;
  final Color? progressColor;

  const StatTileWidget({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.valueColor,
    this.showProgress = true,
    this.progressValue = 0.0,
    this.progressColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: valueColor,
                ),
              ),
            ],
          ),
          if (showProgress) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progressValue.clamp(0.0, 1.0),
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                progressColor ?? Colors.blue,
              ),
              minHeight: 5,
              borderRadius: BorderRadius.circular(2.5),
            ),
          ],
        ],
      ),
    );
  }
}
