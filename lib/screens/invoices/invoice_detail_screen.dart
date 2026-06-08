import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tcs/controllers/invoice_controller.dart';
import 'package:tcs/screens/invoices/create_invoice_screen.dart';
import 'package:tcs/widgets/app_titlebar.dart';
import 'package:tcs/widgets/custom_button.dart';
import '../../services/invoice_pdf_service.dart';
import '../../controllers/customer_controller.dart';
import '../../controllers/vehicle_controller.dart';
import '../../models/invoice_model.dart';
import '../../models/customer_model.dart';
import '../../models/vehicle_model.dart';

class InvoiceDetailScreen extends StatelessWidget {
  final String invoiceId;

  const InvoiceDetailScreen({super.key, required this.invoiceId});

  @override
  Widget build(BuildContext context) {
    final customerCtrl = Get.find<CustomerController>();
    final vehicleCtrl = Get.find<VehicleController>();

    final Invoice? invoice = Get.find<InvoiceController>().invoices
        .firstWhereOrNull((i) => i.invoiceId == invoiceId);

    final Customer? customer = customerCtrl.customers.firstWhereOrNull(
      (c) => c.customerId == invoice?.customerId,
    );

    final Vehicle? vehicle = vehicleCtrl.vehicles.firstWhereOrNull(
      (v) => v.vehicleId == invoice?.vehicleId,
    );

    double subtotal = 0;
    double totalTax = 0;

    for (var item in invoice?.items ?? []) {
      subtotal += item.qty * item.rate;
      totalTax += item.taxAmount;
    }

    final grandTotal = subtotal + totalTax;

    if (invoice == null) {
      return const Scaffold(body: Center(child: Text("Invoice not found")));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const AppTitleBar(),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // =====================================================
                // LEFT PANEL (MATCH CREATE INVOICE STYLE)
                // =====================================================
                Container(
                  width: 320,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(right: BorderSide(color: Colors.grey.shade300)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: () => Get.back(),
                          ),
                          const SizedBox(width: 5),
                          const Text(
                            "Invoice Details",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 25),
                      Row(
                        children: [
                          _infoField("Invoice ID", invoice.invoiceId),
                          const SizedBox(width: 20),
                          _infoField(
                            "Date",
                            "${invoice.dateTime.day.toString().padLeft(2, '0')}-"
                                "${invoice.dateTime.month.toString().padLeft(2, '0')}-"
                                "${(invoice.dateTime.year % 100).toString().padLeft(2, '0')}",
                          ),
                        ],
                      ),
                      _infoField("Customer", customer?.name ?? "Unknown"),
                      _infoField("Vehicle", vehicle?.registrationNumber ?? "Unknown"),
                      const SizedBox(height: 25),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Summary", style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            _summaryRow("Subtotal", subtotal),
                            _summaryRow("Tax", totalTax),
                            const Divider(),
                            _summaryRow("Grand Total", grandTotal, bold: true),
                          ],
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        child: cButton(
                          () {
                            Get.to(() => CreateInvoiceScreen(invoice: invoice));
                          },
                          'Edit Invoice',
                          true,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: cButton(() => Get.back(), 'Back', false),
                      ),
                    ],
                  ),
                ),
                // =====================================================
                // RIGHT PANEL (TABLE SAME STYLE AS CREATE SCREEN)
                // =====================================================
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Invoice Items",
                              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                            ),
                            cButton(
                              () => InvoicePdfService.generateInvoicePdf(invoice),
                              'Download PDF',
                              true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: SingleChildScrollView(
                              child: DataTable(
                                columns: const [
                                  DataColumn(label: Text("Sr No")),
                                  DataColumn(label: Text("Item")),
                                  DataColumn(label: Text("HSN/SAC")),
                                  DataColumn(label: Text("Qty")),
                                  DataColumn(label: Text("Rate")),
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
                                      DataCell(
                                        Text("${item.taxAmount.toStringAsFixed(2)} (${item.taxPercent}%)"),
                                      ),
                                      DataCell(Text(item.totalAmount.toStringAsFixed(2))),
                                    ],
                                  );
                                }),
                              ),
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
        ],
      ),
    );
  }

  Widget _infoField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, double value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          Text("Rs. ${value.toStringAsFixed(2)}", style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}