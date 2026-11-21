import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pdf/pdf.dart';
import 'package:tcs/controllers/payment_controller.dart';
import 'package:tcs/controllers/reminder_controller.dart';
import 'package:tcs/models/reminder_model.dart';
import 'package:tcs/services/invoice_pdf_preview.dart';
import 'package:tcs/services/whatsapp_share.dart';
import 'package:tcs/utils/billing_document_type.dart';
import 'package:tcs/utils/responsive.dart';
import 'package:tcs/widgets/app_popup_menu.dart';
import 'package:tcs/widgets/confirmation_dialog.dart';
import 'package:tcs/widgets/my_snackbar.dart';

import 'package:tcs/widgets/app_titlebar.dart';
import 'package:tcs/widgets/payment_collection_dialog.dart';
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

      final isInvoice = BillingDocumentType.isInvoice(invoice.invoiceId);

      return GetBuilder<ReminderController>(
        builder: (reminderCtrl) {
          final List<Reminder> reminders = reminderCtrl.getRemindersByInvoiceId(
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
                                Text(
                                  "${BillingDocumentType.getLabel(invoice.invoiceId)} Preview",
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 25),
                            Expanded(
                              child: ScrollConfiguration(
                                behavior: ScrollConfiguration.of(
                                  context,
                                ).copyWith(scrollbars: false),
                                child: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _infoField(
                                              "${BillingDocumentType.getShortLabel(invoice.invoiceId)} ID",
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
                                              _formatShortDate(invoice.dueDate),
                                            ),
                                          ),
                                        ],
                                      ),
                                      _infoField(
                                        "Vehicle",
                                        vehicle?.registrationNumber ??
                                            "Unknown",
                                      ),
                                      const SizedBox(height: 25),
                                      if (isInvoice) _paymentHistory(invoice),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.grey.shade300,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
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
                                            _summaryRow(
                                              "Discount",
                                              invoice.discount,
                                            ),
                                            _summaryRow(
                                              "Advance",
                                              invoice.advanceAmount,
                                            ),
                                            if (isInvoice)
                                              _summaryRow(
                                                "Collected",
                                                totalCollected,
                                              ),
                                            const Divider(),
                                            _summaryRow(
                                              isInvoice
                                                  ? "Balance"
                                                  : "Total Amount",
                                              isInvoice
                                                  ? invoice.balanceAmount
                                                  : grandTotal,
                                              bold: true,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      _reminderListCardDesktop(
                                        reminders,
                                        reminderCtrl,
                                      ),
                                      const SizedBox(height: 20),
                                      // === EDIT BUTTON ===
                                      SizedBox(
                                        width: double.infinity,
                                        child: cButton(
                                          () {
                                            Get.to(
                                              () => CreateInvoiceScreen(
                                                invoice: invoice,
                                              ),
                                            );
                                          },
                                          'Edit ${BillingDocumentType.getLabel(invoice.invoiceId)}',
                                          true,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      // === INVOICE-ONLY buttons ===
                                      if (isInvoice) ...[
                                        SizedBox(
                                          width: double.infinity,
                                          child: cButton(
                                            () {
                                              PaymentCollectionDialog.show(
                                                context: context,
                                                initialInvoice: invoice,
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
                                            () {
                                              WhatsappShare.invoicePaymentReminder(
                                                invoice.invoiceId,
                                              );
                                            },
                                            "Send Payment Reminder",
                                            false,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                      ],
                                      // === QUOTATION-ONLY Convert to Invoice ===
                                      if (!isInvoice) ...[
                                        SizedBox(
                                          width: double.infinity,
                                          child: cButton(
                                            () async {
                                              final invoiceCtrl =
                                                  Get.find<InvoiceController>();
                                              final hasBeenConverted =
                                                  invoiceCtrl
                                                      .hasQuotationBeenConverted(
                                                        invoice.invoiceId,
                                                      );
                                              if (hasBeenConverted) {
                                                final confirmed = await showDialog<bool>(
                                                  context: context,
                                                  builder: (_) => ConfirmationDialog(
                                                    icon: Icons.swap_horiz,
                                                    title: "Convert Again?",
                                                    message:
                                                        "An invoice already exists for this quotation.\n\n"
                                                        "Do you want to convert again with a new Invoice ID?",
                                                    confirmLabel: "Confirm",
                                                    cancelLabel: "Cancel",
                                                  ),
                                                );
                                                if (confirmed != true) return;
                                              }
                                              final newId = await invoiceCtrl
                                                  .convertQuotationToInvoice(
                                                    invoice.invoiceId,
                                                  );
                                              if (newId != null) {
                                                if (context.mounted) {
                                                  MySnackbar.show(
                                                    title: "Converted",
                                                    message:
                                                        "Invoice $newId created from quotation",
                                                    type: SnackbarType.success,
                                                    context: context,
                                                  );
                                                  Get.to(
                                                    () => InvoicePreviewScreen(
                                                      invoiceId: newId,
                                                    ),
                                                  );
                                                }
                                              }
                                            },
                                            "Convert to Invoice",
                                            true,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                      ],
                                      // === SHARED PDF buttons ===
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
                                            if (path != null &&
                                                context.mounted) {
                                              MySnackbar.show(
                                                title: 'WhatsApp',
                                                message:
                                                    'PDF copied. Press Ctrl + V in WhatsApp.',
                                                type: SnackbarType.info,
                                                context: context,
                                                duration: const Duration(
                                                  seconds: 6,
                                                ),
                                              );
                                            }
                                          },
                                          'Share via WhatsApp',
                                          false,
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                    ],
                                  ),
                                ),
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

      final isInvoice = BillingDocumentType.isInvoice(invoice.invoiceId);

      return GetBuilder<ReminderController>(
        builder: (reminderCtrl) {
          final List<Reminder> reminders = reminderCtrl.getRemindersByInvoiceId(
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
              title: Text(
                "${BillingDocumentType.getLabel(invoice.invoiceId)} Preview",
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              actions: [
                AppPopupMenu(
                  options: [
                    //edit
                    AppPopupMenuOption(
                      icon: Icons.mode_edit_outline_outlined,
                      label: "Edit",
                      onTap: () {
                        Get.to(() => CreateInvoiceScreen(invoice: invoice));
                      },
                    ),

                    // Invoice-only actions
                    if (isInvoice) ...[
                      AppPopupMenuOption(
                        label: "Collect Payment",
                        icon: Icons.payments_outlined,
                        onTap: () {
                          PaymentCollectionDialog.show(
                            context: context,
                            initialInvoice: invoice,
                          );
                        },
                      ),
                    ],

                    // Quotation-only actions
                    if (!isInvoice) ...[
                      AppPopupMenuOption(
                        icon: Icons.swap_horiz,
                        label: "Convert to Invoice",
                        onTap: () async {
                          final invoiceCtrl = Get.find<InvoiceController>();
                          final hasBeenConverted = invoiceCtrl
                              .hasQuotationBeenConverted(invoice.invoiceId);
                          if (hasBeenConverted) {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (_) => ConfirmationDialog(
                                icon: Icons.swap_horiz,
                                title: "Convert Again?",
                                message:
                                    "An invoice already exists for this quotation.\n\n"
                                    "Do you want to convert again with a new Invoice ID?",
                                confirmLabel: "Confirm",
                                cancelLabel: "Cancel",
                              ),
                            );
                            if (confirmed != true) return;
                          }
                          final newId = await invoiceCtrl
                              .convertQuotationToInvoice(invoice.invoiceId);
                          if (newId != null && context.mounted) {
                            MySnackbar.show(
                              title: "Converted",
                              message: "Invoice $newId created from quotation",
                              type: SnackbarType.success,
                              context: context,
                            );
                            Get.to(
                              () => InvoicePreviewScreen(invoiceId: newId),
                            );
                          }
                        },
                      ),
                    ],

                    //Download PDF
                    AppPopupMenuOption(
                      icon: Icons.sim_card_download_outlined,
                      label: "Download PDF",
                      onTap: () async {
                        try {
                          final path =
                              await InvoicePdfService.downloadInvoicePdfMobile(
                                invoice,
                              );
                          if (path != null) {
                            MySnackbar.show(
                              title: "Downloaded",
                              message:
                                  "${BillingDocumentType.getLabel(invoice.invoiceId)} saved",
                              type: SnackbarType.success,
                              context: context,
                            );
                          }
                        } catch (e) {
                          MySnackbar.show(
                            title: "Error",
                            message: "Failed to download PDF: $e",
                            type: SnackbarType.error,
                            context: context,
                          );
                        }
                      },
                    ),

                    //Share PDF
                    AppPopupMenuOption(
                      icon: Icons.share_outlined,
                      label: "Share PDF",
                      onTap: () async {
                        try {
                          await InvoicePdfService.shareInvoicePdf(
                            invoice,
                            isMobile: true,
                          );
                        } catch (e) {
                          MySnackbar.show(
                            title: "Error",
                            message: "Failed to share PDF: $e",
                            type: SnackbarType.error,
                            context: context,
                          );
                        }
                      },
                    ),

                    //Send Payment Reminder (invoice only)
                    if (isInvoice)
                      AppPopupMenuOption(
                        icon: Icons.notifications_outlined,
                        label: "Send Payment Reminder",
                        onTap: () {
                          WhatsappShare.invoicePaymentReminder(
                            invoice.invoiceId,
                          );
                        },
                      ),
                  ],
                ),
              ],
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

                    _quickInfoCard(
                      customer,
                      vehicle,
                      reminders.isNotEmpty ? reminders.first : null,
                      invoice,
                    ),

                    const SizedBox(height: 15),

                    Listener(
                      onPointerDown: (_) => isInteractingWithPdf.value = true,
                      onPointerUp: (_) => isInteractingWithPdf.value = false,
                      onPointerCancel: (_) =>
                          isInteractingWithPdf.value = false,
                      child: _pdfContainer(invoice),
                    ),

                    const SizedBox(height: 20),

                    // Show reminders card
                    _reminderListCardMobile(reminders, reminderCtrl),

                    const SizedBox(height: 15),

                    if (isInvoice) _paymentHistoryCard(invoice),

                    const SizedBox(height: 15),
                    _financialSummaryCard(
                      subtotal,
                      totalTax,
                      grandTotal,
                      discount,
                      totalCollected,
                      advanceAmount,
                      balanceAmount,
                      isInvoice,
                    ),

                    const SizedBox(height: 15),
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
        _rowItem("Due Date", formatDate(invoice.dueDate)),
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
  bool isInvoice,
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
        if (isInvoice) _summaryRow("Collected", totalCollected),

        const Divider(),
        _summaryRow(
          isInvoice ? "Balance" : "Total Amount",
          isInvoice ? balanceAmount : grandTotal,
          bold: true,
        ),
      ],
    ),
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
                Expanded(
                  child: Text(
                    _formatPaymentDate(p.dateTime),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
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
      ],
    ),
  );
}

// =====================================================
// REMINDERS CARD – DESKTOP
// =====================================================
Widget _reminderListCardDesktop(
  List<Reminder> reminders,
  ReminderController reminderCtrl,
) {
  if (reminders.isEmpty) return const SizedBox.shrink();

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      border: Border.all(color: Colors.grey.shade300),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Reminders",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        ...reminders.map((r) {
          final isOverdue = !r.completed && r.dueDate.isBefore(DateTime.now());
          return Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border.all(
                color: isOverdue ? Colors.red.shade200 : Colors.grey.shade300,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => reminderCtrl.toggleCompleted(r.reminderId),
                  child: Container(
                    width: 20,
                    height: 20,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: r.completed
                            ? Colors.green
                            : Colors.grey.shade400,
                      ),
                      borderRadius: BorderRadius.circular(4),
                      color: r.completed ? Colors.green : Colors.transparent,
                    ),
                    child: r.completed
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : null,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          decoration: r.completed
                              ? TextDecoration.lineThrough
                              : null,
                          color: r.completed ? Colors.grey : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatShortDate(r.dueDate),
                        style: TextStyle(
                          fontSize: 11,
                          color: isOverdue ? Colors.red : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (r.completed)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      "Done",
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ],
    ),
  );
}

// =====================================================
// REMINDERS CARD – MOBILE
// =====================================================
Widget _reminderListCardMobile(
  List<Reminder> reminders,
  ReminderController reminderCtrl,
) {
  if (reminders.isEmpty) return const SizedBox.shrink();

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      border: Border.all(color: Colors.grey.shade300),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Reminders",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        ...reminders.map((r) {
          final isOverdue = !r.completed && r.dueDate.isBefore(DateTime.now());
          return Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border.all(
                color: isOverdue ? Colors.red.shade200 : Colors.grey.shade300,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => reminderCtrl.toggleCompleted(r.reminderId),
                  child: Container(
                    width: 22,
                    height: 22,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: r.completed
                            ? Colors.green
                            : Colors.grey.shade400,
                      ),
                      borderRadius: BorderRadius.circular(4),
                      color: r.completed ? Colors.green : Colors.transparent,
                    ),
                    child: r.completed
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : null,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          decoration: r.completed
                              ? TextDecoration.lineThrough
                              : null,
                          color: r.completed ? Colors.grey : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 2),
                      if (r.notes != null && r.notes!.isNotEmpty)
                        Text(
                          r.notes!,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      Text(
                        _formatShortDate(r.dueDate),
                        style: TextStyle(
                          fontSize: 11,
                          color: isOverdue ? Colors.red : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (r.completed)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      "Done",
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
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
              Expanded(
                child: Text(
                  _formatPaymentDate(p.dateTime),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              SizedBox(
                width: 80,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
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
    ],
  );
}
