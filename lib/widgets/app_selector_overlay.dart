import 'package:flutter/material.dart';

class AppSelectorOverlay {
  static OverlayEntry create({
    required BuildContext context,
    required LayerLink link,
    required List<Widget> children,
    required VoidCallback onClose,
  }) {
    return OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            // ---------------- OUTSIDE TAP DETECTOR ----------------
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: onClose,
                child: Container(color: Colors.transparent),
              ),
            ),

            // ---------------- DROPDOWN ----------------
            CompositedTransformFollower(
              link: link,
              showWhenUnlinked: false,
              offset: const Offset(0, 55),
              child: Material(
                elevation: 10,
                color: Colors.white,
                child: Container(
                  width: 400,
                  constraints: const BoxConstraints(maxHeight: 220),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black12),
                  ),
                  child: children.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: Text("No results found"),
                        )
                      : ListView(shrinkWrap: true, children: children),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
