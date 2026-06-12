import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tcs/controllers/customer_controller.dart';
import 'package:tcs/database/id_generator.dart';
import 'package:tcs/models/customer_model.dart';
import 'package:tcs/utils/responsive.dart';
import 'package:tcs/widgets/app_text_field.dart';
import 'package:tcs/widgets/custom_button.dart';

class AddCustomerDialog extends StatefulWidget {
  final ScrollController? scrollController;

  final Customer? customer;

  const AddCustomerDialog({super.key, this.customer, this.scrollController});

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

  String? _nameError;
  String? _contact1Error;

  bool get isEditing => widget.customer != null;

  @override
  void initState() {
    super.initState();

    final customer = widget.customer;
    if (customer != null) {
      nameController.text = customer.name;
      contact1Controller.text = customer.contact1;
      contact2Controller.text = customer.contact2 ?? '';
      addressController.text = customer.address ?? '';
      emailController.text = customer.email ?? '';
      gstController.text = customer.gstNumber ?? '';
      panController.text = customer.panNumber ?? '';
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    contact1Controller.dispose();
    contact2Controller.dispose();
    addressController.dispose();
    emailController.dispose();
    gstController.dispose();
    panController.dispose();
    super.dispose();
  }

  /// Strip +91 or +91  prefix from contact number
  String _cleanContact(String raw) {
    var cleaned = raw.trim();
    cleaned = cleaned.replaceFirst(RegExp(r'^\+91[\s\-]?'), '');
    cleaned = cleaned.replaceFirst(RegExp(r'^0+'), '');
    return cleaned;
  }

  void saveCustomer() async {
    // Reset errors
    setState(() {
      _nameError = null;
      _contact1Error = null;
    });

    bool hasError = false;

    // Validate name
    if (nameController.text.trim().isEmpty) {
      setState(() {
        _nameError = 'Please enter customer name';
      });
      hasError = true;
    }

    // Validate contact1
    final rawContact = contact1Controller.text.trim();
    if (rawContact.isEmpty) {
      setState(() {
        _contact1Error = 'Please enter contact number';
      });
      hasError = true;
    } else {
      final cleaned = _cleanContact(rawContact);
      if (cleaned.length != 10 || !RegExp(r'^\d{10}$').hasMatch(cleaned)) {
        setState(() {
          _contact1Error = 'Contact number should be 10 digits';
        });
        hasError = true;
      }
    }

    if (hasError) return;

    final customerController = Get.find<CustomerController>();

    final cleanedContact = _cleanContact(contact1Controller.text);
    final cleanedContact2 = _cleanContact(contact2Controller.text);

    final customer = Customer(
      customerId:
          widget.customer?.customerId ?? IdGenerator.generateCustomerId(),

      name: nameController.text.trim(),

      contact1: cleanedContact,

      contact2: cleanedContact2,

      address: addressController.text.trim(),

      email: emailController.text.trim(),

      gstNumber: gstController.text.trim(),

      panNumber: panController.text.trim(),
    );

    if (isEditing) {
      await customerController.updateCustomer(customer);
    } else {
      await customerController.addCustomer(customer);
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (Responsive.isDesktop(context)) {
      return _buildDesktopAddCustomer(context);
    }

    return _buildMobileAddCustomer(context);
  }

  Widget _buildDesktopAddCustomer(BuildContext context) {
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
              Text(
                isEditing ? 'Edit Customer' : 'Add Customer',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
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

              if (_nameError != null) ...[
                const SizedBox(height: 4),
                Text(
                  _nameError!,
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

                        if (_contact1Error != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            _contact1Error!,
                            style: const TextStyle(color: Colors.red, fontSize: 12),
                          ),
                        ],
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

                  cButton(saveCustomer, isEditing ? 'Update' : 'Save', true),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileAddCustomer(BuildContext context) {
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

                    _field(
                      "Name *",
                      nameController,
                      hint: "Enter customer name",
                    ),
                    if (_nameError != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _nameError!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ],
                    const SizedBox(height: 14),

                    _field(
                      "Contact 1 *",
                      contact1Controller,
                      hint: "Enter contact number",
                      keyboard: TextInputType.phone,
                    ),
                    if (_contact1Error != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _contact1Error!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ],

                    const SizedBox(height: 14),

                    _field(
                      "Contact 2",
                      contact2Controller,
                      hint: "Enter alternate number",
                      keyboard: TextInputType.phone,
                    ),

                    const SizedBox(height: 14),

                    _field(
                      "Address",
                      addressController,
                      hint: "Enter address",
                      maxLines: 3,
                    ),

                    const SizedBox(height: 14),

                    _field(
                      "Email",
                      emailController,
                      hint: "Enter email",
                      keyboard: TextInputType.emailAddress,
                    ),

                    const SizedBox(height: 14),

                    _field(
                      "GST Number",
                      gstController,
                      hint: "Enter GST number",
                    ),

                    const SizedBox(height: 14),

                    _field(
                      "PAN Number",
                      panController,
                      hint: "Enter PAN number",
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
      isEditing ? "Edit Customer" : "Add Customer",
      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    String? hint,
    TextInputType? keyboard,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),

        const SizedBox(height: 6),

        AppTextField(
          controller: controller,
          hintText: hint ?? "",
          keyboardType: keyboard,
          maxLines: maxLines,
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
        cButton(saveCustomer, isEditing ? "Update" : "Save", true),
      ],
    );
  }
}