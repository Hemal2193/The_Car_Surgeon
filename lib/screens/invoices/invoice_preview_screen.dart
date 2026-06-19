import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pdf/pdf.dart';
import 'package:tcs/controllers/payment_controller.dart';
import 'package:tcs/controllers/reminder_controller.dart';
import 'package:tcs/database/id_generator.dart';
import 'package:tcs/services/supabase_sync_service.dart';
import 'package:tcs/models/payment_model.dart';
import 'package:tcs/models/reminder_model.dart';
import 'package:tcs/services/invoice_pdf_preview.dart';
import 'package:tcs/utils/responsive.dart';

import 'package:tcs/widgets/app_text_field.dart';
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
      final paymentCtrl = Get.find<PaymentController>();

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

      return GetBuilder<ReminderController>(
        builder: (reminderCtrl) {
          final Reminder? reminder = reminderCtrl.getReminderByInvoiceId(
            invoice.invoiceId,
          );

          double subtotal = 0;
          double totalTax = 0;

          for (var item in invoice.items) {
            subtotal += item.qty * item.rate;
            totalTax += item.taxAmount;
          }

          final grandTotal = subtotal + totalTax;

          //total collected payments
          double totalCollected = 0;

          for (var payment in paymentCtrl.allPayments) {
            if (payment.invoiceId == invoice.invoiceId) {
              totalCollected += payment.amount;
            }
          }

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
                        // Wrap the Column in SingleChildScrollView to allow scrolling
                        child: SingleChildScrollView(
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
                                      _formatShortDate(reminder?.dueDate),
                                    ),
                                  ),
                                ],
                              ),
                              _infoField(
                                "Vehicle",
                                vehicle?.registrationNumber ?? "Unknown",
                              ),
                              const SizedBox(height: 25),
                              _paymentHistory(invoice),

                              // SPACER REPLACED: SingleChildScrollView needs fixed spacing, not Spacers
                              // const SizedBox(height: 20),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  children: [
                                    _summaryRow("Subtotal", subtotal),
                                    _summaryRow("Tax", totalTax),
                                    _summaryRow(
                                      "Grand Total",
                                      grandTotal,
                                      bold: true,
                                    ),
                                    const Divider(),

                                    _summaryRow("Discount", invoice.discount),
                                    _summaryRow(
                                      "Advance",
                                      invoice.advanceAmount,
                                    ),
                                    _summaryRow("Collected", totalCollected),

                                    const Divider(),
                                    _summaryRow(
                                      "Balance",
                                      invoice.balanceAmount,
                                      bold: true,
                                    ),
                                  ],
                                ),
                              ),

                              // SPACER REPLACED
                              const SizedBox(height: 20),

                              SizedBox(
                                width: double.infinity,
                                child: cButton(
                                  () {
                                    Get.to(
                                      () =>
                                          CreateInvoiceScreen(invoice: invoice),
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
                                  () {
                                    _showPaymentCollectionDialog(
                                      context,
                                      invoice,
                                    );
                                  },
                                  'Collect Payment',
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
                                    final path =
                                        await InvoicePdfService.shareInvoiceViaWhatsApp(
                                          invoice,
                                          customer,
                                        );
                                    if (path != null && context.mounted) {
                                      Get.snackbar(
                                        'WhatsApp',
                                        'PDF copied. Press Ctrl + V in WhatsApp.',
                                        snackPosition: SnackPosition.BOTTOM,
                                        duration: const Duration(seconds: 6),
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 20,
                                        ),
                                      );
                                    }
                                  },
                                  'Share via WhatsApp',
                                  false,
                                ),
                              ),
                            ],
                          ),
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
      final paymentCtrl = Get.find<PaymentController>();

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

      return GetBuilder<ReminderController>(
        builder: (reminderCtrl) {
          final Reminder? reminder = reminderCtrl.getReminderByInvoiceId(
            invoice.invoiceId,
          );

          double subtotal = 0;
          double totalTax = 0;

          for (var item in invoice.items) {
            subtotal += item.qty * item.rate;
            totalTax += item.taxAmount;
          }

          final grandTotal = invoice.grandTotal;
          final advanceAmount = invoice.advanceAmount;
          final balanceAmount = invoice.balanceAmount;
          final discount = invoice.discount;
          double totalCollected = 0.0;

          final payments = paymentCtrl.getPaymentsByInvoiceId(
            invoice.invoiceId,
          );
          if (payments.isNotEmpty) {
            totalCollected = payments.fold<double>(
              0,
              (sum, p) => sum + p.amount,
            );
          }

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
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
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
                      onPointerCancel: (_) =>
                          isInteractingWithPdf.value = false,
                      child: _pdfContainer(invoice),
                    ),

                    const SizedBox(height: 20),

                    _paymentHistoryCard(invoice),

                    const SizedBox(height: 15),

                    _financialSummaryCard(
                      subtotal,
                      totalTax,
                      grandTotal,
                      discount,
                      totalCollected,
                      advanceAmount,
                      balanceAmount,
                    ),

                    const SizedBox(height: 15),

                    _actionButtons(context, invoice),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

String _formatShortDate(DateTime? date) {
  if (date == null) return "-";

  return "${date.day.toString().padLeft(2, '0')}-"
      "${date.month.toString().padLeft(2, '0')}-"
      "${(date.year % 100).toString().padLeft(2, '0')}";
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

Widget _financialSummaryCard(
  double subtotal,
  double tax,
  double grandTotal,
  double discount,
  double totalCollected,
  double advanceAmount,
  double balanceAmount,
) {
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
        _summaryRow("Grand Total", grandTotal, bold: true),
        const Divider(),

        _summaryRow("Discount", discount),
        _summaryRow("Advance", advanceAmount),
        _summaryRow("Collected", totalCollected),

        const Divider(),
        _summaryRow("Balance", balanceAmount, bold: true),
      ],
    ),
  );
}

