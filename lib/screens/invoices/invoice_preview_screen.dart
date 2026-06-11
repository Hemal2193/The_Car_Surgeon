import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pdf/pdf.dart';
import 'package:tcs/controllers/reminder_controller.dart';
import 'package:tcs/models/reminder_model.dart';
import 'package:tcs/services/invoice_pdf_preview.dart';
import 'package:tcs/utils/responsive.dart';

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

class InvoicePreviewScreen extends StatefulWidget {
  final String invoiceId;

  const InvoicePreviewScreen({super.key, required this.invoiceId});

  @override
  State<InvoicePreviewScreen> createState() => _InvoicePreviewScreenState();
}

class _InvoicePreviewScreenState extends State<InvoicePreviewScreen> {
  final RxBool isInteractingWithPdf = false.obs;
  @override
  Widget build(BuildContext context) {
    if (Responsive.isDesktop(context)) {
      return _buildDesktopInvoicePreview(context, widget.invoiceId);
    }

    return _buildMobileInvoicePreview(
      context,
      widget.invoiceId,
      isInteractingWithPdf,
    );
  }
}

Widget _buildDesktopInvoicePreview(BuildContext context, String invoiceId) {
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

      final Reminder? reminder = Get.find<ReminderController>()
          .getReminderByInvoiceId(invoice.invoiceId);

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
                      border: Border(
                        right: BorderSide(color: Colors.grey.shade300),
                      ),
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
                            Expanded(
                              child: _infoField(
                                "Invoice ID",
                                invoice.invoiceId,
                              ),
                            ),
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
                        Row(
                          children: [
                            Expanded(
                              child: _infoField(
                                "Customer",
                                customer?.name ?? "Unknown",
                              ),
                            ),
                            Expanded(
                              child: _infoField(
                                "Due Date",
                                "${reminder?.dueDate.day.toString().padLeft(2, '0')}-"
                                    "${reminder?.dueDate.month.toString().padLeft(2, '0')}-"
                                    "${(reminder!.dueDate.year % 100).toString().padLeft(2, '0')}",
                              ),
                            ),
                          ],
                        ),
                        _infoField(
                          "Vehicle",
                          vehicle?.registrationNumber ?? "Unknown",
                        ),
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
                              _summaryRow(
                                "Grand Total",
                                grandTotal,
                                bold: true,
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        SizedBox(
                          width: double.infinity,
                          child: cButton(
                            () {
                              Get.to(
                                () => CreateInvoiceScreen(invoice: invoice),
                              );
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
                              await InvoicePdfService.generateInvoicePdf(
                                invoice,
                              );
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
                        child: InvoicePdfPreview(invoice: invoice),
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

Widget _buildMobileInvoicePreview(
  BuildContext context,
  String invoiceId,
  RxBool isInteractingWithPdf,
) {
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

      final Reminder? reminder = Get.find<ReminderController>()
          .getReminderByInvoiceId(invoice.invoiceId);

      double subtotal = 0;
      double totalTax = 0;

      for (var item in invoice.items) {
        subtotal += item.qty * item.rate;
        totalTax += item.taxAmount;
      }

      final grandTotal = subtotal + totalTax;

      return Scaffold(
        backgroundColor: Colors.white,

        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Get.back(),
          ),
          title: const Text(
            "Invoice Preview",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
        ),

        body: Obx(
          () => SingleChildScrollView(
            physics: isInteractingWithPdf.value
                ? const NeverScrollableScrollPhysics()
                : const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _invoiceHeaderCard(invoice),

                const SizedBox(height: 15),

                _quickInfoCard(customer, vehicle, reminder, invoice),

                const SizedBox(height: 15),

                Listener(
                  onPointerDown: (_) => isInteractingWithPdf.value = true,
                  onPointerUp: (_) => isInteractingWithPdf.value = false,
                  onPointerCancel: (_) => isInteractingWithPdf.value = false,
                  child: _pdfContainer(invoice),
                ),

                const SizedBox(height: 20),

                _financialSummaryCard(subtotal, totalTax, grandTotal),

                const SizedBox(height: 15),

                _actionButtons(invoice),
              ],
            ),
          ),
        ),
      );
    },
  );
}

