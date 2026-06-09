import 'package:flutter/material.dart';

Widget adderButton({
  required void Function() onPressed,
  required String label,
}) {
  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onPressed,
      mouseCursor: SystemMouseCursors.click,
      borderRadius: BorderRadius.circular(8),
      hoverColor: Colors.white.withValues(alpha: 0.05),
      highlightColor: Colors.white.withValues(alpha: 0.10),
      splashColor: Colors.white.withValues(alpha: 0.08),
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.add, size: 16, color: Colors.white),
              const SizedBox(width: 5),
              Text(label, style: const TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ),
    ),
  );
}
