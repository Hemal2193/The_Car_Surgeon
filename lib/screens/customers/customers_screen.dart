import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tcs/controllers/customer_controller.dart';
import 'package:tcs/controllers/vehicle_controller.dart';
import 'package:tcs/models/customer_model.dart';
import 'package:tcs/screens/customers/add_customer_dialog.dart';
import 'package:tcs/widgets/adder_button.dart';
import 'package:tcs/widgets/app_popup_menu.dart';
import 'package:tcs/widgets/delete_confirmation_dialog.dart';

class CustomersScreen extends StatelessWidget {
  const CustomersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                'Customers',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),

              const Spacer(),

              adderButton(
                label: 'Add Customer',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return const AddCustomerDialog();
                    },
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 20),

          TextField(
            decoration: InputDecoration(
              hintText: 'Search customer...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),

          const SizedBox(height: 20),

          Expanded(
            child: GetBuilder<CustomerController>(
              builder: (controller) {
                if (controller.customers.isEmpty) {
                  return Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(child: Text('No customers found')),
                  );
                }

                return Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Customer ID')),
                        DataColumn(label: Text('Name')),
                        DataColumn(label: Text('Contact')),
                        DataColumn(label: Text('GST')),
                        DataColumn(label: Text('Vehicles')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: controller.customers.map((customer) {
                        return buildCustomerRow(context, customer);
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  DataRow buildCustomerRow(BuildContext context, Customer customer) {
    return DataRow(
      cells: [
        DataCell(
          Text(
            customer.customerId,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),

        DataCell(Text(customer.name)),

        DataCell(Text(customer.contact1)),

        DataCell(
          Text(
            customer.gstNumber?.isNotEmpty == true ? customer.gstNumber! : '-',
          ),
        ),

        DataCell(
          Text(
            Get.find<VehicleController>()
                .getVehicleCountForCustomer(customer.customerId)
                .toString(),
          ),
        ),

        DataCell(
          AppPopupMenu(
            onEdit: () {
              print('Edit ${customer.customerId}');
            },

            onDelete: () {
              showDialog(
                context: context,
                builder: (dialogContext) {
                  return DeleteConfirmationDialog(
                    title: 'Delete Customer',
                    message:
                        'Are you sure you want to delete ${customer.name}?',
                    onDelete: () async {
                      final customerController = Get.find<CustomerController>();

                      await customerController.deleteCustomer(
                        customer.customerId,
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
