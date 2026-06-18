import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:tcs/controllers/customer_controller.dart';
import 'package:tcs/controllers/vehicle_controller.dart';

import 'package:tcs/database/id_generator.dart';

import 'package:tcs/models/customer_model.dart';
import 'package:tcs/models/vehicle_model.dart';
import 'package:tcs/services/customer_cache.dart';
import 'package:tcs/utils/responsive.dart';
import 'package:tcs/widgets/app_fuel_field.dart';

import 'package:tcs/widgets/app_text_field.dart';
import 'package:tcs/widgets/custom_button.dart';
import 'package:tcs/widgets/app_selector.dart';

class AddVehicleDialog extends StatefulWidget {
  final ScrollController? scrollController;

  final Vehicle? vehicle;

  const AddVehicleDialog({super.key, this.vehicle, this.scrollController});

  @override
  State<AddVehicleDialog> createState() => _AddVehicleDialogState();
}

class _AddVehicleDialogState extends State<AddVehicleDialog> {
  final registrationController = TextEditingController();

  final makeController = TextEditingController();

  final modelController = TextEditingController();

  final colorController = TextEditingController();

  final engineController = TextEditingController();

  final chassisController = TextEditingController();

  final odometerController = TextEditingController();

  String fuelType = 'Petrol';

  Customer? selectedCustomer;

  final customerSearchController = TextEditingController();
  List<Customer> filteredCustomers = [];

  String? _customerError;
  String? _registrationError;

  bool get isEditing => widget.vehicle != null;

