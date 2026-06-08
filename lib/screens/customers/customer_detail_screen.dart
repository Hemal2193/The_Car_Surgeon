import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tcs/screens/customers/add_customer_dialog.dart';
import 'package:tcs/screens/invoices/invoice_preview_screen.dart';
import 'package:tcs/screens/invoices/create_invoice_screen.dart';
import 'package:tcs/screens/vehicles/add_vehicle_dialog.dart';
import 'package:tcs/widgets/custom_button.dart';
import 'package:tcs/widgets/app_popup_menu.dart';
import 'package:tcs/widgets/delete_confirmation_dialog.dart';

import '../../controllers/customer_controller.dart';
import '../../controllers/vehicle_controller.dart';
import '../../controllers/invoice_controller.dart';

import '../../models/customer_model.dart';
import '../../models/vehicle_model.dart';
import '../../models/invoice_model.dart';

class CustomerDetailScreen extends StatelessWidget {
  final String customerId;

  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  Widget build(BuildContext context) {
    final customerController = Get.find<CustomerController>();
    final vehicleController = Get.find<VehicleController>();
    final invoiceController = Get.find<InvoiceController>();

    final Customer? customer = customerController.getCustomerById(customerId);

    if (customer == null) {
      return const Scaffold(body: Center(child: Text("Customer not found")));
    }

    final List<Vehicle> vehicles = vehicleController.vehicles
        .where((v) => v.customerId == customerId)
        .toList();

    final List<Invoice> invoices = invoiceController.invoices
        .where((i) => i.customerId == customerId)
        .toList();

    double totalRevenue = 0;

    for (final invoice in invoices) {
      totalRevenue += invoice.grandTotal;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
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
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
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
                            customer.name,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 5),

                          Text(
                            customer.customerId,
                            style: TextStyle(color: Colors.grey.shade600),
                          ),

                          const SizedBox(height: 25),

                          Row(
                            children: [
                              Expanded(
                                child: _infoTile(
                                  "Primary Contact",
                                  customer.contact1,
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: _infoTile(
                                  "Secondary Contact",
                                  customer.contact2 ?? "-",
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
                                  customer.email ?? "-",
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: _infoTile(
                                  "GST Number",
                                  customer.gstNumber ?? "-",
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
                                  customer.panNumber ?? "-",
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: _infoTile(
                                  "Address",
                                  customer.address ?? "-",
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
                              child: Center(child: Text("No vehicles found")),
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
                                    onSelectChanged: (_) {
                                      // Vehicle Detail Screen
                                    },
                                    cells: [
                                      DataCell(Text(v.registrationNumber)),
                                      DataCell(Text(v.make)),
                                      DataCell(Text(v.model)),
                                      DataCell(Text(v.fuelType)),
                                      DataCell(Text(v.vehicleColor ?? "-")),
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
                              child: Center(child: Text("No invoices found")),
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
                                        Text(invoice.items.length.toString()),
                                      ),
                                      DataCell(
                                        Text(
                                          invoice.grandTotal.toStringAsFixed(2),
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
                                                    title: "Delete Invoice",
                                                    message:
                                                        "Are you sure you want to delete ${invoice.invoiceId}?",
                                                    onDelete: () async {
                                                      await invoiceController
                                                          .deleteInvoice(
                                                            invoice.invoiceId,
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
    );
  }

  static Widget _infoTile(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        // color: Colors.grey.shade50,
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

  static Widget _statCard(String title, String value, IconData icon) {
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
}
