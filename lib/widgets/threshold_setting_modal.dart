import 'package:flutter/material.dart';

class ThresholdSettingModal extends StatefulWidget {
  final int initialThreshold;
  final Function(int threshold, bool hasSet) onSave;

  const ThresholdSettingModal({
    super.key,
    required this.initialThreshold,
    required this.onSave,
  });

  @override
  State<ThresholdSettingModal> createState() => _ThresholdSettingModalState();
}

class _ThresholdSettingModalState extends State<ThresholdSettingModal> {
  late int tempThreshold;
  late int tempHours;
  late int tempMinutes;
  late TextEditingController hoursController;
  late TextEditingController minutesController;

  @override
  void initState() {
    super.initState();
    tempThreshold = widget.initialThreshold;
    tempHours = tempThreshold ~/ 60;
    tempMinutes = tempThreshold % 60;
    hoursController = TextEditingController(text: tempHours.toString());
    minutesController = TextEditingController(text: tempMinutes.toString());
  }

  @override
  void dispose() {
    hoursController.dispose();
    minutesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Set Usage Thresholds'),
      content: Column(
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
                  controller: hoursController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(labelText: "Hours"),
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
                  controller: minutesController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(labelText: "Minutes"),
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
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            widget.onSave(tempThreshold, true);
          },
          child: const Text('Set Threshold'),
        ),
      ],
    );
  }
}