Widget _actionButtons(BuildContext context, Invoice invoice) {
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
        () {
          _showPaymentCollectionDialog(context, invoice);
        },
        "Collect Payment",
        true,
      ),

      const SizedBox(height: 10),

      cButton(
        () async {
          try {
            final path = await InvoicePdfService.downloadInvoicePdfMobile(
              invoice,
            );
            if (path != null) {
              Get.snackbar(
                margin: EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                "Downloaded",
                "Invoice saved to Downloads/TCS/${invoice.invoiceId}.pdf",
                snackPosition: SnackPosition.BOTTOM,
              );
            }
          } catch (e) {
            Get.snackbar(
              "Error",
              "Failed to download PDF: $e",
              snackPosition: SnackPosition.BOTTOM,
            );
          }
        },
        "Download PDF",
        false,
      ),

      const SizedBox(height: 10),

      cButton(
        () async {
          try {
            await InvoicePdfService.shareInvoicePdf(invoice, isMobile: true);
          } catch (e) {
            Get.snackbar(
              "Error",
              "Failed to share PDF: $e",
              snackPosition: SnackPosition.BOTTOM,
            );
          }
        },
        "Share PDF",
        false,
      ),
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

String _formatPaymentDate(DateTime date) {
  return "${date.day.toString().padLeft(2, '0')}-"
      "${date.month.toString().padLeft(2, '0')}-"
      "${(date.year % 100).toString().padLeft(2, '0')}";
}

