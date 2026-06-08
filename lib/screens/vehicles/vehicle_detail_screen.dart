import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tcs/screens/invoices/invoice_preview_screen.dart';
import 'package:tcs/screens/invoices/create_invoice_screen.dart';
import 'package:tcs/screens/vehicles/add_vehicle_dialog.dart';
import 'package:tcs/widgets/app_popup_menu.dart';
import 'package:tcs/widgets/custom_button.dart';
import 'package:tcs/widgets/delete_confirmation_dialog.dart';

import '../../controllers/customer_controller.dart';
import '../../controllers/vehicle_controller.dart';
import '../../controllers/invoice_controller.dart';

import '../../models/customer_model.dart';
import '../../models/vehicle_model.dart';
import '../../models/invoice_model.dart';

class VehicleDetailScreen extends StatelessWidget {
  final String vehicleId;

  const VehicleDetailScreen({super.key, required this.vehicleId});

  @override
  Widget build(BuildContext context) {
    final vehicleController = Get.find<VehicleController>();
    final customerController = Get.find<CustomerController>();
    final invoiceController = Get.find<InvoiceController>();

    final Vehicle? vehicle = vehicleController.getVehicleById(vehicleId);

    if (vehicle == null) {
      return const Scaffold(body: Center(child: Text("Vehicle not found")));
    }

    final Customer? customer = customerController.getCustomerById(
      vehicle.customerId,
    );

    final List<Invoice> invoices = invoiceController.invoices
        .where((i) => i.vehicleId == vehicle.vehicleId)
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
                  "Vehicle Details",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),

                const Spacer(),

                cButton(
                  () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AddVehicleDialog(vehicle: vehicle);
                      },
                    );
                  },
                  'Edit Vehicle',
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

                        const SizedBox(width: 15),

                        Expanded(
                          child: _statCard(
                            "Customer",
                            customer?.name ?? "-",
                            Icons.person_outline,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // =====================================================
                    // VEHICLE CARD
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
                            vehicle.registrationNumber,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 5),

                          Text(
                            vehicle.vehicleId,
                            style: TextStyle(color: Colors.grey.shade600),
                          ),

                          const SizedBox(height: 25),

                          Row(
                            children: [
                              Expanded(child: _infoTile("Make", vehicle.make)),
                              const SizedBox(width: 15),
                              Expanded(
                                child: _infoTile("Model", vehicle.model),
                              ),
                            ],
                          ),

                          const SizedBox(height: 15),

                          Row(
                            children: [
                              Expanded(
                                child: _infoTile(
                                  "Registration Number",
                                  vehicle.registrationNumber,
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: _infoTile("Fuel Type", vehicle.fuelType),
                              ),
                            ],
                          ),

                          const SizedBox(height: 15),

                          Row(
                            children: [
                              Expanded(
                                child: _infoTile(
                                  "Vehicle Color",
                                  vehicle.vehicleColor ?? "-",
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: _infoTile(
                                  "Engine Number",
                                  vehicle.engineNumber ?? "-",
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 15),

                          Row(
                            children: [
                              Expanded(
                                child: _infoTile(
                                  "Chassis Number",
                                  vehicle.chassisNumber ?? "-",
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: _infoTile(
                                  "Customer",
                                  customer?.name ?? "-",
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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
