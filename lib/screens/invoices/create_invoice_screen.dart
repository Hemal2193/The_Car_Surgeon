import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tcs/controllers/invoice_controller.dart';
import 'package:tcs/controllers/reminder_controller.dart';
import 'package:tcs/database/id_generator.dart';
import 'package:tcs/models/invoice_model.dart';
import 'package:tcs/models/item_model.dart';
import 'package:tcs/models/reminder_model.dart';
import 'package:tcs/screens/customers/add_customer_dialog.dart';
import 'package:tcs/screens/vehicles/add_vehicle_dialog.dart';
import 'package:tcs/utils/responsive.dart';
import 'package:tcs/widgets/app_selector.dart';
import 'package:tcs/widgets/app_text_field.dart';
import 'package:tcs/widgets/app_titlebar.dart';
import 'package:tcs/widgets/custom_button.dart';
import 'package:tcs/widgets/delete_confirmation_dialog.dart';

import '../../models/customer_model.dart';
import '../../models/vehicle_model.dart';
import '../../controllers/customer_controller.dart';
import '../../controllers/vehicle_controller.dart';
import 'add_item_popup.dart';

// =========================================================
// DATA CLASS FOR REMINDERS IN THIS FORM
// =========================================================
class _InvoiceReminderData {
  final TextEditingController titleController;
  final TextEditingController notesController;
  DateTime dueDate;
  String? existingReminderId; // null = new reminder

  _InvoiceReminderData({
    String title = '',
    String notes = '',
    DateTime? dueDate,
    this.existingReminderId,
  }) : titleController = TextEditingController(text: title),
       notesController = TextEditingController(text: notes),
       dueDate = dueDate ?? DateTime.now().add(const Duration(days: 7));

  void dispose() {
    titleController.dispose();
    notesController.dispose();
  }
}

class CreateInvoiceScreen extends StatefulWidget {
  final Invoice? invoice;

  const CreateInvoiceScreen({super.key, this.invoice});

  @override
  State<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
  Customer? selectedCustomer;
  Vehicle? selectedVehicle;
  int _customerSelectorVersion = 0;
  int _vehicleSelectorVersion = 0;

  final List<_InvoiceRow> rows = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Invoice date & due date
  DateTime _invoiceDate = DateTime.now();
  DateTime _invoiceDueDate = DateTime.now();

  // Advance fields
  final TextEditingController _advanceController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  String _selectedPaymentMethod = 'Cash';
  static const List<String> _paymentMethods = [
    'Cash',
    'UPI',
    'Card',
    'Net Banking',
    'Bank Transfer',
    'Cheque',
  ];

  // Reminder fields – now supports multiple reminders
  final List<_InvoiceReminderData> _reminders = [];

  double get subtotalBeforeDiscount =>
      rows.fold(0, (sum, e) => sum + e.grossAmount);
  // double get totalDiscount => rows.fold(0, (sum, e) => sum + e.discountAmount);
  double get totalTax => rows.fold(0, (sum, e) => sum + e.taxAmount);
  double get grandTotal => rows.fold(0, (sum, e) => sum + e.totalAmount);
  double get advanceAmount => double.tryParse(_advanceController.text) ?? 0;
  double get discount => double.tryParse(_discountController.text) ?? 0;
  double get remainingAmount => grandTotal - advanceAmount - discount;

  bool get isEditing => widget.invoice != null;

  List<_InvoiceRow> get _filteredRows {
    if (_searchQuery.isEmpty) return rows;
    final query = _searchQuery.toLowerCase();
    return rows.where((row) {
      final nameMatch = row.item.name.toLowerCase().contains(query);
      final hsnMatch = (row.item.hsnSac ?? '').toLowerCase().contains(query);
      return nameMatch || hsnMatch;
    }).toList();
  }

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

      // Load invoice dates
      _invoiceDate = invoice.dateTime;
      _invoiceDueDate = invoice.dueDate;

      // Load advance fields
      if (invoice.advanceAmount > 0) {
        _advanceController.text = invoice.advanceAmount.toStringAsFixed(2);
      }
      if (invoice.discount > 0) {
        _discountController.text = invoice.discount.toStringAsFixed(2);
      }
      _selectedPaymentMethod = invoice.paymentMethod;

