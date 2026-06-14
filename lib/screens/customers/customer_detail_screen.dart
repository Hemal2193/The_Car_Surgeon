import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tcs/screens/customers/add_customer_dialog.dart';
import 'package:tcs/screens/invoices/invoice_preview_screen.dart';
import 'package:tcs/screens/invoices/create_invoice_screen.dart';
import 'package:tcs/screens/vehicles/add_vehicle_dialog.dart';
import 'package:tcs/screens/vehicles/vehicle_detail_screen.dart';
import 'package:tcs/utils/responsive.dart';
import 'package:tcs/widgets/app_titlebar.dart';
import 'package:tcs/widgets/custom_button.dart';
import 'package:tcs/widgets/app_popup_menu.dart';
import 'package:tcs/widgets/delete_confirmation_dialog.dart';
import 'package:tcs/widgets/erp_mobile_tile.dart';

import '../../controllers/customer_controller.dart';
import '../../controllers/vehicle_controller.dart';
import '../../controllers/invoice_controller.dart';

import '../../models/customer_model.dart';
import '../../models/vehicle_model.dart';
import '../../models/invoice_model.dart';

class CustomerDetailScreen extends StatefulWidget {
  final String customerId;

  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  late CustomerController customerController;
  late VehicleController vehicleController;
  late InvoiceController invoiceController;

  Customer? customer;

  List<Vehicle> vehicles = [];

  List<Invoice> invoices = [];

  double totalRevenue = 0;
  @override
  Widget build(BuildContext context) {
    return GetBuilder<CustomerController>(
      builder: (_) {
        return GetBuilder<VehicleController>(
          builder: (_) {
            return GetBuilder<InvoiceController>(
              builder: (_) => _buildReactiveContent(context),
            );
          },
        );
      },
    );
  }

  Widget _buildReactiveContent(BuildContext context) {
    customerController = Get.find<CustomerController>();
    vehicleController = Get.find<VehicleController>();
    invoiceController = Get.find<InvoiceController>();

    customer = customerController.getCustomerById(widget.customerId);

    if (customer == null) {
      return const Scaffold(body: Center(child: Text("Customer not found")));
    }

    vehicles = vehicleController.vehicles
        .where((v) => v.customerId == widget.customerId)
        .toList();
    invoices = invoiceController.invoices
        .where((i) => i.customerId == widget.customerId)
        .toList();

    totalRevenue = 0;

    for (final invoice in invoices) {
      totalRevenue += invoice.grandTotal;
    }

    if (Responsive.isDesktop(context)) {
      return _buildDesktop(context);
    }

    return _buildMobile(context);
  }

