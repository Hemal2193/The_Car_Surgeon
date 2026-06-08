import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tcs/controllers/customer_controller.dart';
import 'package:tcs/controllers/vehicle_controller.dart';
import 'package:tcs/models/customer_model.dart';
import 'package:tcs/screens/customers/add_customer_dialog.dart';
import 'package:tcs/widgets/adder_button.dart';
import 'package:tcs/widgets/app_popup_menu.dart';
import 'package:tcs/widgets/delete_confirmation_dialog.dart';
import 'package:tcs/screens/customers/customer_detail_screen.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
            controller: _searchController,
            onChanged: (value) {
              setState(() => _searchQuery = value.trim().toLowerCase());
            },
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
                final customers = controller.customers.where((customer) {
                  if (_searchQuery.isEmpty) return true;

                  return customer.customerId.toLowerCase().contains(
                        _searchQuery,
                      ) ||
                      customer.name.toLowerCase().contains(_searchQuery) ||
                      customer.contact1.toLowerCase().contains(_searchQuery) ||
                      (customer.gstNumber ?? '').toLowerCase().contains(
                        _searchQuery,
                      );
                }).toList();

                if (customers.isEmpty) {
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
                      showCheckboxColumn: false,
                      columns: const [
                        DataColumn(label: Text('Customer ID')),
                        DataColumn(label: Text('Name')),
                        DataColumn(label: Text('Contact')),
                        DataColumn(label: Text('GST')),
                        DataColumn(label: Text('Vehicles')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: customers.map((customer) {
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
      
      onSelectChanged: (selected) {
        if (selected == true) {
          Get.to(
            () => CustomerDetailScreen(customerId: customer.customerId),
          );
        }
      },
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
              showDialog(
                context: context,
                builder: (context) {
                  return AddCustomerDialog(customer: customer);
                },
              );
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
