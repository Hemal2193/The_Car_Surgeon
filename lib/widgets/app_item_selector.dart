import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tcs/widgets/app_selector_overlay.dart';

import '../controllers/item_controller.dart';
import '../models/item_model.dart';

class AppItemSelector extends StatefulWidget {
  final Function(Item) onSelected;

  const AppItemSelector({super.key, required this.onSelected});

  @override
  State<AppItemSelector> createState() => _AppItemSelectorState();
}

class _AppItemSelectorState extends State<AppItemSelector> {
  final TextEditingController controller = TextEditingController();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  List<Item> filtered = [];

  void _showOverlay() {
    _removeOverlay();

    final overlay = Overlay.of(context);

    _overlayEntry = AppSelectorOverlay.create(
      context: context,
      link: _layerLink,
      onClose: _removeOverlay,
      children: filtered.take(6).map((i) {
        return ListTile(
          dense: true,
          title: Text(i.name),
          subtitle: Text("₹${i.price ?? 0}"),
          onTap: () {
            controller.text = i.name;
            widget.onSelected(i);
            _removeOverlay();
          },
        );
      }).toList(),
    );

    overlay.insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _filter(String value) {
    final all = Get.find<ItemController>().items;

    setState(() {
      filtered = all
          .where((i) => i.name.toLowerCase().contains(value.toLowerCase()))
          .toList();
    });

    _showOverlay();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextField(
        controller: controller,
        onChanged: _filter,
        onTap: () {
          setState(() {
            filtered = Get.find<ItemController>().items;
          });
          _showOverlay();
        },
        decoration: InputDecoration(
          hintText: "Select Item",
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
