import 'package:flutter/material.dart';

class AppPopupMenuOption {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const AppPopupMenuOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}

class AppPopupMenu extends StatelessWidget {
  final List<AppPopupMenuOption> options;

  const AppPopupMenu({
    super.key,
    required this.options,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      icon: const Icon(
        Icons.more_vert,
        color: Colors.black,
      ),

      color: Colors.white,

      elevation: 4,

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Colors.black12),
      ),

      onSelected: (index) {
        options[index].onTap();
      },

      itemBuilder: (context) {
        return List.generate(
          options.length,
          (index) {
            final option = options[index];

            return PopupMenuItem<int>(
              value: index,

              child: Row(
                children: [
                  Icon(
                    option.icon,
                    size: 18,
                    color: Colors.black,
                  ),

                  const SizedBox(width: 10),

                  Text(
                    option.label,
                    style: const TextStyle(
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}