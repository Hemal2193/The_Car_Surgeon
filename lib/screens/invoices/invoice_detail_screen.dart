import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/customer_controller.dart';
import '../../controllers/vehicle_controller.dart';
import '../../controllers/item_controller.dart';
import '../../models/invoice_model.dart';
import '../../models/customer_model.dart';
import '../../models/vehicle_model.dart';
import '../../models/item_model.dart';

class InvoiceDetailScreen extends StatelessWidget {
  final Invoice invoice;

  const InvoiceDetailScreen({super.key, required this.invoice});

  @override
  Widget build(BuildContext context) {
    final customerCtrl = Get.find<CustomerController>();
    final vehicleCtrl = Get.find<VehicleController>();
    final itemCtrl = Get.find<ItemController>();

    final Customer? customer = customerCtrl.customers.firstWhereOrNull(
      (c) => c.customerId == invoice.customerId,
    );

    final Vehicle? vehicle = vehicleCtrl.vehicles.firstWhereOrNull(
      (v) => v.vehicleId == invoice.vehicleId,
    );

    double subtotal = 0;
    double totalTax = 0;

    for (var item in invoice.items) {
      subtotal += item.qty * item.rate;
      totalTax += item.taxAmount;
    }

    final grandTotal = subtotal + totalTax;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          // =====================================================
          // LEFT PANEL (ERP DARK STYLE INFO PANEL)
          // =====================================================
          Container(
            width: 320,
            color: Colors.black,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "INVOICE DETAILS",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                _infoTile("Invoice ID", invoice.invoiceId),
                _infoTile("Date", invoice.dateTime.toString()),

                const SizedBox(height: 15),

                _infoTile(
                  "Customer",
                  customer?.name ?? "Unknown",
                ),

                _infoTile(
                  "Vehicle",
                  vehicle?.registrationNumber ?? "Unknown",
                ),

                const SizedBox(height: 30),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 45),
                  ),
                  onPressed: () {
                    // TODO: navigate to edit screen
                  },
                  child: const Text("Edit Invoice"),
                ),

                const SizedBox(height: 10),

                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white),
                    minimumSize: const Size(double.infinity, 45),
                  ),
                  onPressed: () {
                    Get.back();
                  },
                  child: const Text("Back"),
                ),
              ],
            ),
          ),

          // =====================================================
          // RIGHT PANEL (TABLE)
          // =====================================================
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "ITEMS",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 15),

                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SingleChildScrollView(
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text("Sr")),
                            DataColumn(label: Text("Item")),
                            DataColumn(label: Text("HSN")),
                            DataColumn(label: Text("Qty")),
                            DataColumn(label: Text("Rate")),
                            DataColumn(label: Text("GST")),
                            DataColumn(label: Text("Tax")),
                            DataColumn(label: Text("Total")),
                          ],
                          rows: List.generate(invoice.items.length, (i) {
                            final item = invoice.items[i];

                            return DataRow(
                              cells: [
                                DataCell(Text("${i + 1}")),
                                DataCell(Text(item.name)),
                                DataCell(Text(item.hsnSac ?? "-")),
                                DataCell(Text("${item.qty}")),
                                DataCell(Text(item.rate.toString())),
                                DataCell(Text("${item.taxPercent}%")),
                                DataCell(Text(item.taxAmount.toStringAsFixed(2))),
                                DataCell(Text(item.totalAmount.toStringAsFixed(2))),
                              ],
                            );
                          }),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // =====================================================
                  // SUMMARY BAR
                  // =====================================================
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Subtotal + GST",
                          style: TextStyle(color: Colors.white),
                        ),
                        Text(
                          "₹${grandTotal.toStringAsFixed(2)}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
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

  Widget _infoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              )),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}