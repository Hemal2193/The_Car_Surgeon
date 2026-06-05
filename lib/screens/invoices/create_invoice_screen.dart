import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:hive/hive.dart';
import 'package:tcs/database/hive_boxes.dart';
import 'package:tcs/database/id_generator.dart';
import 'package:tcs/models/invoice_model.dart';
import 'package:tcs/widgets/app_customer_selector.dart';
import 'package:tcs/widgets/app_item_selector.dart';
import 'package:tcs/widgets/app_vehicle_selector.dart';
import 'package:tcs/widgets/custom_button.dart';

import '../../models/customer_model.dart';
import '../../models/vehicle_model.dart';
import '../../models/item_model.dart';

class CreateInvoiceScreen extends StatefulWidget {
  const CreateInvoiceScreen({super.key});

  @override
  State<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
  Customer? selectedCustomer;
  Vehicle? selectedVehicle;
  Item? selectedItem;

  int qty = 1;
  double rate = 0;

  final List<_InvoiceRow> rows = [];

  final TextEditingController qtyController = TextEditingController(text: "1");
  final TextEditingController rateController = TextEditingController();

  double get grandTotal => rows.fold(0, (sum, e) => sum + e.totalAmount);

  void addToInvoice() {
    if (selectedItem == null) return;

    final baseAmount = qty * rate;
    final gstAmount = (baseAmount * selectedItem!.gst) / 100;

    setState(() {
      rows.add(
        _InvoiceRow(
          item: selectedItem!,
          qty: qty,
          rate: rate,
          taxPercent: selectedItem!.gst,
          taxAmount: gstAmount,
        ),
      );

      // reset input only (NOT validation, NOT blocking)
      selectedItem = null;
      qty = 1;
      qtyController.text = "1";
    });
  }

  void saveInvoice() async {
    if (selectedCustomer == null || selectedVehicle == null || rows.isEmpty) {
      return;
    }

    final invoiceItems = rows.map((r) {
      return InvoiceItem(
        itemId: r.item.itemId,
        name: r.item.name,
        hsnSac: r.item.hsnSac,
        qty: r.qty,
        rate: r.rate,
        taxPercent: r.taxPercent,
        taxAmount: r.taxAmount,
        totalAmount: r.totalAmount,
      );
    }).toList();

    final invoice = Invoice(
      invoiceId: IdGenerator.generateInvoiceId(),
      customerId: selectedCustomer!.customerId,
      vehicleId: selectedVehicle!.vehicleId,
      dateTime: DateTime.now(),
      items: invoiceItems,
      grandTotal: grandTotal,
    );

    final box = Hive.box<Invoice>(HiveBoxes.invoices);
    await box.add(invoice);

    setState(() {
      rows.clear();
      selectedCustomer = null;
      selectedVehicle = null;
    });

    Get.snackbar("Success", "Invoice saved successfully");
  }

  @override
  void dispose() {
    qtyController.dispose();
    rateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // =========================================================
          // LEFT PANEL
          // =========================================================
          Container(
            width: 320,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(right: BorderSide(color: Colors.black12)),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // =====================================================
                  // HEADER WITH BACK BUTTON (NEW)
                  // =====================================================
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                      const SizedBox(width: 5),
                      const Text(
                        "Create Invoice",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  const Text(
                    'Customer *',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  AppCustomerSelector(
                    onSelected: (c) {
                      setState(() {
                        selectedCustomer = c;
                        selectedVehicle = null;
                      });
                    },
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    'Vehicle',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  if (selectedCustomer != null)
                    AppVehicleSelector(
                      customerId: selectedCustomer!.customerId,
                      onSelected: (v) {
                        setState(() {
                          selectedVehicle = v;
                        });
                      },
                    )
                  else
                    const Text("Select customer first"),

                  const SizedBox(height: 16),

                  const Text(
                    'Item',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  AppItemSelector(
                    onSelected: (i) {
                      setState(() {
                        selectedItem = i;

                        qty = 1;
                        qtyController.text = "1";

                        rate = i.price ?? 0;
                        rateController.text = rate.toString();
                      });
                    },
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Quantity",
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: qtyController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onChanged: (v) {
                                qty = int.tryParse(v) ?? 1;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Rate",
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: rateController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onChanged: (v) {
                                rate = double.tryParse(v) ?? 0;
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  SizedBox(
                    width: double.infinity,
                    child: cButton(addToInvoice, 'Add Item', true),
                  ),
                ],
              ),
            ),
          ),

          // =========================================================
          // RIGHT PANEL (UNCHANGED)
          // =========================================================
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Invoice Items",
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      cButton(saveInvoice, 'Save Invoice', true),
                    ],
                  ),
                  const SizedBox(height: 20),

                  Expanded(
                    child: rows.isEmpty
                        ? Center(child: Text("No items added"))
                        : Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
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
                                  DataColumn(label: Text("Tax")),
                                  DataColumn(label: Text("Total")),
                                  DataColumn(label: Text("Action")),
                                ],
                                rows: List.generate(rows.length, (i) {
                                  final r = rows[i];
                                  return DataRow(
                                    cells: [
                                      DataCell(Text("${i + 1}")),
                                      DataCell(Text(r.item.name)),
                                      DataCell(Text(r.item.hsnSac ?? "-")),
                                      DataCell(Text("${r.qty}")),
                                      DataCell(Text("${r.rate}")),
                                      DataCell(
                                        Text(
                                          "${r.taxAmount.toStringAsFixed(2)} (${r.taxPercent}%)",
                                        ),
                                      ),
                                      DataCell(
                                        Text(r.totalAmount.toStringAsFixed(2)),
                                      ),
                                      DataCell(
                                        IconButton(
                                          icon: const Icon(Icons.close),
                                          onPressed: () {
                                            setState(() {
                                              rows.removeAt(i);
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  );
                                }),
                              ),
                            ),
                          ),
                  ),

                  const SizedBox(height: 15),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Grand Total",
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          "₹${grandTotal.toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
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
}

// =========================================================
// MODEL
// =========================================================
class _InvoiceRow {
  final Item item;
  final int qty;
  final double rate;
  final double taxPercent;
  final double taxAmount;

  _InvoiceRow({
    required this.item,
    required this.qty,
    required this.rate,
    required this.taxPercent,
    required this.taxAmount,
  });

  double get totalAmount => (qty * rate) + taxAmount;
}
