import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tcs/widgets/app_selector_overlay.dart';

import '../controllers/customer_controller.dart';
import '../models/customer_model.dart';

class AppCustomerSelector extends StatefulWidget {
  final Function(Customer) onSelected;
  final Customer? initialCustomer;

  const AppCustomerSelector({
    super.key,
    required this.onSelected,
    this.initialCustomer,
  });

  @override
  State<AppCustomerSelector> createState() => _AppCustomerSelectorState();
}

class _AppCustomerSelectorState extends State<AppCustomerSelector> {
  final TextEditingController controller = TextEditingController();

  final LayerLink _layerLink = LayerLink();

  OverlayEntry? _overlayEntry;

  List<Customer> filtered = [];

  @override
  void initState() {
    super.initState();
    filtered = Get.find<CustomerController>().customers;

    final customer = widget.initialCustomer;
    if (customer != null) {
      controller.text = '${customer.name} (${customer.customerId})';
    }
  }

  void _showOverlay() {
    _removeOverlay();

    final overlay = Overlay.of(context);

    _overlayEntry = AppSelectorOverlay.create(
      context: context,
      link: _layerLink,
      onClose: _removeOverlay,
      children: filtered.map((c) {
        return ListTile(
          dense: true,
          title: Text(c.name),
          subtitle: Text(c.customerId),
          onTap: () {
            controller.text = '${c.name} (${c.customerId})';
            widget.onSelected(c);
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
    final all = Get.find<CustomerController>().customers;

    setState(() {
      filtered = all
          .where(
            (c) =>
                c.name.toLowerCase().contains(value.toLowerCase()) ||
                c.customerId.toLowerCase().contains(value.toLowerCase()),
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
            filtered = Get.find<CustomerController>().customers;
          });

          _showOverlay();
        },
        decoration: InputDecoration(
          hintText: 'Select Customer',
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
