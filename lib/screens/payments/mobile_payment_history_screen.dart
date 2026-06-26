import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tcs/controllers/customer_controller.dart';
import 'package:tcs/controllers/invoice_controller.dart';
import 'package:tcs/controllers/payment_controller.dart';
import 'package:tcs/models/payment_model.dart';
import 'package:tcs/screens/invoices/invoice_preview_screen.dart';
import 'package:tcs/widgets/app_popup_menu.dart';
import 'package:tcs/widgets/erp_mobile_tile.dart';
import 'package:tcs/widgets/payment_collection_dialog.dart';

class MobilePaymentHistoryScreen extends StatefulWidget {
  const MobilePaymentHistoryScreen({super.key});

  @override
  State<MobilePaymentHistoryScreen> createState() =>
      _MobilePaymentHistoryScreenState();
}

class _MobilePaymentHistoryScreenState
    extends State<MobilePaymentHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getCustomerNameForPayment(Payment payment) {
    final invoiceCtrl = Get.find<InvoiceController>();
    final customerCtrl = Get.find<CustomerController>();
    final invoice = invoiceCtrl.getInvoiceById(payment.invoiceId);
    if (invoice == null) return 'Unknown';
    final customer = customerCtrl.getCustomerById(invoice.customerId);
    return customer?.name ?? 'Unknown';
  }

  List<Payment> _filteredPayments() {
    final paymentCtrl = Get.find<PaymentController>();
    if (_searchQuery.isEmpty) return paymentCtrl.allPayments;

    final invoiceCtrl = Get.find<InvoiceController>();
    final customerCtrl = Get.find<CustomerController>();

    return paymentCtrl.allPayments.where((payment) {
      final invoice = invoiceCtrl.getInvoiceById(payment.invoiceId);
      final customer =
          invoice != null
              ? customerCtrl.getCustomerById(invoice.customerId)
              : null;
      final customerName = customer?.name.toLowerCase() ?? '';
      final invoiceId = payment.invoiceId.toLowerCase();
      final paymentId = payment.paymentId.toLowerCase();

      return paymentId.contains(_searchQuery) ||
          invoiceId.contains(_searchQuery) ||
          customerName.contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Payment History',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() => _searchQuery = value.trim().toLowerCase());
                },
                decoration: InputDecoration(
                  hintText: 'Search payments...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GetBuilder<PaymentController>(
                  builder: (_) {
                    final payments = _filteredPayments();
                    if (payments.isEmpty) {
                      return const Center(child: Text('No payments found'));
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.only(bottom: 150),
                      itemCount: payments.length,
                      itemBuilder: (context, index) {
                        return _buildPaymentTile(
                          payments[payments.length - index - 1],
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        label: const Text('Collect Payment'),
        icon: const Icon(Icons.add, size: 20),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        heroTag: null,
        onPressed: () {
          PaymentCollectionDialog.show(context: context);
        },
      ),
    );
  }

  Widget _buildPaymentTile(Payment payment) {
    final customerName = _getCustomerNameForPayment(payment);
    final date =
        "${payment.dateTime.day.toString().padLeft(2, '0')}-"
        "${payment.dateTime.month.toString().padLeft(2, '0')}-"
        "${payment.dateTime.year}";

    return ErpMobileTile(
      onTap: () {
        Get.to(
          () => InvoicePreviewScreen(invoiceId: payment.invoiceId),
        );
      },
      leading: CircleAvatar(
        backgroundColor: Colors.grey.shade100,
        child: const Icon(Icons.payments_outlined, color: Colors.black87),
      ),
      title: payment.paymentId,
      subtitles: [
        payment.invoiceId,
        customerName,
        "$date  •  ${payment.mode}",
      ],
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "₹${payment.amount.toStringAsFixed(2)}",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          AppPopupMenu(
            options: [
              AppPopupMenuOption(
                icon: Icons.receipt_outlined,
                label: 'View Invoice',
                onTap: () {
                  Get.to(
                    () => InvoicePreviewScreen(
                      invoiceId: payment.invoiceId,
                    ),
                  );
                },
              ),
              AppPopupMenuOption(
                icon: Icons.delete_outline,
                label: 'Delete',
                onTap: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: Colors.white,
                      title: const Text('Delete Payment'),
                      content: const Text(
                        'Are you sure you want to delete this payment?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text(
                            'Delete',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    await Get.find<PaymentController>()
                        .deletePayment(payment.paymentId);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}