// =====================================================
// PAYMENT HISTORY – DESKTOP
// =====================================================
Widget _paymentHistory(Invoice invoice) {
  final payments = Get.find<PaymentController>().getPaymentsByInvoiceId(
    invoice.invoiceId,
  );

  if (payments.isEmpty) {
    return const SizedBox.shrink();
  }

  return Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Payment History",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        ...payments.map((p) {
          return Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                // 1. Expanded or Flexible takes all available space on the left
                Expanded(
                  child: Text(
                    _formatPaymentDate(p.dateTime),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),

                // 2. Use SizedBox with a fixed width for the Amount/Mode section
                SizedBox(
                  width:
                      80, // Adjust this width based on your max expected amount length
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.end, // Align text to the right
                    children: [
                      Text(
                        "₹${p.amount.toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          p.mode,
                          style: const TextStyle(
                            fontSize: 9,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
        //total payment collected(sum of all the collected payments for the invoice)
        // Row(
        //   mainAxisAlignment: MainAxisAlignment.end,
        //   children: [
        //     Text(
        //       "Total Payment Collected: Rs. ${payments.fold<double>(0, (sum, p) => sum + p.amount)}",
        //       style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        //     ),
        //   ],
        // ),
      ],
    ),
  );
}

// =====================================================
// PAYMENT HISTORY – MOBILE
// =====================================================
Widget _paymentHistoryCard(Invoice invoice) {
  final payments = Get.find<PaymentController>().getPaymentsByInvoiceId(
    invoice.invoiceId,
  );

  if (payments.isEmpty) {
    return const SizedBox.shrink();
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        "Payment History",
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
      const SizedBox(height: 8),
      ...payments.map((p) {
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              // 1. Expanded or Flexible takes all available space on the left
              Expanded(
                child: Text(
                  _formatPaymentDate(p.dateTime),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),

              // 2. Use SizedBox with a fixed width for the Amount/Mode section
              SizedBox(
                width:
                    80, // Adjust this width based on your max expected amount length
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.end, // Align text to the right
                  children: [
                    Text(
                      "₹${p.amount.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        p.mode,
                        style: const TextStyle(
                          fontSize: 9,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
      //total payment collected(sum of all the collected payments for the invoice)
      // Row(
      //   mainAxisAlignment: MainAxisAlignment.end,
      //   children: [
      //     Text(
      //       "Total Payment Collected: Rs. ${payments.fold<double>(0, (sum, p) => sum + p.amount)}",
      //       style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      //     ),
      //   ],
      // ),
    ],
  );
}

void _showPaymentCollectionDialog(BuildContext context, Invoice invoice) {
  final paymentCtrl = Get.find<PaymentController>();
  final invoiceCtrl = Get.find<InvoiceController>();

  final amountController = TextEditingController();
  final notesController = TextEditingController();
  String selectedMode = 'Cash';
  DateTime paymentDate = DateTime.now();

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          final isDesktop = MediaQuery.of(context).size.width > 700;

          double totalCollected = 0.0;

          final payments = paymentCtrl.getPaymentsByInvoiceId(
            invoice.invoiceId,
          );
          if (payments.isNotEmpty) {
            totalCollected = payments.fold<double>(
              0,
              (sum, p) => sum + p.amount,
            );
          }

          return Dialog(
            backgroundColor: Colors.white,
            insetPadding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 24 : 16,
              vertical: 24,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isDesktop ? 500 : double.infinity,
                maxHeight: 700,
              ),
              child: ScrollConfiguration(
                behavior: const ScrollBehavior().copyWith(scrollbars: false),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(isDesktop ? 20 : 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ---------------- HEADER ----------------
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Collect Payment",
                              style: TextStyle(
                                fontSize: isDesktop ? 20 : 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // ---------------- PAYMENT SUMMARY ----------------
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Invoice: ${invoice.invoiceId}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),

                              Text(
                                "Grand Total: ₹${invoice.grandTotal.toStringAsFixed(2)}",
                              ),

                              const SizedBox(height: 4),

                              Text(
                                "Advance: ₹${invoice.advanceAmount.toStringAsFixed(2)}",
                              ),

                              const SizedBox(height: 4),

                              Text(
                                "Discount: ₹${invoice.discount.toStringAsFixed(2)}",
                              ),
                              const SizedBox(height: 4),

                              Text(
                                "Collected: ₹${totalCollected.toStringAsFixed(2)}",
                              ),

                              const Divider(height: 20),

                              Text(
                                "Balance: ₹${(invoice.balanceAmount).toStringAsFixed(2)}",

                                // "Balance: ₹${(invoice.grandTotal - invoice.advanceAmount).toStringAsFixed(2)}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ---------------- AMOUNT ----------------
                        Row(
                          children: [
                            const Text(
                              "Payment Amount",
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            SizedBox(width: 10),
                            InkWell(
                              onTap: () {
                                amountController.text = invoice.balanceAmount
                                    .toStringAsFixed(2);
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey.shade400,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Padding(
                                  padding: EdgeInsetsGeometry.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  child: Text(
                                    "Full Payment",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        AppTextField(
                          hintText: "Enter payment amount",
                          controller: amountController,
                          keyboardType: TextInputType.number,
                        ),

                        const SizedBox(height: 16),

                        // ---------------- PAYMENT MODE ----------------
                        const Text(
                          "Payment Mode",
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),

                        const SizedBox(height: 8),

                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedMode,
                              isExpanded: true,
                              items: const [
                                DropdownMenuItem(
                                  value: 'Cash',
                                  child: Text('Cash'),
                                ),
                                DropdownMenuItem(
                                  value: 'UPI',
                                  child: Text('UPI'),
                                ),
                                DropdownMenuItem(
                                  value: 'Bank Transfer',
                                  child: Text('Bank Transfer'),
                                ),
                                DropdownMenuItem(
                                  value: 'Cheque',
                                  child: Text('Cheque'),
                                ),
                                DropdownMenuItem(
                                  value: 'Card',
                                  child: Text('Card'),
                                ),
                                DropdownMenuItem(
                                  value: 'Net Banking',
                                  child: Text('Net Banking'),
                                ),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setDialogState(() {
                                    selectedMode = value;
                                  });
                                }
                              },
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ---------------- DATE ----------------
                        const Text(
                          "Payment Date",
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),

                        const SizedBox(height: 8),

                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: paymentDate,
                              firstDate: DateTime.now().subtract(
                                const Duration(days: 30),
                              ),
                              lastDate: DateTime.now(),
                            );

                            if (picked != null) {
                              setDialogState(() {
                                paymentDate = picked;
                              });
                            }
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "${paymentDate.day.toString().padLeft(2, '0')}-${paymentDate.month.toString().padLeft(2, '0')}-${paymentDate.year}",
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ---------------- NOTES ----------------
                        const Text(
                          "Notes",
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),

                        const SizedBox(height: 8),

                        AppTextField(
                          hintText: "Notes (optional)",
                          controller: notesController,
                          maxLines: 2,
                        ),

                        const SizedBox(height: 24),

                        // ---------------- ACTION BUTTONS ----------------
                        Row(
                          children: [
                            Expanded(
                              child: cButton(
                                () {
                                  Navigator.pop(context);
                                },
                                "Cancel",
                                false,
                              ),
                            ),

                            const SizedBox(width: 12),

                            Expanded(
                              child: cButton(
                                () async {
                                  final amount = double.tryParse(
                                    amountController.text,
                                  );

                                  if (amount == null || amount <= 0) {
                                    Get.snackbar(
                                      "Error",
                                      "Please enter a valid amount",
                                      snackPosition: SnackPosition.BOTTOM,
                                    );
                                    return;
                                  }

                                  final payment = Payment(
                                    paymentId: IdGenerator.generatePaymentId(),
                                    invoiceId: invoice.invoiceId,
                                    dateTime: paymentDate,
                                    mode: selectedMode,
                                    amount: amount,
                                    notes: notesController.text.trim().isEmpty
                                        ? null
                                        : notesController.text.trim(),
                                  );

                                  await paymentCtrl.addPayment(payment);

                                  Get.find<SupabaseSyncService>().syncPayments();

                                  invoiceCtrl.updateInvoicePaymentStatus(
                                    invoice.invoiceId,
                                  );

                                  if (context.mounted) {
                                    Navigator.pop(context);
                                  }

                                  Get.snackbar(
                                    "Success",
                                    "Payment collected successfully",
                                    snackPosition: SnackPosition.BOTTOM,
                                  );
                                },
                                "Collect",
                                true,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
