import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tcs/controllers/customer_controller.dart';
import 'package:tcs/controllers/invoice_controller.dart';
import 'package:tcs/controllers/payment_controller.dart';
import 'package:tcs/models/payment_model.dart';
import 'package:tcs/screens/invoices/invoice_preview_screen.dart';
import 'package:tcs/utils/responsive.dart';
import 'package:tcs/widgets/adder_button.dart';
import 'package:tcs/widgets/app_popup_menu.dart';
import 'package:tcs/widgets/payment_collection_dialog.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (Responsive.isDesktop(context)) {
      return _buildDesktopPayments();
    }

    return _buildMobilePayments();
  }

  // ---------------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------------
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
      final amount = payment.amount.toString();

      return paymentId.contains(_searchQuery) ||
          invoiceId.contains(_searchQuery) ||
          customerName.contains(_searchQuery) ||
          amount.contains(_searchQuery);
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // DESKTOP
  // ---------------------------------------------------------------------------
  Widget _buildDesktopPayments() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                'Payments',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              adderButton(
                label: 'Collect Payment',
                onPressed: () {
                  PaymentCollectionDialog.show(context: context);
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() => _searchQuery = value.trim().toLowerCase());
            },
            decoration: InputDecoration(
              hintText: 'Search by Payment ID, Invoice ID, Customer, Amount...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: GetBuilder<PaymentController>(
              builder: (_) {
                final payments = _filteredPayments();

                if (payments.isEmpty) {
                  return Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(child: Text('No payments found')),
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
                      showCheckboxColumn: false,
                      columns: const [
                        DataColumn(label: Text('Payment ID')),
                        DataColumn(label: Text('Invoice ID')),
                        DataColumn(label: Text('Customer Name')),
                        DataColumn(label: Text('Amount')),
                        DataColumn(label: Text('Type')),
                        DataColumn(label: Text('Date')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: payments.map((payment) {
                        final customerName =
                            _getCustomerNameForPayment(payment);
                        return DataRow(
                          onSelectChanged: (selected) {
                            if (selected == true) {
                              Get.to(
                                () => InvoicePreviewScreen(
                                  invoiceId: payment.invoiceId,
                                ),
                              );
                            }
                          },
                          cells: [
                            DataCell(
                              Text(
                                payment.paymentId,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            DataCell(Text(payment.invoiceId)),
                            DataCell(Text(customerName)),
                            DataCell(
                              Text(
                                "₹${payment.amount.toStringAsFixed(2)}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            DataCell(Text(payment.mode)),
                            DataCell(
                              Text(
                                "${payment.dateTime.day.toString().padLeft(2, '0')}-"
                                "${payment.dateTime.month.toString().padLeft(2, '0')}-"
                                "${payment.dateTime.year}",
                              ),
                            ),
                            DataCell(
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
                                              onPressed: () =>
                                                  Navigator.pop(ctx, false),
                                              child: const Text(
                                                'Cancel',
                                                style: TextStyle(
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx, true),
                                              child: const Text(
                                                'Delete',
                                                style: TextStyle(
                                                  color: Colors.red,
                                                ),
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

  // ---------------------------------------------------------------------------
  // MOBILE
  // ---------------------------------------------------------------------------
  Widget _buildMobilePayments() {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Column(
          children: [
            _buildMobileHeader(),
            const SizedBox(height: 16),
            _buildMobileSearch(),
            const SizedBox(height: 16),
            Expanded(child: _buildMobilePaymentList()),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileHeader() {
    return const Align(
      alignment: Alignment.centerLeft,
      child: Text(
        'Payments',
        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildMobileSearch() {
    return TextField(
      controller: _searchController,
      onChanged: (value) {
        setState(() => _searchQuery = value.trim().toLowerCase());
      },
      decoration: InputDecoration(
        hintText: 'Search payments...',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }

  Widget _buildMobilePaymentList() {
    return GetBuilder<PaymentController>(
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
    );
  }

  Widget _buildPaymentTile(Payment payment) {
    final customerName = _getCustomerNameForPayment(payment);
    final date =
        "${payment.dateTime.day.toString().padLeft(2, '0')}-"
        "${payment.dateTime.month.toString().padLeft(2, '0')}-"
        "${payment.dateTime.year}";

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(14),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Get.to(
            () => InvoicePreviewScreen(invoiceId: payment.invoiceId),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      payment.paymentId,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      payment.invoiceId,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      customerName,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "$date  •  ${payment.mode}",
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "₹${payment.amount.toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 6),
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
            ],
          ),
        ),
      ),
    );
  }
}