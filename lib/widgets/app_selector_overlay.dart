import 'package:flutter/material.dart';

class AppSelectorOverlay {
  static OverlayEntry create({
    required BuildContext context,
    required LayerLink link,
    required List<Widget> children,
    required VoidCallback onClose,
    bool showAbove = false,
  }) {
    return OverlayEntry(
      builder: (context) {
        final int itemCount = children.length;
        final double itemHeight = 48.0;
        final double maxHeight = 220.0;
        final double actualHeight = (itemCount * itemHeight).clamp(
          0,
          maxHeight,
        );
        // When showing above, offset = -(actualHeight + gap)
        final offset = showAbove
            ? Offset(0, -(actualHeight + 4))
            : const Offset(0, 55);

        return Stack(
          children: [
            // ---------------- OUTSIDE TAP DETECTOR ----------------
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  FocusManager.instance.primaryFocus?.unfocus();
                  onClose();
                },
                child: Container(color: Colors.transparent),
              ),
            ),

            // ---------------- DROPDOWN ----------------
            CompositedTransformFollower(
              link: link,
              showWhenUnlinked: false,
              offset: offset,
              child: Material(
                elevation: 10,
                color: Colors.white,
                child: Container(
                  width: 400,
                  constraints: BoxConstraints(maxHeight: actualHeight),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black12),
                  ),
                  child: children.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: Text("No results found"),
                        )
                      : ListView(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          children: children,
                        ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
