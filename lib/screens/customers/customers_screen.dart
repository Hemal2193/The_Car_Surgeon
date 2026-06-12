import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:tcs/controllers/customer_controller.dart';
import 'package:tcs/controllers/vehicle_controller.dart';
import 'package:tcs/models/customer_model.dart';
import 'package:tcs/screens/customers/add_customer_dialog.dart';
import 'package:tcs/utils/responsive.dart';
import 'package:tcs/widgets/adder_button.dart';
import 'package:tcs/widgets/app_popup_menu.dart';
import 'package:tcs/widgets/delete_confirmation_dialog.dart';
import 'package:tcs/screens/customers/customer_detail_screen.dart';
import 'package:tcs/widgets/erp_mobile_tile.dart';

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
    if (Platform.isAndroid || Platform.isIOS) {
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.white, // background
          statusBarIconBrightness: Brightness.dark, // Android icons
          statusBarBrightness: Brightness.light, // iOS icons
        ),
      );
    }
    if (Responsive.isDesktop(context)) {
      return _buildDesktopCustomers();
    }

    return _buildMobileCustomers();
  }

  Widget _buildDesktopCustomers() {
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

  Widget _buildMobileCustomers() {
    return
    // backgroundColor: Colors.transparent,
    // extendBody: true,
    // floatingActionButton: FloatingActionButton.extended(
    //   label: const Text('Add Customer'),
    //   icon: const Icon(Icons.add),
    //   backgroundColor: Colors.black,
    //   foregroundColor: Colors.white,
    //   onPressed: () {
    //     showModalBottomSheet(
    //       context: context,
    //       isScrollControlled: true,
    //       isDismissible: true, // tap outside closes
    //       enableDrag: true, // swipe down closes
    //       backgroundColor: Colors.transparent,
    //       builder: (_) => AddCustomerDialog(),
    //     );
    //   },
    // ),
    SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Column(
          children: [
            _buildMobileHeader(),

            const SizedBox(height: 16),

            _buildSearch(),

            const SizedBox(height: 16),

            Expanded(child: _buildMobileCustomerList()),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileHeader() {
    return const Align(
      alignment: Alignment.centerLeft,
      child: Text(
        'Customers',
        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildSearch() {
    return TextField(
      controller: _searchController,
      onChanged: (value) {
        setState(() => _searchQuery = value.trim().toLowerCase());
      },
      decoration: InputDecoration(
        hintText: 'Search customers...',
        prefixIcon: const Icon(Icons.search),

        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }

  Widget _buildMobileCustomerList() {
    return GetBuilder<CustomerController>(
      builder: (controller) {
        final customers = controller.customers.where((customer) {
          if (_searchQuery.isEmpty) {
            return true;
          }

          return customer.customerId.toLowerCase().contains(_searchQuery) ||
              customer.name.toLowerCase().contains(_searchQuery) ||
              customer.contact1.toLowerCase().contains(_searchQuery) ||
              (customer.gstNumber ?? '').toLowerCase().contains(_searchQuery);
        }).toList();

        if (customers.isEmpty) {
          return const Center(child: Text('No customers found'));
        }

        return ListView.builder(
          padding: EdgeInsets.only(bottom: 150),
          itemCount: customers.length,

          itemBuilder: (context, index) {
            return _buildCustomerTile(customers[customers.length - index - 1]);
          },
        );
      },
    );
  }

  Widget _buildCustomerTile(Customer customer) {
    final vehicleCount = Get.find<VehicleController>()
        .getVehicleCountForCustomer(customer.customerId);

    return ErpMobileTile(
      onTap: () {
        Get.to(() => CustomerDetailScreen(customerId: customer.customerId));
      },

      leading: CircleAvatar(
        backgroundColor: Colors.grey.shade100,
        child: Text(
          customer.name.substring(0, 1).toUpperCase(),
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      title: customer.name,

      subtitles: [customer.contact1, "Vehicles: $vehicleCount"],

      trailing: AppPopupMenu(
        onEdit: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            isDismissible: true,
            backgroundColor: Colors.transparent,
            builder: (_) {
              return DraggableScrollableSheet(
                expand: false,
                initialChildSize: 0.80,
                minChildSize: 0.80,
                maxChildSize: 0.92,
                shouldCloseOnMinExtent: true,
                builder: (context, scrollController) {
                  return AddCustomerDialog(scrollController: scrollController);
                },
              );
            },
          );
        },

        onDelete: () {
          showDialog(
            context: context,
            builder: (_) {
              return DeleteConfirmationDialog(
                title: 'Delete Customer',
                message: 'Are you sure you want to delete ${customer.name}?',
                onDelete: () async {
                  await Get.find<CustomerController>().deleteCustomer(
                    customer.customerId,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  DataRow buildCustomerRow(BuildContext context, Customer customer) {
    return DataRow(
      onSelectChanged: (selected) {
        if (selected == true) {
          Get.to(() => CustomerDetailScreen(customerId: customer.customerId));
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
