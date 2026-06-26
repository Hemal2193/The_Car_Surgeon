import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:tcs/models/invoice_model.dart';
import 'package:tcs/models/invoice_payment_status.dart';
import 'package:tcs/screens/invoices/create_invoice_screen.dart';
import 'package:tcs/screens/invoices/invoice_preview_screen.dart';
import 'package:tcs/services/whatsapp_share.dart';
import 'package:tcs/utils/responsive.dart';
import 'package:tcs/widgets/erp_mobile_tile.dart';

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
  String _searchQuery = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String formatDate(DateTime dt) {
    String day = dt.day.toString().padLeft(2, '0');
    String month = dt.month.toString().padLeft(2, '0');
    String year = (dt.year % 100).toString().padLeft(2, '0');
    return "$day-$month-$year";
  }

  bool matchesSearch(Invoice inv, CustomerController cc) {
    if (_searchQuery.isEmpty) return true;
    final q = _searchQuery.toLowerCase();
    final customerName =
        cc.getCustomerById(inv.customerId)?.name.toLowerCase() ?? "";
    return inv.invoiceId.toLowerCase().contains(q) ||
        customerName.contains(q) ||
        inv.dateTime.toString().toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isAndroid || Platform.isIOS) {
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.white,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
      );
    }
    if (Responsive.isDesktop(context)) {
      return _buildDesktopInvoices();
    }
    return _buildMobileInvoices();
  }

  Widget _buildDesktopInvoices() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
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
          TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() => _searchQuery = value.trim().toLowerCase());
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
          Expanded(
            child: GetBuilder<CustomerController>(
              builder: (customerController) {
                return GetBuilder<VehicleController>(
                  builder: (vehicleController) {
                    return GetBuilder<InvoiceController>(
                      builder: (invoiceController) {
                        final invoices = invoiceController.invoices
                            .where(
                              (inv) => matchesSearch(inv, customerController),
                            )
                            .toList();

                        if (invoices.isEmpty) {
                          return Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(
                              child: Text("No invoices found"),
                            ),
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
                              columnSpacing: 40,
                              columns: const [
                                DataColumn(label: Text("Invoice ID")),
                                DataColumn(label: Text("Date")),
                                DataColumn(label: Text("Customer")),
                                DataColumn(label: Text("Vehicle")),
                                DataColumn(label: Text("Items")),
                                DataColumn(label: Text("Balance")),
                                DataColumn(label: Text("Status")),
                                DataColumn(label: Text("Actions")),
                              ],
                              rows: invoices.map((inv) {
                                final customer = customerController
                                    .getCustomerById(inv.customerId);
                                final vehicle = vehicleController
                                    .getVehicleById(inv.vehicleId);
                                final customerName =
                                    customer?.name ?? "Unknown";
                                final vehicleReg =
                                    vehicle?.registrationNumber ?? "Unknown";
                                final itemsCount = inv.items.length;

                                return DataRow(
                                  onSelectChanged: (selected) {
                                    if (selected == true) {
                                      Get.to(
                                        () => InvoicePreviewScreen(
                                          invoiceId: inv.invoiceId,
                                        ),
                                      );
                                    }
                                  },
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
                                    DataCell(
                                      Text(
                                        inv.balanceAmount.toStringAsFixed(2),
                                      ),
                                    ),
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: inv.paymentStatus.color
                                              .withOpacity(0.1),

                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          inv.paymentStatus.label,
                                          style: TextStyle(
                                            color: inv.paymentStatus.color,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      AppPopupMenu(
                                        options: [
                                          AppPopupMenuOption(
                                            icon: Icons.edit_outlined,
                                            label: 'Edit',
                                            onTap: () {
                                              Get.to(
                                                () => CreateInvoiceScreen(
                                                  invoice: inv,
                                                ),
                                              );
                                            },
                                          ),

                                          AppPopupMenuOption(
                                            icon: Icons.delete_outline,
                                            label: 'Delete',
                                            onTap: () {
                                              showDialog(
                                                context: context,
                                                builder: (_) =>
                                                    DeleteConfirmationDialog(
                                                      title: "Delete Invoice",
                                                      message:
                                                          "Are you sure you want to delete ${inv.invoiceId}?",
                                                      onDelete: () async {
                                                        await invoiceController
                                                            .deleteInvoice(
                                                              inv.invoiceId,
                                                            );
                                                      },
                                                    ),
                                              );
                                            },
                                          ),
                                          AppPopupMenuOption(
                                            icon: Icons.share_outlined,
                                            label: "Send Payment Reminder",
                                            onTap: () {
                                              WhatsappShare.invoicePaymentReminder(
                                                inv.invoiceId,
                                              );
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
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // MOBILE
  // ================================================================

  Widget _buildMobileInvoices() {
    return SafeArea(
      bottom: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            children: [
              _buildMobileHeader(),
              const SizedBox(height: 16),
              _buildSearch(),
              const SizedBox(height: 16),
              Expanded(child: _buildMobileInvoiceList()),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Get.to(() => const CreateInvoiceScreen());
          },
          label: const Text("Create Invoice"),
          icon: const Icon(Icons.add),
          heroTag: null,
        ),
      ),
    );
  }

  Widget _buildMobileHeader() {
    return const Align(
      alignment: Alignment.centerLeft,
      child: Text(
        'Invoices',
        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildSearch() {
    return TextField(
      controller: _searchController,
      onChanged: (value) {
        setState(() => _searchQuery = value.trim().toLowerCase());
      },
      decoration: InputDecoration(
        hintText: 'Search invoices...',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }

  Widget _buildMobileInvoiceList() {
    return GetBuilder<CustomerController>(
      builder: (customerController) {
        return GetBuilder<VehicleController>(
          builder: (vehicleController) {
            return GetBuilder<InvoiceController>(
              builder: (invoiceController) {
                final invoices = invoiceController.invoices
                    .where((inv) => matchesSearch(inv, customerController))
                    .toList();

                if (invoices.isEmpty) {
                  return const Center(child: Text("No invoices found"));
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 150),
                  itemCount: invoices.length,
                  itemBuilder: (context, index) {
                    return _buildInvoiceTile(
                      invoices[invoices.length - index - 1],
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildInvoiceTile(Invoice inv) {
    final customerController = Get.find<CustomerController>();
    final vehicleController = Get.find<VehicleController>();
    final customer = customerController.getCustomerById(inv.customerId);
    final vehicle = vehicleController.getVehicleById(inv.vehicleId);
    final tax = inv.items.fold<double>(
      0.0,
      (sum, item) => sum + item.taxAmount,
    );

    return ErpMobileTile(
      onTap: () {
        Get.to(() => InvoicePreviewScreen(invoiceId: inv.invoiceId));
      },
      leading: CircleAvatar(
        backgroundColor: Colors.grey.shade100,
        child: const Icon(Icons.receipt_long, color: Colors.black87),
      ),
      title: inv.invoiceId,
      subtitles: [
        customer?.name ?? 'Unknown Customer',
        vehicle?.registrationNumber ?? 'Unknown Vehicle',
        '${inv.items.length} items • Tax ₹${tax.toStringAsFixed(0)}',
      ],
      trailing: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 5),
              Text(
                '₹${inv.balanceAmount.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Container(
                width: 50,
                decoration: BoxDecoration(
                  color: inv.paymentStatus.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  child: Center(
                    child: Text(
                      inv.paymentStatus.label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: inv.paymentStatus.color,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          AppPopupMenu(
            options: [
              AppPopupMenuOption(
                icon: Icons.edit_outlined,
                label: 'Edit',
                onTap: () {
                  Get.to(() => CreateInvoiceScreen(invoice: inv));
                },
              ),

              AppPopupMenuOption(
                icon: Icons.delete_outline,
                label: 'Delete',
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => DeleteConfirmationDialog(
                      title: 'Delete Invoice',
                      message:
                          'Are you sure you want to delete ${inv.invoiceId}?',
                      onDelete: () async {
                        await Get.find<InvoiceController>().deleteInvoice(
                          inv.invoiceId,
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