  void filterCustomers(String query) {
    final customers = CustomerCache.search(
      query,
      Get.find<CustomerController>().customers,
    );

    setState(() {
      filteredCustomers = customers
          .where(
            (c) =>
                c.name.toLowerCase().contains(query.toLowerCase()) ||
                c.customerId.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
    });
  }

  @override
  void initState() {
    super.initState();

    final customers = Get.find<CustomerController>().customers;

    filteredCustomers = customers;

    final vehicle = widget.vehicle;
    if (vehicle != null) {
      selectedCustomer = customers.firstWhereOrNull(
        (customer) => customer.customerId == vehicle.customerId,
      );
      registrationController.text = vehicle.registrationNumber;
      makeController.text = vehicle.make;
      modelController.text = vehicle.model;
      colorController.text = vehicle.vehicleColor ?? '';
      engineController.text = vehicle.engineNumber ?? '';
      chassisController.text = vehicle.chassisNumber ?? '';
      odometerController.text = vehicle.odoMeter.toString();
      fuelType = vehicle.fuelType;
    }
  }

  @override
  void dispose() {
    registrationController.dispose();
    makeController.dispose();
    modelController.dispose();
    colorController.dispose();
    engineController.dispose();
    chassisController.dispose();
    customerSearchController.dispose();
    odometerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (Responsive.isDesktop(context)) {
      return _buildDesktopAddVehicle(context);
    }
    return _buildMobileAddVehicle(context);
  }

  Widget _buildDesktopAddVehicle(BuildContext context) {
    Get.find<CustomerController>();

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 750,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isEditing ? 'Edit Vehicle' : 'Add Vehicle',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 25),

              const Text(
                'Customer *',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),

              const SizedBox(height: 8),

              AppSelector<Customer>(
                items: Get.find<CustomerController>().customers,
                initialItem: selectedCustomer,
                hintText: 'Select Customer',
                displayText: (c) => '${c.name} (${c.customerId})',
                searchText: (c) => '${c.name} ${c.customerId}',
                itemBuilder: (c) => Text(c.name),
                onSelected: (customer) {
                  setState(() {
                    selectedCustomer = customer;
                    _customerError = null;
                  });
                },
              ),

              if (_customerError != null) ...[
                const SizedBox(height: 4),
                Text(
                  _customerError!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ],

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppTextField(
                          hintText: 'Registration Number *',
                          controller: registrationController,
                        ),
                        if (_registrationError != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            _registrationError!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(width: 16),

                  Expanded(
                    child: AppFuelField(
                      initialValue: fuelType,
                      onSelected: (value) {
                        fuelType = value;
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      hintText: 'Make *',
                      controller: makeController,
                    ),
                  ),

                  const SizedBox(width: 16),

                  Expanded(
                    child: AppTextField(
                      hintText: 'Model *',
                      controller: modelController,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      hintText: 'Vehicle Color',
                      controller: colorController,
                    ),
                  ),

                  const SizedBox(width: 16),

                  Expanded(
                    child: AppTextField(
                      hintText: 'Engine Number',
                      controller: engineController,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      hintText: 'Chassis Number',
                      controller: chassisController,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: AppTextField(
                      hintText: 'Odometer in Km',
                      controller: odometerController,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  cButton(
                    () {
                      Navigator.pop(context);
                    },
                    'Cancel',
                    false,
                  ),

                  const SizedBox(width: 10),

                  cButton(saveVehicle, isEditing ? 'Update' : 'Save', true),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileAddVehicle(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.92,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 14),

            _handleBar(),

            Expanded(
              child: SingleChildScrollView(
                controller: widget.scrollController,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _title(),
                    const SizedBox(height: 20),

                    _label("Customer *"),
                    AppSelector<Customer>(
                      showAbove: true,
                      items: Get.find<CustomerController>().customers,
                      initialItem: selectedCustomer,
                      hintText: "Select Customer",
                      displayText: (c) => "${c.name} (${c.customerId})",
                      searchText: (c) => "${c.name} ${c.customerId}",
                      itemBuilder: (c) => Text(c.name),
                      onSelected: (customer) {
                        setState(() {
                          selectedCustomer = customer;
                          _customerError = null;
                        });
                      },
                    ),
                    if (_customerError != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _customerError!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ],

                    const SizedBox(height: 14),

                    _field("Registration Number *", registrationController),
                    if (_registrationError != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _registrationError!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ],
                    const SizedBox(height: 14),

                    _label("Fuel Type"),
                    AppFuelField(
                      initialValue: fuelType,
                      onSelected: (value) {
                        fuelType = value;
                      },
                    ),

                    const SizedBox(height: 14),

                    _field("Make *", makeController),
                    const SizedBox(height: 14),

                    _field("Model *", modelController),
                    const SizedBox(height: 14),

                    _field("Vehicle Color", colorController),
                    const SizedBox(height: 14),

                    _field("Engine Number", engineController),
                    const SizedBox(height: 14),

                    _field("Chassis Number", chassisController),
                    const SizedBox(height: 14),

                    _field(
                      "Odometer (Km)",
                      odometerController,
                      keyboard: TextInputType.number,
                    ),

                    const SizedBox(height: 24),

                    _buttons(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _handleBar() {
    return Center(
      child: Container(
        width: 50,
        height: 5,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _title() {
    return Text(
      isEditing ? "Edit Vehicle" : "Add Vehicle",
      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    TextInputType? keyboard,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        AppTextField(
          controller: controller,
          keyboardType: keyboard,
          hintText: label,
        ),
      ],
    );
  }

  Widget _buttons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        cButton(() => Navigator.pop(context), "Cancel", false),
        const SizedBox(width: 10),
        cButton(saveVehicle, isEditing ? "Update" : "Save", true),
      ],
    );
  }

  Future<void> saveVehicle() async {
    // Reset errors
    setState(() {
      _customerError = null;
      _registrationError = null;
    });

    bool hasError = false;

    // Validate customer
    if (selectedCustomer == null) {
      setState(() {
        _customerError = 'Please select a customer';
      });
      hasError = true;
    }

    // Validate registration number
    if (registrationController.text.trim().isEmpty) {
      setState(() {
        _registrationError = 'Please enter registration number';
      });
      hasError = true;
    }

    if (hasError) return;

    final vehicleController = Get.find<VehicleController>();

    final vehicle = Vehicle(
      vehicleId: widget.vehicle?.vehicleId ?? IdGenerator.generateVehicleId(),

      customerId: selectedCustomer!.customerId,

      registrationNumber: registrationController.text.trim(),

      make: makeController.text.trim(),

      model: modelController.text.trim(),

      vehicleColor: colorController.text.trim(),

      fuelType: fuelType,

      engineNumber: engineController.text.trim(),

      chassisNumber: chassisController.text.trim(),

      odoMeter: odometerController.text.trim(),
    );

    if (isEditing) {
      await vehicleController.updateVehicle(vehicle);
    } else {
      await vehicleController.addVehicle(vehicle);
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }
}