      // Load all existing reminders for this invoice
      final existingReminders = Get.find<ReminderController>()
          .getRemindersByInvoiceId(invoice.invoiceId);
      if (existingReminders.isNotEmpty) {
        for (final r in existingReminders) {
          _reminders.add(
            _InvoiceReminderData(
              title: r.title,
              notes: r.notes ?? '',
              dueDate: r.dueDate,
              existingReminderId: r.reminderId,
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _advanceController.dispose();
    _discountController.dispose();
    for (final r in _reminders) {
      r.dispose();
    }
    _searchController.dispose();
    super.dispose();
  }

  void _addEmptyReminder() {
    setState(() {
      _reminders.add(_InvoiceReminderData());
    });
  }

  void _removeReminder(int index) {
    setState(() {
      _reminders[index].dispose();
      _reminders.removeAt(index);
    });
  }

  /// Generic date picker that allows selecting any date (past, present, or future).
  /// [currentDate] is the initially selected date.
  /// Returns the picked date or null if cancelled.
  Future<DateTime?> _pickDate(DateTime currentDate) async {
    final theme = Theme.of(context);
    final picked = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: DateTime(2000),
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
    return picked;
  }

  Future<void> _pickInvoiceDate() async {
    final picked = await _pickDate(_invoiceDate);
    if (picked != null) {
      setState(() {
        _invoiceDate = picked;
      });
    }
  }

  Future<void> _pickInvoiceDueDate() async {
    final picked = await _pickDate(_invoiceDueDate);
    if (picked != null) {
      setState(() {
        _invoiceDueDate = picked;
      });
    }
  }

  Future<void> _createRemindersIfNeeded(
    String invoiceId,
    String customerId,
    String vehicleId,
  ) async {
    final reminderCtrl = Get.find<ReminderController>();
    for (final r in _reminders) {
      final title = r.titleController.text.trim();
      if (title.isEmpty) continue;

      if (r.existingReminderId != null) {
        // Update existing
        final existing = reminderCtrl.getReminderById(r.existingReminderId!);
        if (existing != null) {
          existing.title = title;
          existing.notes = r.notesController.text.trim().isNotEmpty
              ? r.notesController.text.trim()
              : null;
          existing.dueDate = r.dueDate;
          try {
            await reminderCtrl.updateReminder(existing);
          } catch (e, st) {
            Get.snackbar(
              'Reminder Save Error',
              'Failed to update reminder: $e',
            );
            print('updateReminder error: $e');
            print(st);
          }
        }
      } else {
        // Create new
        final reminder = Reminder(
          reminderId: IdGenerator.generateReminderId(),
          customerId: customerId,
          vehicleId: vehicleId,
          invoiceId: invoiceId,
          dueDate: r.dueDate,
          title: title,
          notes: r.notesController.text.trim().isNotEmpty
              ? r.notesController.text.trim()
              : null,
          type: ReminderType.service,
        );
        try {
          await reminderCtrl.addReminder(reminder);
          print("Reminder added");
        } catch (e, st) {
          Get.snackbar('Reminder Save Error', 'Failed to create reminder: $e');
          print('addReminder error: $e');
          print(st);
        }
      }
    }
  }

  Future<void> _deleteRemovedReminders() async {
    if (!isEditing) return;
    final invoiceId = widget.invoice!.invoiceId;
    final reminderCtrl = Get.find<ReminderController>();
    final existingAll = reminderCtrl.getRemindersByInvoiceId(invoiceId);
    final keptIds = _reminders
        .map((r) => r.existingReminderId)
        .where((id) => id != null)
        .toSet();

    for (final existing in existingAll) {
      if (!keptIds.contains(existing.reminderId)) {
        await reminderCtrl.deleteReminder(existing.reminderId);
      }
    }
  }

  void _addRowToInvoice(_InvoiceRow row) {
    setState(() {
      rows.add(row);
    });
  }

  void saveInvoice() async {
    debugPrint("Advance: ${_advanceController.text}");
    debugPrint("Discount: ${_discountController.text}");

    debugPrint("advanceAmount = $advanceAmount");
    debugPrint("discount = $discount");

    final invoiceCtrl = Get.find<InvoiceController>();
    if (selectedCustomer == null || selectedVehicle == null || rows.isEmpty) {
      Get.snackbar(
        "Validation Error",
        "Please select customer, vehicle, and add items.",
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    // for (final r in _reminders) {
    //   if (r.titleController.text.trim().isEmpty) {
    //     Get.snackbar(
    //       "Validation Error",
    //       "Reminder title cannot be empty.",
    //       snackPosition: SnackPosition.BOTTOM,
    //     );
    //     return;
    //   }
    // }

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
        discount: r.discount,
        discountIsPercent: r.discountIsPercent,
      );
    }).toList();

    final invoice = Invoice(
      invoiceId: widget.invoice?.invoiceId ?? IdGenerator.generateInvoiceId(),
      customerId: selectedCustomer!.customerId,
      vehicleId: selectedVehicle!.vehicleId,
      dateTime: _invoiceDate,
      dueDate: _invoiceDueDate,
      items: invoiceItems,
      grandTotal: grandTotal,
      discount: discount,
      advanceAmount: advanceAmount,
      paymentMethod: _selectedPaymentMethod,
    );

    if (isEditing) {
      try {
        await invoiceCtrl.updateInvoice(invoice);
        debugPrint("Invoice updated successfully");
      } catch (e, st) {
        debugPrint("updateInvoice error: $e");
        debugPrint("$st");
        Get.snackbar(
          "Invoice Save Error",
          "Failed to update invoice: $e",
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
      // Delete reminders that were removed (with error isolation)
      try {
        await _deleteRemovedReminders();
        debugPrint("deleteRemovedReminders completed");
      } catch (e, st) {
        debugPrint("deleteRemovedReminders error: $e");
        debugPrint("$st");
      }
      // Create/update remaining reminders (with error isolation)
      try {
        await _createRemindersIfNeeded(
          invoice.invoiceId,
          invoice.customerId,
          invoice.vehicleId,
        );
        debugPrint("createRemindersIfNeeded completed");
      } catch (e, st) {
        debugPrint("createRemindersIfNeeded error: $e");
        debugPrint("$st");
        Get.snackbar(
          "Reminder Save Error",
          "Failed to save reminders: $e",
          snackPosition: SnackPosition.BOTTOM,
        );
      }
      Get.back();
      Get.snackbar(
        margin: EdgeInsets.symmetric(horizontal: 10, vertical: 20),
        "Invoice Updated",
        "Invoice ${invoice.invoiceId} updated successfully",
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    } else {
      await invoiceCtrl.addInvoice(invoice);
      await _createRemindersIfNeeded(
        invoice.invoiceId,
        invoice.customerId,
        invoice.vehicleId,
      );
    }

    setState(() {
      rows.clear();
      selectedCustomer = null;
      selectedVehicle = null;
      _advanceController.clear();
      _discountController.clear();
      for (final r in _reminders) {
        r.dispose();
      }
      _reminders.clear();
      _customerSelectorVersion++;
    });

    Get.snackbar(
      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 20),
      "Success",
      "Invoice saved successfully",
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (Responsive.isDesktop(context)) {
      return _buildDesktopCreateInvoice(context);
    }

    return _buildMobileCreateInvoice(context);
  }

  Widget _buildMobileCreateInvoice(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              _mobileTopBar(),
              Container(
                color: Colors.white,
                child: const TabBar(
                  indicatorSize: TabBarIndicatorSize.label,
                  labelColor: Colors.black,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Colors.black,
                  tabs: [
                    Tab(text: 'Invoice'),
                    Tab(text: 'Reminders'),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildMobileInvoiceTab(),
                    _buildMobileReminderTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mobileTopBar() {
    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 12, top: 10),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Get.back(),
          ),
          const SizedBox(width: 6),
          Text(
            isEditing ? "Edit Invoice" : "Create Invoice",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _mobileCustomerSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Customer *",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(width: 10),
            InkWell(
              onTap: () async {
                await showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  isDismissible: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) {
                    return DraggableScrollableSheet(
                      expand: false,
                      initialChildSize: 0.80,
                      minChildSize: 0.80,
                      maxChildSize: 0.92,
                      shouldCloseOnMinExtent: true,
                      builder: (context, scrollController) {
                        return AddCustomerDialog(
                          scrollController: scrollController,
                        );
                      },
                    );
                  },
                );
                Get.find<CustomerController>().update();
                setState(() {
                  _customerSelectorVersion++;
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 3,
                  ),
                  child: const Text(
                    "Add New Customer",
                    style: TextStyle(fontSize: 9),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        AppSelector<Customer>(
          key: ValueKey('mobile_customer_$_customerSelectorVersion'),
          items: Get.find<CustomerController>().customers,
          initialItem: selectedCustomer,
          hintText: "Select Customer",
          displayText: (c) => c.name,
          searchText: (c) => c.name,
          itemBuilder: (c) => Text(c.name),
          onSelected: (c) {
            setState(() {
              selectedCustomer = c;
              selectedVehicle = null;
            });
          },
        ),
      ],
    );
  }

  Widget _mobileVehicleSelector() {
    final FocusNode vehicleFocusNode = FocusNode();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Vehicle",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            InkWell(
              onTap: () async {
                await showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  isDismissible: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) {
                    return DraggableScrollableSheet(
                      expand: false,
                      initialChildSize: 0.80,
                      minChildSize: 0.80,
                      maxChildSize: 0.92,
                      shouldCloseOnMinExtent: true,
                      builder: (context, scrollController) {
                        return AddVehicleDialog(
                          scrollController: scrollController,
                        );
                      },
                    );
                  },
                );
                Get.find<VehicleController>().update();
                setState(() {
                  _vehicleSelectorVersion++;
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 3,
                  ),
                  child: const Text(
                    "Add New Vehicle",
                    style: TextStyle(fontSize: 9),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        if (selectedCustomer == null)
          const Text("Select customer first")
        else
          GestureDetector(
            child: AppSelector<Vehicle>(
              focusNode: vehicleFocusNode,
              key: ValueKey('mobile_vehicle_$_vehicleSelectorVersion'),
              items: Get.find<VehicleController>().vehicles
                  .where((v) => v.customerId == selectedCustomer!.customerId)
                  .toList(),
              initialItem: selectedVehicle,
              hintText: "Select Vehicle",
              displayText: (v) => v.registrationNumber,
              searchText: (v) => v.registrationNumber,
              itemBuilder: (v) => Text(v.registrationNumber),
              onSelected: (v) {
                setState(() => selectedVehicle = v);
              },
            ),
          ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}-"
        "${date.month.toString().padLeft(2, '0')}-"
        "${date.year}";
  }

  Widget _mobileInvoiceDatesSelector() {
    return Row(
      children: [
        // Invoice Date
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Invoice Date",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: _pickInvoiceDate,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDate(_invoiceDate),
                        style: const TextStyle(fontSize: 13),
                      ),
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Colors.grey.shade700,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Due Date
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Due Date",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: _pickInvoiceDueDate,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDate(_invoiceDueDate),
                        style: const TextStyle(fontSize: 13),
                      ),
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Colors.grey.shade700,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _mobileAdvanceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Advance Amount (Optional)",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: AppTextField(
                hintText: 'Enter advance amount',
                controller: _advanceController,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black26),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedPaymentMethod,
                    isExpanded: true,
                    items: _paymentMethods
                        .map(
                          (m) => DropdownMenuItem(
                            value: m,
                            child: Text(
                              m,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedPaymentMethod = v);
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _mobileDiscountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Discount (Optional)",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        AppTextField(
          hintText: 'Enter discount amount',
          controller: _discountController,
          keyboardType: TextInputType.number,
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  Widget _mobileItemsList() {
    if (_filteredRows.isEmpty && rows.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text("No items added"),
        ),
      );
    }

    if (_filteredRows.isEmpty && rows.isNotEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text("No items found"),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(_filteredRows.length, (i) {
        final r = _filteredRows[i];
        return _itemCard(r, i);
      }),
    );
  }

  Widget _itemCard(_InvoiceRow r, int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => _openAddItemPopup(editIndex: index),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "${r.item.name} (${r.item.type})",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            _deleteRow(index);
                          },
                          child: Icon(
                            Icons.delete_outline,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      "Qty: ${r.qty} | Rate: ${r.rate}",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade900,
                      ),
                    ),
                    Text(
                      "Tax: ${r.taxAmount.toStringAsFixed(2)} (${r.taxPercent}%)",
                    ),
                    Text("Total: ${r.totalAmount.toStringAsFixed(2)}"),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _deleteRow(int index) {
    showDialog(
      context: context,
      builder: (_) => DeleteConfirmationDialog(
        title: 'Delete Item',
        message: 'Are you sure you want to remove this item?',
        onDelete: () {
          setState(() {
            rows.removeAt(index);
          });
        },
      ),
    );
  }

  Widget _mobileBottomBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _amountLine("Subtotal", subtotalBeforeDiscount),
          _amountLine("Tax", totalTax),
          _amountLine("Grand Total", grandTotal),
          _amountLine("Discount", -discount),
          _amountLine("Advance ($_selectedPaymentMethod)", -advanceAmount),
          Divider(color: Colors.grey.shade300),
          _amountLine("Balance", remainingAmount, bold: true),
        ],
      ),
    );
  }

  Widget _buildMobileInvoiceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _mobileCustomerSelector(),
          const SizedBox(height: 12),
          _mobileVehicleSelector(),
          const SizedBox(height: 12),
          _mobileInvoiceDatesSelector(),
          const SizedBox(height: 12),
          const Divider(color: Colors.grey),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: cButton(_openAddItemPopup, 'Add Item', true),
          ),
          const SizedBox(height: 12),
          _buildItemSearchBar(),
          const SizedBox(height: 12),
          _mobileItemsList(),
          const SizedBox(height: 12),
          const Divider(color: Colors.grey),
          const SizedBox(height: 12),
          _mobileAdvanceSection(),
          const SizedBox(height: 12),
          _mobileDiscountSection(),
          const SizedBox(height: 12),
          _mobileBottomBar(),
          const SizedBox(height: 12),
          cButton(saveInvoice, isEditing ? "Update" : "Save", true),
        ],
      ),
    );
  }

  // =========================================================
  // MOBILE REMINDER TAB – MULTIPLE REMINDERS
  // =========================================================
  Widget _buildMobileReminderTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Reminders (Optional)",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),

          // List of reminders
          ...List.generate(_reminders.length, (i) {
            return _mobileReminderCard(i);
          }),

          // Add reminder button
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _addEmptyReminder,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.black),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.add, size: 18),
              label: const Text("Add Reminder"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mobileReminderCard(int index) {
    final r = _reminders[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with delete button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Reminder #${index + 1}",
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (_reminders.length > 1)
                GestureDetector(
                  onTap: () => _removeReminder(index),
                  child: const Icon(Icons.close, size: 20),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Title
          const Text("Title", style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextField(
            controller: r.titleController,
            decoration: InputDecoration(
              hintText: "e.g. Follow up payment",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Due date
          Row(
            children: [
              const Text(
                "Due Date",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              InkWell(
                onTap: () async {
                  final picked = await _pickDate(r.dueDate);
                  if (picked != null) {
                    setState(() => r.dueDate = picked);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatDate(r.dueDate),
                        style: const TextStyle(fontSize: 13),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Colors.grey.shade700,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Notes
          const Text("Notes", style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextField(
            controller: r.notesController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: "Optional notes...",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // DESKTOP
  // =========================================================
  Widget _buildDesktopCreateInvoice(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const AppTitleBar(),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLeftPanel(),
                _buildVerticalDivider(),
                _buildRightPanel(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftPanel() {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          ScrollConfiguration(
            behavior: const ScrollBehavior().copyWith(scrollbars: false),
            child: Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCustomerSelector(),
                    const SizedBox(height: 16),
                    _buildVehicleSelector(),
                    const SizedBox(height: 16),
                    _buildInvoiceDatesSelector(),
                    const SizedBox(height: 16),
                    const Divider(color: Colors.grey),
                    const SizedBox(height: 16),
                    _buildAddItemButton(),
                    const SizedBox(height: 16),
                    const Divider(color: Colors.grey),
                    const SizedBox(height: 16),
                    _buildAdvanceSection(),
                    const SizedBox(height: 20),
                    _buildDiscountSection(),
                    const SizedBox(height: 25),
                    _buildReminderSection(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        const SizedBox(width: 5),
        Text(
          isEditing ? "Edit Invoice" : "Create Invoice",
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildCustomerSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Customer *',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            InkWell(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return const AddCustomerDialog();
                  },
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Padding(
                  padding: EdgeInsetsGeometry.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Text(
                    "Add New Customer",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 8),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        AppSelector<Customer>(
          key: ValueKey('customer_$_customerSelectorVersion'),
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
      ],
    );
  }

  Widget _buildVehicleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Vehicle',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            InkWell(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return const AddVehicleDialog();
                  },
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Padding(
                  padding: EdgeInsetsGeometry.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Text(
                    "Add New Vehicle",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 8),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (selectedCustomer != null)
          AppSelector<Vehicle>(
            key: ValueKey(selectedCustomer!.customerId),
            items: Get.find<VehicleController>().vehicles
                .where((v) => v.customerId == selectedCustomer!.customerId)
                .toList(),
            initialItem: selectedVehicle,
            hintText: 'Select Vehicle',
            displayText: (v) => v.registrationNumber,
            searchText: (v) => '${v.registrationNumber} ${v.make} ${v.model}',
            itemBuilder: (v) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(v.registrationNumber),
                Text(
                  '${v.make} - ${v.model}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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
      ],
    );
  }

  Widget _buildInvoiceDatesSelector() {
    return Row(
      children: [
        // Invoice Date
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Invoice Date",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: _pickInvoiceDate,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDate(_invoiceDate),
                        style: const TextStyle(fontSize: 13),
                      ),
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Colors.grey.shade700,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Due Date
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Due Date",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: _pickInvoiceDueDate,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDate(_invoiceDueDate),
                        style: const TextStyle(fontSize: 13),
                      ),
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Colors.grey.shade700,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAdvanceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Advance Amount (Optional)',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: AppTextField(
                hintText: 'Enter advance amount',
                controller: _advanceController,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black26),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedPaymentMethod,
                    isExpanded: true,
                    items: _paymentMethods
                        .map(
                          (m) => DropdownMenuItem(
                            value: m,
                            child: Text(
                              m,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedPaymentMethod = v);
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDiscountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Discount (Optional)',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        AppTextField(
          hintText: 'Enter discount amount',
          controller: _discountController,
          keyboardType: TextInputType.number,
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  Future<void> _openAddItemPopup({int? editIndex}) async {
    Map<String, dynamic>? initialData;
    if (editIndex != null && editIndex < rows.length) {
      final r = rows[editIndex];
      initialData = {
        'item': r.item,
        'qty': r.qty,
        'rate': r.rate,
        'taxPercent': r.taxPercent,
        'taxAmount': r.taxAmount,
        'discount': r.discount,
        'discountIsPercent': r.discountIsPercent,
      };
    }

    final result = await AddItemPopup.show(context, initialData: initialData);

    if (result == null) return;

    final row = _InvoiceRow(
      item: result['item'] as Item,
      qty: result['qty'] as int,
      rate: (result['rate'] as num).toDouble(),
      taxPercent: (result['taxPercent'] as num).toDouble(),
      taxAmount: (result['taxAmount'] as num).toDouble(),
      discount: (result['discount'] as num).toDouble(),
      discountIsPercent: result['discountIsPercent'] as bool,
    );

    if (editIndex != null) {
      setState(() {
        rows[editIndex] = row;
      });
    } else {
      _addRowToInvoice(row);
    }
  }

  Widget _buildAddItemButton() {
    return SizedBox(
      width: double.infinity,
      child: cButton(_openAddItemPopup, 'Add Item', true),
    );
  }

  Widget _buildItemSearchBar() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by item name or HSN/SAC',
          prefixIcon: const Icon(Icons.search, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 14,
          ),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  // =========================================================
  // DESKTOP REMINDER SECTION – MULTIPLE REMINDERS
  // =========================================================
  Widget _buildReminderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: 10),

        const Text(
          "Reminders",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),

        // List of reminders
        ...List.generate(_reminders.length, (i) {
          return _desktopReminderCard(i);
        }),

        // Add reminder button
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _addEmptyReminder,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.black),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.add, size: 18),
            label: const Text("Add Reminder"),
          ),
        ),
      ],
    );
  }

  Widget _desktopReminderCard(int index) {
    final r = _reminders[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with delete
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Reminder #${index + 1}",
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (_reminders.length > 1)
                GestureDetector(
                  onTap: () => _removeReminder(index),
                  child: const Icon(Icons.close, size: 18),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Title
          const Text(
            'Title',
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          ),
          const SizedBox(height: 4),
          AppTextField(
            controller: r.titleController,
            hintText: 'e.g. Follow up payment',
          ),
          // TextField(
          //   controller: r.titleController,
          //   decoration: InputDecoration(
          //     hintText: 'e.g. Follow up payment',
          //     border: OutlineInputBorder(
          //       borderRadius: BorderRadius.circular(6),
          //     ),
          //     contentPadding: const EdgeInsets.symmetric(
          //       horizontal: 10,
          //       vertical: 8,
          //     ),
          //     isDense: true,
          //   ),
          // ),
          const SizedBox(height: 20),

          // Due date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Due Date',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
              ),

              InkWell(
                onTap: () async {
                  final picked = await _pickDate(r.dueDate);
                  if (picked != null) {
                    setState(() => r.dueDate = picked);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatDate(r.dueDate),
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Colors.grey.shade700,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          const Text(
            'Notes',
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          ),
          const SizedBox(height: 4),
          AppTextField(
            controller: r.notesController,
            hintText: 'Enter notes',
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildRightPanel() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildInvoiceHeader(),
            const SizedBox(height: 20),
            _buildItemSearchBar(),
            const SizedBox(height: 12),
            _buildInvoiceTable(),
            const SizedBox(height: 15),
            _buildGrandTotal(),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "Invoice Items",
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        cButton(
          saveInvoice,
          isEditing ? 'Update Invoice' : 'Save Invoice',
          true,
        ),
      ],
    );
  }

  Widget _buildInvoiceTable() {
    if (_filteredRows.isEmpty) {
      return const Expanded(child: Center(child: Text("No items added")));
    }

    return Expanded(
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ScrollConfiguration(
          behavior: const ScrollBehavior().copyWith(scrollbars: false),
          child: SingleChildScrollView(
            child: DataTable(
              showCheckboxColumn: false,
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
              rows: List.generate(_filteredRows.length, (i) {
                final r = _filteredRows[i];
                return DataRow(
                  onSelectChanged: (_) => _openAddItemPopup(editIndex: i),
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
                    DataCell(Text(r.totalAmount.toStringAsFixed(2))),
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
    );
  }

  Widget _buildGrandTotal() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _amountLine("Subtotal", subtotalBeforeDiscount),
          _amountLine("Tax", totalTax),
          _amountLine("Grand Total", grandTotal),
          _amountLine("Discount", -discount),
          _amountLine("Advance ($_selectedPaymentMethod)", -advanceAmount),
          Divider(color: Colors.grey.shade400),
          _amountLine("Balance", remainingAmount, bold: true),
        ],
      ),
    );
  }

  Widget _amountLine(String label, double value, {bool bold = false}) {
    final isNegative = value < 0;
    final amount = value.abs().toStringAsFixed(2);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: bold ? 16 : 14,
              fontWeight: bold ? FontWeight.bold : FontWeight.w500,
              color: bold ? Colors.black : Colors.grey.shade800,
            ),
          ),
          Text(
            "${isNegative ? '- ' : ''}Rs. $amount",
            style: TextStyle(
              fontSize: bold ? 16 : 14,
              fontWeight: bold ? FontWeight.bold : FontWeight.w600,
              color: bold && value < 0 ? Colors.red : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(width: 1, color: Colors.grey.shade300);
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
  final double discount;
  final bool discountIsPercent;

  _InvoiceRow({
    required this.item,
    required this.qty,
    required this.rate,
    required this.taxPercent,
    required this.taxAmount,
    this.discount = 0,
    this.discountIsPercent = false,
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
      discount: item.discount,
      discountIsPercent: item.discountIsPercent,
    );
  }

  /// Exclusive price before tax = (qty * rate) - discount
  double get exclusivePrice => (qty * rate) - discountAmount;

  double get grossAmount => qty * rate;

  /// Discount amount (converted from percent if needed)
  double get discountAmount {
    if (discountIsPercent) {
      return grossAmount * discount / 100;
    }
    return discount;
  }

  /// Taxable value after discount
  double get taxableValue => (qty * rate) - discountAmount;

  /// Total amount with tax
  double get totalAmount {
    final taxable = (qty * rate) - discountAmount;
    return taxable + taxAmount;
  }
}
