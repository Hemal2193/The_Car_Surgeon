import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tcs/controllers/invoice_controller.dart';
import 'package:tcs/controllers/reminder_controller.dart';
import 'package:tcs/database/id_generator.dart';
import 'package:tcs/models/invoice_model.dart';
import 'package:tcs/models/reminder_model.dart';
import 'package:tcs/widgets/app_selector.dart';
import 'package:tcs/widgets/app_titlebar.dart';
import 'package:tcs/widgets/custom_button.dart';

import '../../models/customer_model.dart';
import '../../models/vehicle_model.dart';
import '../../models/item_model.dart';
import '../../controllers/customer_controller.dart';
import '../../controllers/vehicle_controller.dart';
import '../../controllers/item_controller.dart';

class CreateInvoiceScreen extends StatefulWidget {
  final Invoice? invoice;

  const CreateInvoiceScreen({super.key, this.invoice});

  @override
  State<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
  Customer? selectedCustomer;
  Vehicle? selectedVehicle;
  Item? selectedItem;

  int qty = 1;
  double rate = 0;
  int _customerSelectorVersion = 0;
  int _itemSelectorVersion = 0;

  final List<_InvoiceRow> rows = [];

  final TextEditingController qtyController = TextEditingController(text: "1");
  final TextEditingController rateController = TextEditingController();

  // Reminder fields
  final TextEditingController _reminderTitleController =
      TextEditingController();
  final TextEditingController _reminderNotesController =
      TextEditingController();
  DateTime _reminderDueDate = DateTime.now().add(const Duration(days: 7));

  double get grandTotal => rows.fold(0, (sum, e) => sum + e.totalAmount);

  bool get isEditing => widget.invoice != null;

  @override
  void initState() {
    super.initState();

    final invoice = widget.invoice;
    if (invoice != null) {
      selectedCustomer = Get.find<CustomerController>().getCustomerById(
        invoice.customerId,
      );
      selectedVehicle = Get.find<VehicleController>().getVehicleById(
        invoice.vehicleId,
      );
      rows.addAll(
        invoice.items.map((item) => _InvoiceRow.fromInvoiceItem(item)),
      );

      // Load existing reminder if editing
      final reminder = Get.find<ReminderController>().getReminderByInvoiceId(
        invoice.invoiceId,
      );
      if (reminder != null) {
        _reminderTitleController.text = reminder.title;
        _reminderNotesController.text = reminder.notes ?? '';
        _reminderDueDate = reminder.dueDate;
      }
    }
  }

