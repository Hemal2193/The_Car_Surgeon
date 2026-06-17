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

  // Advance fields
  final TextEditingController _advanceController = TextEditingController();
  String _selectedPaymentMethod = 'Cash';
  static const List<String> _paymentMethods = [
    'Cash',
    'UPI',
    'Card',
    'Net Banking',
    'Bank Transfer',
    'Cheque',
  ];

  // Reminder fields
  final TextEditingController _reminderTitleController =
      TextEditingController();
  final TextEditingController _reminderNotesController =
      TextEditingController();
  DateTime _reminderDueDate = DateTime.now().add(const Duration(days: 7));

  double get grandTotal => rows.fold(0, (sum, e) => sum + e.totalAmount);
  double get advanceAmount => double.tryParse(_advanceController.text) ?? 0;
  double get remainingAmount => grandTotal - advanceAmount;

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

      // Load advance fields
      if (invoice.advanceAmount > 0) {
        _advanceController.text = invoice.advanceAmount.toStringAsFixed(2);
      }
      _selectedPaymentMethod = invoice.paymentMethod;

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
    _advanceController.dispose();
    _reminderTitleController.dispose();
    _reminderNotesController.dispose();
    _searchController.dispose();
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
      if (existing != null) {
        reminderCtrl.deleteReminder(existing.reminderId);
      }
      return;
    }

    if (existing != null) {
      existing.title = title;
      existing.notes = _reminderNotesController.text.trim().isNotEmpty
          ? _reminderNotesController.text.trim()
          : null;
      existing.dueDate = _reminderDueDate;
      reminderCtrl.updateReminder(existing);
    } else {
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

  void _addRowToInvoice(_InvoiceRow row) {
    setState(() {
      rows.add(row);
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
        discount: r.discount,
        discountIsPercent: r.discountIsPercent,
      );
    }).toList();

    final invoice = Invoice(
      invoiceId: widget.invoice?.invoiceId ?? IdGenerator.generateInvoiceId(),
      customerId: selectedCustomer!.customerId,
      vehicleId: selectedVehicle!.vehicleId,
      dateTime: widget.invoice?.dateTime ?? DateTime.now(),
      items: invoiceItems,
      grandTotal: grandTotal,
      advanceAmount: advanceAmount,
      paymentMethod: _selectedPaymentMethod,
    );

    if (isEditing) {
      await Get.find<InvoiceController>().updateInvoice(invoice);
      _updateReminderIfNeeded(
        invoice.invoiceId,
        invoice.customerId,
        invoice.vehicleId,
      );
      Get.snackbar(
        margin: EdgeInsets.symmetric(horizontal: 10, vertical: 20),
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
      _advanceController.clear();
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
                  labelColor: Colors.black,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Colors.black,
                  tabs: [
                    Tab(text: 'Invoice'),
                    Tab(text: 'Reminder'),
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
              _mobileBottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mobileTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
          AppSelector<Vehicle>(
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
                            child: Text(m, style: const TextStyle(fontSize: 14)),
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
    final hasAdvance = advanceAmount > 0;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasAdvance) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Grand Total", style: const TextStyle(fontSize: 14)),
                Text(
                  "Rs. ${grandTotal.toStringAsFixed(2)}",
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Advance ($_selectedPaymentMethod):",
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
                Text(
                  "- Rs. ${advanceAmount.toStringAsFixed(2)}",
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Remaining",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  "Rs. ${remainingAmount.toStringAsFixed(2)}",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: remainingAmount < 0 ? Colors.red : Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Total: ",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
          ],
          cButton(saveInvoice, isEditing ? "Update" : "Save", true),
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
          _mobileAdvanceSection(),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: cButton(_openAddItemPopup, 'Add Item', true),
          ),
          const SizedBox(height: 12),
          _buildItemSearchBar(),
          const SizedBox(height: 12),
          _mobileItemsList(),
        ],
      ),
    );
  }

  Widget _buildMobileReminderTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: _mobileReminderSection(),
    );
  }

  Widget _mobileReminderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),

        const Text(
          "Reminder (Optional)",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),

        const SizedBox(height: 10),

        const Text("Title", style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: _reminderTitleController,
          decoration: InputDecoration(
            hintText: "e.g. Follow up payment",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),

        const SizedBox(height: 14),

        Row(
          children: [
            const Text(
              "Due Date",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            InkWell(
              onTap: _pickDueDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "${_reminderDueDate.day.toString().padLeft(2, '0')}-"
                  "${_reminderDueDate.month.toString().padLeft(2, '0')}-"
                  "${_reminderDueDate.year}",
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        const Text("Notes", style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),

        TextField(
          controller: _reminderNotesController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: "Optional notes...",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),

        const SizedBox(height: 20),
      ],
    );
  }

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
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildCustomerSelector(),
            const SizedBox(height: 16),
            _buildVehicleSelector(),
            const SizedBox(height: 16),
            _buildAdvanceSection(),
            const SizedBox(height: 20),
            _buildAddItemButton(),
            const SizedBox(height: 25),
            _buildReminderSection(),
          ],
        ),
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
        const Text('Customer *', style: TextStyle(fontWeight: FontWeight.w500)),
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
        const Text('Vehicle', style: TextStyle(fontWeight: FontWeight.w500)),
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

  Widget _buildAdvanceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Advance Amount (Optional)',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        AppTextField(
          hintText: 'Enter advance amount',
          controller: _advanceController,
          keyboardType: TextInputType.number,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        Container(
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
                      child: Text(m, style: const TextStyle(fontSize: 14)),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _selectedPaymentMethod = v);
              },
            ),
          ),
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
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildReminderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: 10),

        const Text(
          "Add Reminder",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),

        const SizedBox(height: 12),
        _reminderTitleField(),
        const SizedBox(height: 16),
        _reminderDatePicker(),
        const SizedBox(height: 12),
        _reminderNotesField(),
      ],
    );
  }

  Widget _reminderTitleField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Reminder Title',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _reminderTitleController,
          decoration: InputDecoration(
            hintText: 'e.g. Follow up payment',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  Widget _reminderDatePicker() {
    return Row(
      children: [
        const Text('Due Date', style: TextStyle(fontWeight: FontWeight.w500)),
        const Spacer(),
        TextButton.icon(
          style: TextButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          icon: const Icon(Icons.calendar_today, size: 18),
          label: Text(
            "${_reminderDueDate.day.toString().padLeft(2, '0')}-"
            "${_reminderDueDate.month.toString().padLeft(2, '0')}-"
            "${_reminderDueDate.year}",
          ),
          onPressed: _pickDueDate,
        ),
      ],
    );
  }

  Widget _reminderNotesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
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
    final hasAdvance = advanceAmount > 0;
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
          if (hasAdvance) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Grand Total",
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                ),
                Text("Rs. ${grandTotal.toStringAsFixed(2)}", style: const TextStyle(fontSize: 14)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Advance ($_selectedPaymentMethod):",
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                ),
                Text(
                  "- Rs. ${advanceAmount.toStringAsFixed(2)}",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Divider(color: Colors.grey.shade400),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Remaining",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  "Rs. ${remainingAmount.toStringAsFixed(2)}",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: remainingAmount < 0 ? Colors.red : Colors.black,
                  ),
                ),
              ],
            ),
          ] else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Grand Total",
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  "Rs. ${grandTotal.toStringAsFixed(2)}",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
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

  /// Discount amount (converted from percent if needed)
  double get discountAmount {
    if (discountIsPercent) {
      return (qty * rate) * discount / 100;
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