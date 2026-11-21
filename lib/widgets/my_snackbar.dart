import 'package:flutter/material.dart';
import 'package:tcs/main.dart';

enum SnackbarType { normal, success, error, info }

class MySnackbar {
  static void show({
    required String message,
    String? title,
    SnackbarType type = SnackbarType.normal,
    IconData? icon,
    bool showIcon = true,
    BuildContext? context,
    Duration duration = const Duration(seconds: 4),
  }) {
    // 1. Set up subtle, highly readable text/icon colors based on the type
    Color titleColor = const Color(
      0xFF1A1A1A,
    ); // Normal default dark grey/black
    Color labelColor = const Color(
      0xFF4A4A4A,
    ); // Normal default muted body text
    IconData? defaultIcon;

    switch (type) {
      case SnackbarType.success:
        titleColor = const Color(0xFF1B5E20); // Darker, rich readable green
        labelColor = const Color(0xFF2E7D32); // Distinct, readable green
        defaultIcon = Icons.check_circle_outline;
        break;
      case SnackbarType.error:
        titleColor = const Color(0xFFB71C1C); // Darker, clear crimson red
        labelColor = const Color(0xFFC62828); // Distinct, readable red
        defaultIcon = Icons.error_outline;
        break;
      case SnackbarType.info:
        titleColor = const Color(0xFF0D47A1); // Darker, rich ocean blue
        labelColor = const Color(0xFF1565C0); // Distinct, readable blue
        defaultIcon = Icons.info_outline;
        break;
      case SnackbarType.normal:
        titleColor = const Color(0xFF000000); // Sharp pure black title
        labelColor = const Color(0xFF333333); // High-contrast off-black label
        defaultIcon = Icons.notifications_none;
        break;
    }

    // Allow user override icon if explicitly passed, otherwise use default
    final IconData finalIcon = icon ?? defaultIcon;

    // 2. Build the SnackBar instance
    final snackBar = SnackBar(
      elevation: 6, // Visible, distinct elevation drop shadow
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.white, // Locked to clean white background
      duration: duration,
      dismissDirection:
          DismissDirection.horizontal, // Enables clean swipe-to-dismiss
      // Black border line styling with custom rounded corners
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(
          color: Colors.black45, // Sharp, premium black border
          width: 1.5,
        ),
      ),

      // Desktop vs Mobile layout responsive sizing constraints
      width: context != null && MediaQuery.of(context).size.width > 600
          ? 420
          : null,
      margin: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
      content: Row(
        children: [
          if (showIcon) ...[
            Icon(finalIcon, color: titleColor, size: 24),
            const SizedBox(width: 14),
          ],
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) ...[
                  Text(
                    title,
                    style: TextStyle(
                      color: titleColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
                Text(
                  message,
                  style: TextStyle(
                    color: labelColor,
                    fontSize: 13,
                    fontWeight: title != null
                        ? FontWeight.normal
                        : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    // 3. Clear any active snackbars and show the new one.
    //    Use context-based ScaffoldMessenger when available so the snackbar
    //    is owned by the current route's Scaffold. This prevents the snackbar
    //    from lingering and jumping position when the user pops the route
    //    while a snackbar is still visible.
    if (context != null) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    } else {
      snackbarKey.currentState?.clearSnackBars();
      snackbarKey.currentState?.showSnackBar(snackBar);
    }
  }
}
