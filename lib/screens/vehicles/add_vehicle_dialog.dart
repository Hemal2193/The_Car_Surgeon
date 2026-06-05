import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:tcs/controllers/customer_controller.dart';
import 'package:tcs/controllers/vehicle_controller.dart';

import 'package:tcs/database/id_generator.dart';

import 'package:tcs/models/customer_model.dart';
import 'package:tcs/models/vehicle_model.dart';
import 'package:tcs/services/customer_cache.dart';
import 'package:tcs/widgets/app_fuel_field.dart';

import 'package:tcs/widgets/app_text_field.dart';
import 'package:tcs/widgets/custom_button.dart';
import 'package:tcs/widgets/app_customer_selector.dart';

class AddVehicleDialog extends StatefulWidget {
  const AddVehicleDialog({super.key});

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

  String fuelType = 'Petrol';

  Customer? selectedCustomer;

  final customerSearchController = TextEditingController();
  List<Customer> filteredCustomers = [];

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              const Text(
                'Add Vehicle',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 25),

              const Text(
                'Customer *',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),

              const SizedBox(height: 8),

              AppCustomerSelector(
                onSelected: (customer) {
                  selectedCustomer = customer;
                },
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      hintText: 'Registration Number *',
                      controller: registrationController,
                    ),
                  ),

                  const SizedBox(width: 16),

                  Expanded(
                    child: AppFuelField(
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

              AppTextField(
                hintText: 'Chassis Number',
                controller: chassisController,
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

                  cButton(saveVehicle, 'Save', true),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> saveVehicle() async {
    if (selectedCustomer == null) {
      return;
    }

    if (registrationController.text.trim().isEmpty ||
        makeController.text.trim().isEmpty ||
        modelController.text.trim().isEmpty) {
      return;
    }

    final vehicleController = Get.find<VehicleController>();

    final vehicle = Vehicle(
      vehicleId: IdGenerator.generateVehicleId(),

      customerId: selectedCustomer!.customerId,

      registrationNumber: registrationController.text.trim(),

      make: makeController.text.trim(),

      model: modelController.text.trim(),

      vehicleColor: colorController.text.trim(),

      fuelType: fuelType,

      engineNumber: engineController.text.trim(),

      chassisNumber: chassisController.text.trim(),
    );

    await vehicleController.addVehicle(vehicle);

    if (mounted) {
      Navigator.pop(context);
    }
  }
}