Widget _invoiceHeaderCard(Invoice invoice) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      border: Border.all(color: Colors.grey.shade300),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          invoice.invoiceId,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          "Date: ${invoice.dateTime.day.toString().padLeft(2, '0')}-"
          "${invoice.dateTime.month.toString().padLeft(2, '0')}-"
          "${invoice.dateTime.year}",
          style: TextStyle(color: Colors.grey.shade700),
        ),
      ],
    ),
  );
}

Widget _quickInfoCard(
  Customer? customer,
  Vehicle? vehicle,
  Reminder? reminder,
  Invoice invoice,
) {
  String formatDate(DateTime? date) {
    if (date == null) return "-";
    return "${date.day.toString().padLeft(2, '0')}-"
        "${date.month.toString().padLeft(2, '0')}-"
        "${date.year}";
  }

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      border: Border.all(color: Colors.grey.shade300),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      children: [
        _rowItem("Customer", customer?.name ?? "-"),
        _rowItem("Vehicle", vehicle?.registrationNumber ?? "-"),
        _rowItem("Due Date", formatDate(reminder?.dueDate)),
      ],
    ),
  );
}

Widget _financialSummaryCard(double subtotal, double tax, double grandTotal) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      border: Border.all(color: Colors.grey.shade300),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      children: [
        _summaryRow("Subtotal", subtotal),
        _summaryRow("Tax", tax),
        const Divider(),
        _summaryRow("Grand Total", grandTotal, bold: true),
      ],
    ),
  );
}

Widget _actionButtons(Invoice invoice) {
  return Column(
    children: [
      cButton(
        () {
          Get.to(() => CreateInvoiceScreen(invoice: invoice));
        },
        "Edit Invoice",
        true,
      ),

      const SizedBox(height: 10),

      cButton(
        () async {
          await InvoicePdfService.generateInvoicePdf(invoice);
        },
        "Download PDF",
        false,
      ),

      // SizedBox(
      //   width: double.infinity,
      //   child: OutlinedButton(
      //     onPressed: () async {
      //       await InvoicePdfService.generateInvoicePdf(invoice);
      //     },
      //     child: const Text("Download PDF"),
      //   ),
      // ),
      const SizedBox(height: 10),

      cButton(
        () async {
          await InvoicePdfService.shareInvoicePdf(invoice);
        },
        "Share PDF",
        false,
      ),
      // SizedBox(
      //   width: double.infinity,
      //   child: OutlinedButton(
      //     onPressed: () async {
      //       await InvoicePdfService.shareInvoicePdf(invoice);
      //     },
      //     child: const Text("Share PDF"),
      //   ),
      // ),
    ],
  );
}

Widget _pdfContainer(Invoice invoice) {
  return AspectRatio(
    aspectRatio: PdfPageFormat.a4.width / PdfPageFormat.a4.height,
    child: Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: InvoicePdfPreview(invoice: invoice),
      // child: PdfPreview(
      //   previewPageMargin: EdgeInsets.zero,
      //   build: (format) => InvoicePdfService.generatePdfBytes(invoice),

      //   maxPageWidth: double.infinity,

      //   canChangeOrientation: false,
      //   canChangePageFormat: false,
      //   allowPrinting: false,
      //   allowSharing: false,

      //   pdfPreviewPageDecoration: const BoxDecoration(color: Colors.white),

      //   initialPageFormat: PdfPageFormat.a4,
      // ),
    ),
  );
}

Widget _rowItem(String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        Expanded(
          child: Text(label, style: TextStyle(color: Colors.grey.shade700)),
        ),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
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
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
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
        Text(
          label,
          style: TextStyle(
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          "Rs. ${value.toStringAsFixed(2)}",
          style: TextStyle(
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    ),
  );
}
