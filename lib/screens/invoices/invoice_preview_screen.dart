import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:printing/printing.dart';

import 'package:tcs/widgets/app_titlebar.dart';
import '../../controllers/customer_controller.dart';
import '../../controllers/invoice_controller.dart';
import '../../controllers/vehicle_controller.dart';

import '../../models/customer_model.dart';
import '../../models/invoice_model.dart';
import '../../models/vehicle_model.dart';

import '../../services/invoice_pdf_service.dart';

import '../../widgets/custom_button.dart';

import 'create_invoice_screen.dart';

class InvoicePreviewScreen extends StatelessWidget {
  final String invoiceId;

  const InvoicePreviewScreen({super.key, required this.invoiceId});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<InvoiceController>(
      builder: (invoiceController) {
        final customerCtrl = Get.find<CustomerController>();
        final vehicleCtrl = Get.find<VehicleController>();

        final Invoice? invoice = invoiceController.invoices.firstWhereOrNull(
          (i) => i.invoiceId == invoiceId,
        );

        if (invoice == null) {
          return const Scaffold(body: Center(child: Text("Invoice not found")));
        }

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
          body: Column(
            children: [
              const AppTitleBar(),
              Expanded(
                child: Row(
                  children: [
                    // =====================================================
                    // LEFT PANEL
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
                                "Invoice Preview",
                                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 25),
                          Row(
                            children: [
                              Expanded(child: _infoField("Invoice ID", invoice.invoiceId)),
                              Expanded(
                                child: _infoField(
                                  "Date",
                                  "${invoice.dateTime.day.toString().padLeft(2, '0')}-"
                                      "${invoice.dateTime.month.toString().padLeft(2, '0')}-"
                                      "${(invoice.dateTime.year % 100).toString().padLeft(2, '0')}",
                                ),
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
                              children: [
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
                            child: cButton(
                              () async {
                                await InvoicePdfService.generateInvoicePdf(invoice);
                              },
                              'Download PDF',
                              false,
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: cButton(
                              () async {
                                await InvoicePdfService.shareInvoicePdf(invoice);
                              },
                              'Share PDF',
                              false,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // =====================================================
                    // RIGHT PANEL
                    // =====================================================
                    Expanded(
                      child: Container(
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: PdfPreview(
                            pdfPreviewPageDecoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            canChangeOrientation: false,
                            canChangePageFormat: false,
                            allowPrinting: false,
                            allowSharing: false,
                            build: (format) => InvoicePdfService.generatePdfBytes(invoice),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget _infoField(String label, String value) {
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

  static Widget _summaryRow(String label, double value, {bool bold = false}) {
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