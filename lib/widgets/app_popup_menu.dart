import 'package:flutter/material.dart';

class AppPopupMenu extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const AppPopupMenu({
    super.key,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(
        Icons.more_vert,
        color: Colors.black,
      ),

      color: Colors.white,

      elevation: 4,

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(
          color: Colors.black12,
        ),
      ),

      onSelected: (value) {
        if (value == 'edit') {
          onEdit();
        }

        if (value == 'delete') {
          onDelete();
        }
      },

      itemBuilder: (context) => [
        const PopupMenuItem<String>(
          value: 'edit',
          child: Row(
            children: [
              Icon(
                Icons.edit_outlined,
                size: 18,
                color: Colors.black,
              ),

              SizedBox(width: 10),

              Text(
                'Edit',
                style: TextStyle(
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),

        const PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              Icon(
                Icons.delete_outline,
                size: 18,
                color: Colors.black,
              ),

              SizedBox(width: 10),

              Text(
                'Delete',
                style: TextStyle(
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}