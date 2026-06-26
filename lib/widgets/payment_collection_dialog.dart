import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tcs/controllers/customer_controller.dart';
import 'package:tcs/controllers/invoice_controller.dart';
import 'package:tcs/controllers/payment_controller.dart';
import 'package:tcs/controllers/vehicle_controller.dart';
import 'package:tcs/database/id_generator.dart';
import 'package:tcs/models/invoice_model.dart';
import 'package:tcs/models/payment_model.dart';
import 'package:tcs/services/supabase_sync_service.dart';

import 'app_text_field.dart';
import 'custom_button.dart';

/// A reusable payment collection dialog.
///
/// [initialInvoice] – when provided (inside an invoice), the dialog shows
/// payment summary directly without a search bar.
///
/// When [initialInvoice] is null (outside an invoice), a search bar appears
/// so the user can find an invoice by customer name, registration number,
/// invoice ID, or phone number. Payment summary is hidden until a result is selected.
class PaymentCollectionDialog extends StatefulWidget {
  final Invoice? initialInvoice;

  const PaymentCollectionDialog({
    super.key,
    this.initialInvoice,
  });

  /// Convenience method to show the dialog.
  static Future<void> show({
    required BuildContext context,
    Invoice? initialInvoice,
  }) {
    return showDialog(
      context: context,
      builder: (_) => PaymentCollectionDialog(
        initialInvoice: initialInvoice,
      ),
    );
  }

  @override
  State<PaymentCollectionDialog> createState() =>
      _PaymentCollectionDialogState();
}

class _PaymentCollectionDialogState extends State<PaymentCollectionDialog> {
  final paymentCtrl = Get.find<PaymentController>();
  final invoiceCtrl = Get.find<InvoiceController>();
  final customerCtrl = Get.find<CustomerController>();
  final vehicleCtrl = Get.find<VehicleController>();

  final amountController = TextEditingController();
  final notesController = TextEditingController();
  final searchController = TextEditingController();
  String selectedMode = 'Cash';
  DateTime paymentDate = DateTime.now();

  Invoice? _selectedInvoice;

  /// Search results built from all invoices (used when initialInvoice is null)
  List<_SearchResult> _allResults = [];
  List<_SearchResult> _filteredResults = [];
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialInvoice != null) {
      _selectedInvoice = widget.initialInvoice;
    } else {
      _buildSearchIndex();
    }
  }

  @override
  void dispose() {
    amountController.dispose();
    notesController.dispose();
    searchController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Search index
  // ---------------------------------------------------------------------------
  void _buildSearchIndex() {
    final invoices = invoiceCtrl.invoices;
    final results = <_SearchResult>[];

    for (final inv in invoices) {
      final customer = customerCtrl.getCustomerById(inv.customerId);
      final vehicle = vehicleCtrl.getVehicleById(inv.vehicleId);

      results.add(_SearchResult(
        invoice: inv,
        customerName: customer?.name ?? 'Unknown',
        registrationNumber: vehicle?.registrationNumber ?? 'Unknown',
        phone: customer?.contact1 ?? '',
        invoiceId: inv.invoiceId,
      ));
    }

    _allResults = results;
  }

  void _onSearchChanged(String query) {
    setState(() {
      _hasSearched = query.trim().isNotEmpty;
      if (query.trim().isEmpty) {
        _filteredResults = [];
        return;
      }

      final q = query.trim().toLowerCase();
      _filteredResults = _allResults.where((r) {
        return r.customerName.toLowerCase().contains(q) ||
            r.registrationNumber.toLowerCase().contains(q) ||
            r.invoiceId.toLowerCase().contains(q) ||
            r.phone.contains(q);
      }).toList();
    });
  }

  void _selectResult(_SearchResult result) {
    setState(() {
      _selectedInvoice = result.invoice;
      _filteredResults = [];
      _hasSearched = false;
      searchController.clear();
    });
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 700;
    final hasInvoice = _selectedInvoice != null;
    final invoice = _selectedInvoice;

    double totalCollected = 0.0;
    if (invoice != null) {
      final payments = paymentCtrl.getPaymentsByInvoiceId(invoice.invoiceId);
      if (payments.isNotEmpty) {
        totalCollected = payments.fold<double>(0, (sum, p) => sum + p.amount);
      }
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
                  // ==========================================================
                  // HEADER
                  // ==========================================================
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

                  // ==========================================================
                  // SEARCH BAR (only when no initial invoice)
                  // ==========================================================
                  if (widget.initialInvoice == null) ...[
                    AppTextField(
                      hintText:
                          "Search by Name, Invoice ID, Reg No, Phone...",
                      controller: searchController,
                      onChanged: _onSearchChanged,
                    ),

                    const SizedBox(height: 12),

                    // ---- Search results list ----
                    if (_filteredResults.isNotEmpty)
                      Container(
                        constraints: const BoxConstraints(maxHeight: 220),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          itemCount: _filteredResults.length,
                          separatorBuilder: (_, _) =>
                              Divider(height: 1, color: Colors.grey.shade200),
                          itemBuilder: (context, index) {
                            final r = _filteredResults[index];
                            final balanceText = r.invoice.balanceAmount > 0
                                ? 'Due'
                                : 'Paid';
                            return InkWell(
                              onTap: () => _selectResult(r),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            r.invoiceId,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            "${r.registrationNumber}  ${r.customerName}",
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          "₹${r.invoice.grandTotal.toStringAsFixed(0)}",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: r.invoice.balanceAmount > 0
                                                ? Colors.black
                                                : Colors.green,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            balanceText,
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Colors.white,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                    if (_hasSearched && _filteredResults.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: Text(
                            "No invoices found",
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ),
                      ),

                    const SizedBox(height: 12),

                    // Show a divider when no invoice selected yet
                    if (!hasInvoice) const Divider(),
                  ],

                  // ==========================================================
                  // PAYMENT SUMMARY (shown only when an invoice is selected)
                  // ==========================================================
                  if (hasInvoice)
                    _buildPaymentSummary(invoice!, totalCollected),

                  const SizedBox(height: 20),

                  // ==========================================================
                  // FORM FIELDS (only when invoice selected)
                  // ==========================================================
                  if (hasInvoice) ...[
                    // ---- AMOUNT ----
                    Row(
                      children: [
                        const Text(
                          "Payment Amount",
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(width: 10),
                        InkWell(
                          onTap: () {
                            amountController.text = invoice!.balanceAmount
                                .toStringAsFixed(2);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
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

                    // ---- PAYMENT MODE ----
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
                              setState(() {
                                selectedMode = value;
                              });
                            }
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ---- DATE ----
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
                          firstDate:
                              DateTime.now().subtract(const Duration(days: 30)),
                          lastDate: DateTime.now(),
                        );

                        if (picked != null) {
                          setState(() {
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
                          "${paymentDate.day.toString().padLeft(2, '0')}-"
                          "${paymentDate.month.toString().padLeft(2, '0')}-"
                          "${paymentDate.year}",
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ---- NOTES ----
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

                    // ---- ACTION BUTTONS ----
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
                                invoiceId: invoice!.invoiceId,
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentSummary(Invoice invoice, double totalCollected) {
    return Container(
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
            style: const TextStyle(fontWeight: FontWeight.w600),
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
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

/// Internal model for search results.
class _SearchResult {
  final Invoice invoice;
  final String customerName;
  final String registrationNumber;
  final String phone;
  final String invoiceId;

  _SearchResult({
    required this.invoice,
    required this.customerName,
    required this.registrationNumber,
    required this.phone,
    required this.invoiceId,
  });
}