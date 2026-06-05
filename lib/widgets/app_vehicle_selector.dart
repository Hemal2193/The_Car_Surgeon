import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tcs/widgets/app_selector_overlay.dart';

import '../controllers/vehicle_controller.dart';
import '../models/vehicle_model.dart';

class AppVehicleSelector extends StatefulWidget {
  final String customerId;
  final Function(Vehicle) onSelected;

  const AppVehicleSelector({
    super.key,
    required this.customerId,
    required this.onSelected,
  });

  @override
  State<AppVehicleSelector> createState() => _AppVehicleSelectorState();
}

class _AppVehicleSelectorState extends State<AppVehicleSelector> {
  final TextEditingController controller = TextEditingController();

  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  List<Vehicle> filtered = [];

  // ---------------- GET FILTERED VEHICLES ----------------
  List<Vehicle> _vehicles() {
    final all = Get.find<VehicleController>().vehicles;
    return all.where((v) => v.customerId == widget.customerId).toList();
  }

  // ---------------- SHOW OVERLAY ----------------
  void _showOverlay() {
    _removeOverlay();

    final overlay = Overlay.of(context);

    _overlayEntry = AppSelectorOverlay.create(
      context: context,
      link: _layerLink,
      onClose: _removeOverlay,
      children: filtered.map((v) {
        return ListTile(
          dense: true,
          title: Text(v.registrationNumber),
          subtitle: Text("${v.make} • ${v.model}"),
          onTap: () {
            controller.text = v.registrationNumber;
            widget.onSelected(v);
            _removeOverlay();
          },
        );
      }).toList(),
    );

    overlay.insert(_overlayEntry!);
  }

  // ---------------- REMOVE OVERLAY ----------------
  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  // ---------------- FILTER ----------------
  void _filter(String value) {
    final all = _vehicles();

    setState(() {
      filtered = all
          .where(
            (v) =>
                v.registrationNumber.toLowerCase().contains(
                  value.toLowerCase(),
                ) ||
                v.make.toLowerCase().contains(value.toLowerCase()) ||
                v.model.toLowerCase().contains(value.toLowerCase()),
          )
          .toList();
    });

    _showOverlay();
  }

  @override
  void dispose() {
    _removeOverlay();
    controller.dispose();
    super.dispose();
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
            filtered = _vehicles();
          });
          _showOverlay();
        },
        decoration: InputDecoration(
          hintText: "Select Vehicle",
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.black26),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.black, width: 1.5),
          ),
        ),
      ),
    );
  }
}
