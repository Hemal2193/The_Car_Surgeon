import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:tcs/controllers/customer_controller.dart';
import 'package:tcs/database/id_generator.dart';
import 'package:tcs/models/customer_model.dart';
import 'package:tcs/widgets/app_text_field.dart';
import 'package:tcs/widgets/custom_button.dart';

class AddCustomerDialog extends StatefulWidget {
  const AddCustomerDialog({super.key});

  @override
  State<AddCustomerDialog> createState() => _AddCustomerDialogState();
}

class _AddCustomerDialogState extends State<AddCustomerDialog> {
  final nameController = TextEditingController();

  final contact1Controller = TextEditingController();

  final contact2Controller = TextEditingController();

  final addressController = TextEditingController();

  final emailController = TextEditingController();

  final gstController = TextEditingController();

  final panController = TextEditingController();

  void saveCustomer() async {
    if (nameController.text.trim().isEmpty ||
        contact1Controller.text.trim().isEmpty) {
      return;
    }

    final customerController = Get.find<CustomerController>();

    final customer = Customer(
      customerId: IdGenerator.generateCustomerId(),

      name: nameController.text.trim(),

      contact1: contact1Controller.text.trim(),

      contact2: contact2Controller.text.trim(),

      address: addressController.text.trim(),

      email: emailController.text.trim(),

      gstNumber: gstController.text.trim(),

      panNumber: panController.text.trim(),
    );

    await customerController.addCustomer(customer);

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 700,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Add Customer',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 25),

              const Text(
                'Name *',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),

              const SizedBox(height: 8),

              AppTextField(
                hintText: 'Enter customer name',
                controller: nameController,
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Contact 1 *',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),

                        const SizedBox(height: 8),

                        AppTextField(
                          hintText: 'Enter contact number',
                          keyboardType: TextInputType.phone,
                          controller: contact1Controller,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 16),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Contact 2',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),

                        const SizedBox(height: 8),

                        AppTextField(
                          hintText: 'Enter alternate number',
                          keyboardType: TextInputType.phone,
                          controller: contact2Controller,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              const Text(
                'Address',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),

              const SizedBox(height: 8),

              AppTextField(
                hintText: 'Enter address',
                maxLines: 3,
                controller: addressController,
              ),

              const SizedBox(height: 16),

              const Text(
                'Email',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),

              const SizedBox(height: 8),

              AppTextField(
                hintText: 'Enter email address',
                keyboardType: TextInputType.emailAddress,
                controller: emailController,
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'GST Number',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),

                        const SizedBox(height: 8),

                        AppTextField(
                          hintText: 'Enter GST number',
                          controller: gstController,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 16),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'PAN Number',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),

                        const SizedBox(height: 8),

                        AppTextField(
                          hintText: 'Enter PAN number',
                          controller: panController,
                        ),
                      ],
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

                  cButton(saveCustomer, 'Save', true),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
