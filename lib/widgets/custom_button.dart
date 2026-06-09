import 'package:flutter/material.dart';

Widget cButton(void Function() onPressed, String label, bool isPrimary) {
  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onPressed,
      mouseCursor: SystemMouseCursors.click,
      borderRadius: BorderRadius.circular(8),
      hoverColor: Colors.black.withValues(alpha: 0.05),
      highlightColor: Colors.black.withValues(alpha: 0.10),
      splashColor: Colors.black.withValues(alpha: 0.08),
      child: Ink(
        decoration: BoxDecoration(
          border: Border.all(
            color: isPrimary ? Colors.transparent : Colors.black,
          ),
          color: isPrimary ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isPrimary ? 24 : 18,
            vertical: 6,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(color: isPrimary ? Colors.white : Colors.black),
            ),
          ),
        ),
      ),
    ),
  );
}
