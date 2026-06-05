import 'package:flutter/material.dart';
import 'package:tcs/widgets/custom_button.dart';

class DeleteConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onDelete;

  const DeleteConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    required this.onDelete,
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
            const Icon(Icons.delete_outline, size: 50, color: Colors.black),

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
                  'Cancel',
                  false,
                ),

                const SizedBox(width: 10),

                cButton(
                  () {
                    Navigator.pop(context);
                    onDelete();
                  },
                  'Delete',
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
