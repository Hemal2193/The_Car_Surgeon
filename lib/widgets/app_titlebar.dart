import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

class AppTitleBar extends StatelessWidget {
  const AppTitleBar({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (_) {
        windowManager.startDragging();
      },
      child: Container(
        height: 30,
        color: Colors.white,
        child: Row(
          children: [
            const Spacer(),

            SizedBox(
              width: 45,
              height: 30,
              child: IconButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  windowManager.minimize();
                },
                icon: const Icon(Icons.remove, color: Colors.black, size: 16),
              ),
            ),

            SizedBox(
              width: 45,
              height: 30,
              child: IconButton(
                padding: EdgeInsets.zero,
                onPressed: () async {
                  bool isMaximized = await windowManager.isMaximized();

                  if (isMaximized) {
                    await windowManager.unmaximize();
                  } else {
                    await windowManager.maximize();
                  }
                },
                icon: const Icon(
                  Icons.crop_square,
                  color: Colors.black,
                  size: 14,
                ),
              ),
            ),

            SizedBox(
              width: 45,
              height: 30,
              child: IconButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  windowManager.close();
                },
                icon: const Icon(Icons.close, color: Colors.black, size: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
