import 'package:flutter/material.dart';
import 'package:tcs/widgets/custom_button.dart';

class LogoutConfirmationDialog extends StatelessWidget {
  final VoidCallback onLogout;

  const LogoutConfirmationDialog({
    super.key,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 450,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.logout, size: 50, color: Colors.black),

            const SizedBox(height: 16),

            const Text(
              'Logout',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            const Text(
              'Are you sure you want to logout?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),

            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                cButton(
                  () {
                    Navigator.pop(context);
                  },
                  'Cancel',
                  false,
                ),

                const SizedBox(width: 10),

                cButton(
                  () {
                    Navigator.pop(context);
                    onLogout();
                  },
                  'Logout',
                  true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}