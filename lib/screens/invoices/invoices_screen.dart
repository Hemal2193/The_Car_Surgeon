import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tcs/screens/invoices/create_invoice_screen.dart';

import '../../controllers/invoice_controller.dart';
import '../../controllers/customer_controller.dart';
import '../../controllers/vehicle_controller.dart';

import '../../widgets/adder_button.dart';
import '../../widgets/app_popup_menu.dart';
import '../../widgets/delete_confirmation_dialog.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String formatDate(DateTime dt) {
    String day = dt.day.toString().padLeft(2, '0');
    String month = dt.month.toString().padLeft(2, '0');
    // Extracts the last 2 digits of the year
    String year = (dt.year % 100).toString().padLeft(2, '0');

    return "$day-$month-$year";
  }

  bool matchesSearch(inv, CustomerController cc) {
    final q = searchQuery.toLowerCase();

    final customerName =
        cc.getCustomerById(inv.customerId)?.name.toLowerCase() ?? "";

    return inv.invoiceId.toLowerCase().contains(q) ||
        customerName.contains(q) ||
        inv.dateTime.toString().toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          /// HEADER
          Row(
            children: [
              const Text(
                "Invoices",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              adderButton(
                label: "Create Invoice",
                onPressed: () {
                  Get.to(() => const CreateInvoiceScreen());
                },
              ),
            ],
          ),

          const SizedBox(height: 20),

          /// SEARCH
          TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() => searchQuery = value);
            },
            decoration: InputDecoration(
              hintText: 'Search invoice...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),

          const SizedBox(height: 20),

          /// TABLE
          Expanded(
            child: GetBuilder<InvoiceController>(
              builder: (invoiceController) {
                final customerController = Get.find<CustomerController>();
                final vehicleController = Get.find<VehicleController>();

                final invoices = invoiceController.invoices
                    .where((inv) => matchesSearch(inv, customerController))
                    .toList();

                if (invoices.isEmpty) {
                  return Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(child: Text("No invoices found")),
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
                        DataColumn(label: Text("Invoice ID")),
                        DataColumn(label: Text("Date")),
                        DataColumn(label: Text("Customer")),
                        DataColumn(label: Text("Vehicle")),
                        DataColumn(label: Text("Items")),
                        DataColumn(label: Text("Tax")),
                        DataColumn(label: Text("Grand Total")),
                        DataColumn(label: Text("Actions")),
                      ],
                      rows: invoices.map((inv) {
                        final customer = customerController.getCustomerById(
                          inv.customerId,
                        );

                        final vehicle = vehicleController.getVehicleById(
                          inv.vehicleId,
                        );

                        final customerName = customer?.name ?? "Unknown";
                        final vehicleReg =
                            vehicle?.registrationNumber ?? "Unknown";

                        final itemsCount = inv.items.length;

                        final totalTax = inv.items.fold<double>(
                          0,
                          (sum, item) => sum + item.taxAmount,
                        );

                        return DataRow(
                          cells: [
                            DataCell(
                              Text(
                                inv.invoiceId,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),

                            DataCell(Text(formatDate(inv.dateTime))),

                            DataCell(Text(customerName)),

                            DataCell(Text(vehicleReg)),

                            DataCell(Text(itemsCount.toString())),

                            DataCell(Text(totalTax.toStringAsFixed(2))),

                            DataCell(Text(inv.grandTotal.toStringAsFixed(2))),

                            DataCell(
                              AppPopupMenu(
                                onEdit: () {
                                  // later edit screen
                                },
                                onDelete: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => DeleteConfirmationDialog(
                                      title: "Delete Invoice",
                                      message:
                                          "Are you sure you want to delete ${inv.invoiceId}?",
                                      onDelete: () async {
                                        await invoiceController.deleteInvoice(
                                          inv.invoiceId,
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