  @override
  void dispose() {
    qtyController.dispose();
    rateController.dispose();
    _reminderTitleController.dispose();
    _reminderNotesController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final theme = Theme.of(context);
    final picked = await showDatePicker(
      context: context,
      initialDate: _reminderDueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: Colors.black,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),

            dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
            datePickerTheme: DatePickerThemeData(
              dayStyle: TextStyle(fontSize: 14),
              backgroundColor: Colors.white,
              headerBackgroundColor: Colors.black,
              headerForegroundColor: Colors.white,
              todayForegroundColor: WidgetStateProperty.all(Colors.black),
              todayBackgroundColor: WidgetStateProperty.all(
                Colors.grey.shade200,
              ),
              dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) return Colors.black;
                return Colors.transparent;
              }),
              dayForegroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) return Colors.white;
                return Colors.black;
              }),
              yearBackgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) return Colors.black;
                return Colors.transparent;
              }),
              yearForegroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) return Colors.white;
                return Colors.black;
              }),
              surfaceTintColor: Colors.transparent,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _reminderDueDate = picked;
      });
    }
  }

  void _createReminderIfNeeded(
    String invoiceId,
    String customerId,
    String vehicleId,
  ) {
    final title = _reminderTitleController.text.trim();
    if (title.isEmpty) return;

    final reminder = Reminder(
      reminderId: IdGenerator.generateReminderId(),
      customerId: customerId,
      vehicleId: vehicleId,
      invoiceId: invoiceId,
      dueDate: _reminderDueDate,
      title: title,
      notes: _reminderNotesController.text.trim().isNotEmpty
          ? _reminderNotesController.text.trim()
          : null,
    );

    Get.find<ReminderController>().addReminder(reminder);
  }

  void _updateReminderIfNeeded(
    String invoiceId,
    String customerId,
    String vehicleId,
  ) {
    final title = _reminderTitleController.text.trim();
    final reminderCtrl = Get.find<ReminderController>();

    final existing = reminderCtrl.getReminderByInvoiceId(invoiceId);

    if (title.isEmpty) {
      // If title is empty and a reminder exists, delete it
      if (existing != null) {
        reminderCtrl.deleteReminder(existing.reminderId);
      }
      return;
    }

    if (existing != null) {
      // Update existing reminder
      existing.title = title;
      existing.notes = _reminderNotesController.text.trim().isNotEmpty
          ? _reminderNotesController.text.trim()
          : null;
      existing.dueDate = _reminderDueDate;
      reminderCtrl.updateReminder(existing);
    } else {
      // Create new reminder
      final reminder = Reminder(
        reminderId: IdGenerator.generateReminderId(),
        customerId: customerId,
        vehicleId: vehicleId,
        invoiceId: invoiceId,
        dueDate: _reminderDueDate,
        title: title,
        notes: _reminderNotesController.text.trim().isNotEmpty
            ? _reminderNotesController.text.trim()
            : null,
      );
      reminderCtrl.addReminder(reminder);
    }
  }

  void addToInvoice() {
    if (selectedItem == null || qty <= 0 || rate < 0) return;

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
      rate = 0;
      qtyController.text = "1";
      rateController.clear();
      _itemSelectorVersion++;
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
        type: r.item.type,
        hsnSac: r.item.hsnSac,
        qty: r.qty,
        rate: r.rate,
        taxPercent: r.taxPercent,
        taxAmount: r.taxAmount,
        totalAmount: r.totalAmount,
      );
    }).toList();

    final invoice = Invoice(
      invoiceId: widget.invoice?.invoiceId ?? IdGenerator.generateInvoiceId(),
      customerId: selectedCustomer!.customerId,
      vehicleId: selectedVehicle!.vehicleId,
      dateTime: widget.invoice?.dateTime ?? DateTime.now(),
      items: invoiceItems,
      grandTotal: grandTotal,
    );

    if (isEditing) {
      await Get.find<InvoiceController>().updateInvoice(invoice);
      _updateReminderIfNeeded(
        invoice.invoiceId,
        invoice.customerId,
        invoice.vehicleId,
      );
      Get.snackbar(
        "Invoice Updated",
        "Invoice ${invoice.invoiceId} updated successfully",
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    } else {
      await Get.find<InvoiceController>().addInvoice(invoice);
      _createReminderIfNeeded(
        invoice.invoiceId,
        invoice.customerId,
        invoice.vehicleId,
      );
    }

    setState(() {
      rows.clear();
      selectedCustomer = null;
      selectedVehicle = null;
      selectedItem = null;
      qty = 1;
      rate = 0;
      qtyController.text = "1";
      rateController.clear();
      _customerSelectorVersion++;
      _itemSelectorVersion++;
    });

    Get.snackbar(
      "Success",
      "Invoice saved successfully",
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const AppTitleBar(),

          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // =========================================================
                // LEFT PANEL
                // =========================================================
                Container(
                  width: 320,
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(color: Colors.white),
                  child: ScrollConfiguration(
                    behavior: ScrollConfiguration.of(
                      context,
                    ).copyWith(scrollbars: false),
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
                                  Get.back();
                                },
                              ),
                              const SizedBox(width: 5),
                              Text(
                                isEditing ? "Edit Invoice" : "Create Invoice",
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),
                          const Text(
                            'Customer *',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          AppSelector<Customer>(
                            key: ValueKey(
                              'invoice_customer_selector_$_customerSelectorVersion',
                            ),
                            items: Get.find<CustomerController>().customers,
                            initialItem: selectedCustomer,
                            hintText: 'Select Customer',
                            displayText: (c) => '${c.name} (${c.customerId})',
                            searchText: (c) => '${c.name} ${c.customerId}',
                            itemBuilder: (c) => Text(c.name),
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
                            AppSelector<Vehicle>(
                              key: ValueKey(selectedCustomer!.customerId),
                              items: Get.find<VehicleController>().vehicles
                                  .where(
                                    (v) =>
                                        v.customerId ==
                                        selectedCustomer!.customerId,
                                  )
                                  .toList(),
                              initialItem: selectedVehicle,
                              hintText: 'Select Vehicle',
                              displayText: (v) => v.registrationNumber,
                              searchText: (v) =>
                                  '${v.registrationNumber} ${v.make} ${v.model}',
                              itemBuilder: (v) => Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(v.registrationNumber),
                                  Text(
                                    '${v.make} - ${v.model}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
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
                          AppSelector<Item>(
                            key: ValueKey(
                              'invoice_item_selector_$_itemSelectorVersion',
                            ),
                            items: Get.find<ItemController>().items,
                            initialItem: selectedItem,
                            hintText: 'Select Item',
                            displayText: (i) => i.name,
                            searchText: (i) => i.name,
                            itemBuilder: (i) => Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(i.name),
                                Text(
                                  'Rs. ${i.price ?? 0}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
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
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextField(
                                      controller: qtyController,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
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
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextField(
                                      controller: rateController,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
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

                          const SizedBox(height: 25),

                          // =====================================================
                          // REMINDER SECTION
                          // =====================================================
                          const Divider(),
                          const SizedBox(height: 10),

                          const Text(
                            "Add Reminder",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          const SizedBox(height: 12),

                          const Text(
                            'Reminder Title',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _reminderTitleController,
                            decoration: InputDecoration(
                              hintText: 'e.g. Follow up payment',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          Row(
                            children: [
                              const Text(
                                'Due Date',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              const Spacer(),
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  overlayColor: Colors.black,
                                ),
                                icon: const Icon(
                                  Icons.calendar_today,
                                  size: 18,
                                ),
                                label: Text(
                                  "${_reminderDueDate.day.toString().padLeft(2, '0')}-"
                                  "${_reminderDueDate.month.toString().padLeft(2, '0')}-"
                                  "${_reminderDueDate.year}",
                                ),
                                onPressed: _pickDueDate,
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          const Text(
                            'Notes (optional)',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _reminderNotesController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText: 'Any additional notes...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                Container(
                  width: 1,
                  height: double.infinity,
                  color: Colors.grey.shade300,
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

                            cButton(
                              saveInvoice,
                              isEditing ? 'Update Invoice' : 'Save Invoice',
                              true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        Expanded(
                          child: rows.isEmpty
                              ? Center(child: Text("No items added"))
                              : Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
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
                                            DataCell(
                                              Text(r.item.hsnSac ?? "-"),
                                            ),
                                            DataCell(Text("${r.qty}")),
                                            DataCell(Text("${r.rate}")),
                                            DataCell(
                                              Text(
                                                "${r.taxAmount.toStringAsFixed(2)} (${r.taxPercent}%)",
                                              ),
                                            ),
                                            DataCell(
                                              Text(
                                                r.totalAmount.toStringAsFixed(
                                                  2,
                                                ),
                                              ),
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
                                "Rs. ${grandTotal.toStringAsFixed(2)}",
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

  factory _InvoiceRow.fromInvoiceItem(InvoiceItem item) {
    return _InvoiceRow(
      item: Item(
        itemId: item.itemId,
        name: item.name,
        hsnSac: item.hsnSac,
        gst: item.taxPercent,
        price: item.rate,
        type: item.type,
      ),
      qty: item.qty,
      rate: item.rate,
      taxPercent: item.taxPercent,
      taxAmount: item.taxAmount,
    );
  }

  double get totalAmount => (qty * rate) + taxAmount;
}
