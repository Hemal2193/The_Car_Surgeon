import 'package:flutter/material.dart';
import 'package:tcs/widgets/custom_button.dart';

/// A reusable confirmation dialog with customizable icon, title, message,
/// and confirm/cancel buttons.
///
/// Usage:
/// ```dart
/// final confirmed = await showDialog<bool>(
///   context: context,
///   builder: (_) => ConfirmationDialog(
///     icon: Icons.warning_amber_rounded,
///     title: "Are you sure?",
///     message: "This action cannot be undone.",
///     confirmLabel: "Yes",
///     cancelLabel: "No",
///   ),
/// );
/// ```
class ConfirmationDialog extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;

  const ConfirmationDialog({
    super.key,
    this.icon = Icons.warning_amber_rounded,
    required this.title,
    required this.message,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
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
            Icon(icon, size: 50, color: Colors.black),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                cButton(
                  () {
                    Navigator.pop(context);
                  },
                  cancelLabel,
                  false,
                ),
                const SizedBox(width: 10),
                cButton(
                  () {
                    Navigator.pop(context, true);
                  },
                  confirmLabel,
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