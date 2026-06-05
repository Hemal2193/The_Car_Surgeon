import 'package:flutter/material.dart';

Widget cButton(void Function() onPressed, String label, bool isPrimary) {
  return InkWell(
    onTap: onPressed,
    child: Container(
      padding: EdgeInsets.symmetric(
        horizontal: isPrimary ? 24 : 18,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        border: Border.all(
          color: isPrimary ? Colors.transparent : Colors.black,
        ),
        color: isPrimary ? Colors.black : Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(color: isPrimary ? Colors.white : Colors.black),
        ),
      ),
    ),
  );
}
