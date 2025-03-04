import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionBanner extends StatelessWidget {
  const PermissionBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
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
    );
  }
}
