import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class UsageUtils {
  static String formatDuration(Duration duration) {
    int hours = duration.inHours;
    int minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '$hours h${minutes > 0 ? ' $minutes min' : ''}';
    } else if (minutes > 0) {
      return '$minutes min';
    } else {
      return 'Less than 1 min';
    }
  }

  static Color getUsageColor(Duration duration) {
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

  static Color getUsageCategoryColor(String category) {
    if (category.contains('Heavy')) {
      return Colors.red;
    } else if (category.contains('Moderate')) {
      return Colors.blue;
    } else if (category.contains('Minimal')) {
      return Colors.grey;
    } else {
      return Colors.black;
    }
  }

  static String capitalize(String? text) {
    if (text == null || text.isEmpty) return "Unknown";
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  static String formatLastActive(DateTime? lastActive) {
    if (lastActive == null || lastActive.isBefore(DateTime(2000))) {
      return 'Not used recently';
    }

    Duration difference = DateTime.now().difference(lastActive);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d, yyyy - h:mm a').format(lastActive);
    }
  }
}