  Widget _buildDesktop(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const AppTitleBar(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // =====================================================
                  // HEADER
                  // =====================================================
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Get.back(),
                        icon: const Icon(Icons.arrow_back),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        "Customer Details",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      cButton(
                        () {
                          showDialog(
                            context: context,
                            builder: (context) {
                              return AddCustomerDialog(customer: customer);
                            },
                          );
                        },
                        'Edit Customer',
                        true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          // =====================================================
                          // STATS
                          // =====================================================
                          Row(
                            children: [
                              Expanded(
                                child: _statCard(
                                  "Vehicles",
                                  vehicles.length.toString(),
                                  Icons.directions_car,
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: _statCard(
                                  "Invoices",
                                  invoices.length.toString(),
                                  Icons.receipt_long,
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: _statCard(
                                  "Revenue",
                                  "₹${totalRevenue.toStringAsFixed(2)}",
                                  Icons.currency_rupee,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // =====================================================
                          // CUSTOMER CARD
                          // =====================================================
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  customer!.name,
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  customer!.customerId,
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                                const SizedBox(height: 25),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _infoTile(
                                        "Primary Contact",
                                        customer!.contact1,
                                      ),
                                    ),
                                    const SizedBox(width: 15),
                                    Expanded(
                                      child: _infoTile(
                                        "Secondary Contact",
                                        customer!.contact2 ?? "-",
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 15),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _infoTile(
                                        "Email",
                                        customer!.email ?? "-",
                                      ),
                                    ),
                                    const SizedBox(width: 15),
                                    Expanded(
                                      child: _infoTile(
                                        "GST Number",
                                        customer!.gstNumber ?? "-",
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 15),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _infoTile(
                                        "PAN Number",
                                        customer!.panNumber ?? "-",
                                      ),
                                    ),
                                    const SizedBox(width: 15),
                                    Expanded(
                                      child: _infoTile(
                                        "Address",
                                        customer!.address ?? "-",
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          // =====================================================
                          // VEHICLES
                          // =====================================================
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Vehicles",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: vehicles.isEmpty
                                ? const Padding(
                                    padding: EdgeInsets.all(30),
                                    child: Center(
                                      child: Text("No vehicles found"),
                                    ),
                                  )
                                : SingleChildScrollView(
                                    child: DataTable(
                                      showCheckboxColumn: false,
                                      columns: const [
                                        DataColumn(label: Text("Registration")),
                                        DataColumn(label: Text("Make")),
                                        DataColumn(label: Text("Model")),
                                        DataColumn(label: Text("Fuel")),
                                        DataColumn(label: Text("Color")),
                                        DataColumn(label: Text("Actions")),
                                      ],
                                      rows: vehicles.map((v) {
                                        return DataRow(
                                          onSelectChanged: (_) {},
                                          cells: [
                                            DataCell(
                                              Text(v.registrationNumber),
                                            ),
                                            DataCell(Text(v.make)),
                                            DataCell(Text(v.model)),
                                            DataCell(Text(v.fuelType)),
                                            DataCell(
                                              Text(v.vehicleColor ?? "-"),
                                            ),
                                            DataCell(
                                              AppPopupMenu(
                                                onEdit: () {
                                                  showDialog(
                                                    context: context,
                                                    builder: (context) {
                                                      return AddVehicleDialog(
                                                        vehicle: v,
                                                      );
                                                    },
                                                  );
                                                },
                                                onDelete: () {
                                                  showDialog(
                                                    context: context,
                                                    builder: (dialogContext) {
                                                      return DeleteConfirmationDialog(
                                                        title: 'Delete Vehicle',
                                                        message:
                                                            'Are you sure you want to delete ${v.registrationNumber}?',
                                                        onDelete: () async {
                                                          await vehicleController
                                                              .deleteVehicle(
                                                                v.vehicleId,
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
                                      }).toList(),
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 25),
                          // =====================================================
                          // INVOICES
                          // =====================================================
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Invoices",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: invoices.isEmpty
                                ? const Padding(
                                    padding: EdgeInsets.all(30),
                                    child: Center(
                                      child: Text("No invoices found"),
                                    ),
                                  )
                                : SingleChildScrollView(
                                    child: DataTable(
                                      showCheckboxColumn: false,
                                      columns: const [
                                        DataColumn(label: Text("Invoice ID")),
                                        DataColumn(label: Text("Items")),
                                        DataColumn(label: Text("Total")),
                                        DataColumn(label: Text("Date")),
                                        DataColumn(label: Text("Actions")),
                                      ],
                                      rows: invoices.map((invoice) {
                                        return DataRow(
                                          onSelectChanged: (selected) {
                                            if (selected == true) {
                                              Get.to(
                                                () => InvoicePreviewScreen(
                                                  invoiceId: invoice.invoiceId,
                                                ),
                                              );
                                            }
                                          },
                                          cells: [
                                            DataCell(Text(invoice.invoiceId)),
                                            DataCell(
                                              Text(
                                                invoice.items.length.toString(),
                                              ),
                                            ),
                                            DataCell(
                                              Text(
                                                invoice.grandTotal
                                                    .toStringAsFixed(2),
                                              ),
                                            ),
                                            DataCell(
                                              Text(
                                                invoice.dateTime
                                                    .toString()
                                                    .split(' ')
                                                    .first,
                                              ),
                                            ),
                                            DataCell(
                                              AppPopupMenu(
                                                onEdit: () {
                                                  Get.to(
                                                    () => CreateInvoiceScreen(
                                                      invoice: invoice,
                                                    ),
                                                  );
                                                },
                                                onDelete: () {
                                                  showDialog(
                                                    context: context,
                                                    builder: (_) =>
                                                        DeleteConfirmationDialog(
                                                          title:
                                                              "Delete Invoice",
                                                          message:
                                                              "Are you sure you want to delete ${invoice.invoiceId}?",
                                                          onDelete: () async {
                                                            await invoiceController
                                                                .deleteInvoice(
                                                                  invoice
                                                                      .invoiceId,
                                                                );
                                                          },
                                                        ),
                                                  );
                                                },
                                              ),
                                            ),
                                          ],
                                        );
                                      }).toList(),
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobile(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,

        leading: IconButton(
          onPressed: Get.back,
          icon: const Icon(Icons.arrow_back, color: Colors.black),
        ),

        title: const Text(
          'Customer Details',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),

        actions: [
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) {
                  return AddCustomerDialog(customer: customer);
                },
              );
            },

            icon: const Icon(Icons.edit_outlined, color: Colors.black),
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: 24,
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            _buildMobileCustomerCard(),

            const SizedBox(height: 20),

            _buildMobileStats(),

            const SizedBox(height: 24),

            _buildMobileVehicles(context, vehicles, vehicleController),

            const SizedBox(height: 24),

            _buildMobileInvoices(context, invoices, invoiceController),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileCustomerCard() {
    bool isNotEmpty(String? value) {
      return value != null && value.trim().isNotEmpty;
    }

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),

        borderRadius: BorderRadius.circular(16),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Text(
            customer!.name,

            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 4),

          Text(
            customer!.customerId,

            style: TextStyle(color: Colors.grey.shade600),
          ),

          const SizedBox(height: 20),

          _mobileInfoTile(Icons.phone_outlined, customer?.contact1 ?? '-'),

          if (isNotEmpty(customer?.contact2))
            _mobileInfoTile(Icons.phone_outlined, customer!.contact2!),

          if (isNotEmpty(customer?.email))
            _mobileInfoTile(Icons.email_outlined, customer!.email!),

          if (isNotEmpty(customer?.gstNumber))
            _mobileInfoTile(Icons.receipt_long_outlined, customer!.gstNumber!),

          if (isNotEmpty(customer?.panNumber))
            _mobileInfoTile(Icons.badge_outlined, customer!.panNumber!),

          if (isNotEmpty(customer?.address))
            _mobileInfoTile(Icons.location_on_outlined, customer!.address!),
        ],
      ),
    );
  }

  Widget _mobileInfoTile(IconData icon, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade700),
          const SizedBox(width: 12),

          Expanded(child: Text(value, style: const TextStyle(fontSize: 15))),
        ],
      ),
    );
  }

  Widget _buildMobileStats() {
    return Row(
      children: [
        Expanded(
          child: _mobileStatCard(
            vehicles.length.toString(),
            'Vehicles',
            Icons.directions_car_outlined,
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: _mobileStatCard(
            invoices.length.toString(),
            'Invoices',
            Icons.receipt_long_outlined,
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: _mobileStatCard(
            '₹${totalRevenue.toStringAsFixed(0)}',
            'Revenue',
            Icons.currency_rupee,
          ),
        ),
      ],
    );
  }

  Widget _buildMobileVehicles(
    BuildContext context,
    List<Vehicle> vehicles,
    VehicleController vehicleController,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Vehicles",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 12),

        if (vehicles.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(child: Text("No vehicles found")),
          )
        else
          Column(
            children: vehicles.map((v) {
              return ErpMobileTile(
                onTap: () {
                  Get.to(() => VehicleDetailScreen(vehicleId: v.vehicleId));
                },

                leading: CircleAvatar(
                  backgroundColor: Colors.grey.shade100,

                  child: const Icon(
                    Icons.directions_car_outlined,
                    color: Colors.black87,
                  ),
                ),

                title: v.registrationNumber,

                subtitles: ["${v.make} ${v.model}", v.fuelType],

                trailing: AppPopupMenu(
                  onEdit: () {
                    showDialog(
                      context: context,
                      builder: (_) {
                        return AddVehicleDialog(vehicle: v);
                      },
                    );
                  },

                  onDelete: () {
                    showDialog(
                      context: context,
                      builder: (_) {
                        return DeleteConfirmationDialog(
                          title: 'Delete Vehicle',

                          message:
                              'Are you sure you want to delete '
                              '${v.registrationNumber}?',

                          onDelete: () async {
                            await vehicleController.deleteVehicle(v.vehicleId);
                          },
                        );
                      },
                    );
                  },
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildMobileInvoices(
    BuildContext context,
    List<Invoice> invoices,
    InvoiceController invoiceController,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Invoices",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 12),

        if (invoices.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(child: Text("No invoices found")),
          )
        else
          Column(
            children: invoices.map((invoice) {
              return ErpMobileTile(
                onTap: () {
                  Get.to(
                    () => InvoicePreviewScreen(invoiceId: invoice.invoiceId),
                  );
                },

                leading: CircleAvatar(
                  backgroundColor: Colors.grey.shade100,

                  child: const Icon(Icons.receipt_long, color: Colors.black87),
                ),

                title: invoice.invoiceId,

                subtitles: [
                  '${invoice.items.length} items',

                  formatDate(invoice.dateTime),
                ],

                trailing: Row(
                  // mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '₹${invoice.grandTotal.toStringAsFixed(0)}',

                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),

                    // const SizedBox(width: 5),
                    AppPopupMenu(
                      onEdit: () {
                        Get.to(() => CreateInvoiceScreen(invoice: invoice));
                      },

                      onDelete: () {
                        showDialog(
                          context: context,
                          builder: (_) {
                            return DeleteConfirmationDialog(
                              title: 'Delete Invoice',

                              message:
                                  'Are you sure you want to delete '
                                  '${invoice.invoiceId}?',

                              onDelete: () async {
                                await invoiceController.deleteInvoice(
                                  invoice.invoiceId,
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _mobileStatCard(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),

      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),

        borderRadius: BorderRadius.circular(12),
      ),

      child: Column(
        children: [
          Icon(icon),

          const SizedBox(height: 8),

          Text(
            value,

            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),

          Text(
            label,

            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _infoTile(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(title),
        ],
      ),
    );
  }

  String formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString().substring(2);

    return "$day-$month-$year";
  }
}
