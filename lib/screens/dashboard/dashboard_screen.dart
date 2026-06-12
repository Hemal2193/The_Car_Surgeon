// ignore_for_file: deprecated_member_use

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:tcs/screens/invoices/create_invoice_screen.dart';
import 'package:tcs/utils/responsive.dart';
import 'package:tcs/widgets/app_popup_menu.dart';
import 'package:tcs/widgets/delete_confirmation_dialog.dart';
import 'package:tcs/widgets/erp_mobile_tile.dart';

import '../../controllers/customer_controller.dart';
import '../../controllers/vehicle_controller.dart';
import '../../controllers/item_controller.dart';
import '../../controllers/invoice_controller.dart';
import '../../controllers/reminder_controller.dart';

import '../../models/reminder_model.dart';

import '../customers/customer_detail_screen.dart';
import '../vehicles/vehicle_detail_screen.dart';
import '../invoices/invoice_preview_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<SearchResult> _searchResults = [];
  bool _isSearching = false;

  String formatDate(DateTime dt) {
    String day = dt.day.toString().padLeft(2, '0');
    String month = dt.month.toString().padLeft(2, '0');
    // Extracts the last 2 digits of the year
    String year = (dt.year % 100).toString().padLeft(2, '0');

    return "$day-$month-$year";
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    final q = query.trim().toLowerCase();
    final customerCtrl = Get.find<CustomerController>();
    final vehicleCtrl = Get.find<VehicleController>();
    final invoiceCtrl = Get.find<InvoiceController>();
    final results = <SearchResult>[];

    // Search customers
    for (final c in customerCtrl.customers) {
      if (c.name.toLowerCase().contains(q) ||
          c.customerId.toLowerCase().contains(q)) {
        results.add(
          SearchResult(
            type: SearchResultType.customer,
            primary: c.name,
            secondary: c.customerId,
            payload: c.customerId,
          ),
        );
      }
    }

    // Search vehicles
    for (final v in vehicleCtrl.vehicles) {
      if (v.registrationNumber.toLowerCase().contains(q) ||
          v.vehicleId.toLowerCase().contains(q)) {
        final customer = customerCtrl.getCustomerById(v.customerId);
        results.add(
          SearchResult(
            type: SearchResultType.vehicle,
            primary: v.registrationNumber,
            secondary: '${v.make} ${v.model} — ${customer?.name ?? "Unknown"}',
            payload: v.vehicleId,
          ),
        );
      }
    }

    // Search invoices
    for (final inv in invoiceCtrl.invoices) {
      if (inv.invoiceId.toLowerCase().contains(q)) {
        final customer = customerCtrl.getCustomerById(inv.customerId);
        results.add(
          SearchResult(
            type: SearchResultType.invoice,
            primary: inv.invoiceId,
            secondary: customer?.name ?? "Unknown",
            payload: inv.invoiceId,
          ),
        );
      }
    }

    setState(() {
      _searchResults = results.take(10).toList();
      _isSearching = true;
    });
  }

  void _openResult(SearchResult result) {
    _searchFocusNode.unfocus();
    _searchController.clear();
    setState(() {
      _searchResults = [];
      _isSearching = false;
    });

    switch (result.type) {
      case SearchResultType.customer:
        Get.to(() => CustomerDetailScreen(customerId: result.payload));
        break;
      case SearchResultType.vehicle:
        Get.to(() => VehicleDetailScreen(vehicleId: result.payload));
        break;
      case SearchResultType.invoice:
        Get.to(() => InvoicePreviewScreen(invoiceId: result.payload));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isAndroid || Platform.isIOS) {
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.white, // background
          statusBarIconBrightness: Brightness.dark, // Android icons
          statusBarBrightness: Brightness.light, // iOS icons
        ),
      );
    }
    if (Responsive.isDesktop(context)) {
      return _buildDesktopDashboard();
    }

    return _buildMobileDashboard();
  }

  Widget _buildDesktopDashboard() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // =====================================================
          // UNIVERSAL SEARCH
          // =====================================================
          _buildSearchBar(),

          const SizedBox(height: 24),

          // =====================================================
          // KPI CARDS
          // =====================================================
          GetBuilder<CustomerController>(
            builder: (customerCtrl) {
              return GetBuilder<VehicleController>(
                builder: (vehicleCtrl) {
                  return GetBuilder<ItemController>(
                    builder: (itemCtrl) {
                      return GetBuilder<InvoiceController>(
                        builder: (invoiceCtrl) {
                          final totalRevenue = invoiceCtrl.invoices
                              .fold<double>(
                                0,
                                (sum, inv) => sum + inv.grandTotal,
                              );

                          return _buildKpiRow(
                            customerCtrl.customers.length,
                            vehicleCtrl.vehicles.length,
                            itemCtrl.items.length,
                            invoiceCtrl.invoices.length,
                            totalRevenue,
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          ),

          const SizedBox(height: 24),

          // =====================================================
          // MIDDLE SECTION
          // =====================================================
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // =====================================================
                // LEFT: RECENT INVOICES
                // =====================================================
                Expanded(flex: 3, child: _buildRecentInvoices()),

                const SizedBox(width: 24),

                // =====================================================
                // RIGHT: REMINDER PANEL
                // =====================================================
                Expanded(flex: 2, child: _buildReminderPanel()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileDashboard() {
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Dashboard",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
            ),

            const SizedBox(height: 12),

            _buildSearchBar(),

            const SizedBox(height: 12),

            _buildMobileKpis(),

            const SizedBox(height: 12),

            _buildMobileInvoices(),

            const SizedBox(height: 12),

            _buildMobileReminders(),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileKpis() => GetBuilder<CustomerController>(
    builder: (customerCtrl) {
      return GetBuilder<VehicleController>(
        builder: (vehicleCtrl) {
          return GetBuilder<ItemController>(
            builder: (itemCtrl) {
              return GetBuilder<InvoiceController>(
                builder: (invoiceCtrl) {
                  final totalRevenue = invoiceCtrl.invoices.fold<double>(
                    0,
                    (sum, inv) => sum + inv.grandTotal,
                  );

                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _kpiCard(
                              "Customers",
                              customerCtrl.customers.length.toString(),
                              Icons.people_outline,
                              () {},
                            ),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: _kpiCard(
                              "Vehicles",
                              vehicleCtrl.vehicles.length.toString(),
                              Icons.directions_car_outlined,
                              () {},
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: _kpiCard(
                              "Items",
                              itemCtrl.items.length.toString(),
                              Icons.inventory_2_outlined,
                              () {},
                            ),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: _kpiCard(
                              "Invoices",
                              invoiceCtrl.invoices.length.toString(),
                              Icons.receipt_outlined,
                              () {},
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      _kpiCard(
                        "Revenue",
                        "₹${totalRevenue.toStringAsFixed(2)}",
                        Icons.currency_rupee,
                        () {},
                        isRevenue: true,
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      );
    },
  );

  Widget _buildMobileInvoices() {
    return GetBuilder<InvoiceController>(
      builder: (invoiceCtrl) {
        final customerCtrl = Get.find<CustomerController>();
        final vehicleCtrl = Get.find<VehicleController>();

        final recentInvoices = invoiceCtrl.invoices.toList()
          ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

        final latest5 = recentInvoices.take(5).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Recent Invoices",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            if (latest5.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: Text("No invoices found")),
              )
            else
              ...latest5.map((inv) {
                final customer = customerCtrl.getCustomerById(inv.customerId);

                final vehicle = vehicleCtrl.getVehicleById(inv.vehicleId);

                return ErpMobileTile(
                  onTap: () {
                    Get.to(
                      () => InvoicePreviewScreen(invoiceId: inv.invoiceId),
                    );
                  },

                  leading: CircleAvatar(
                    backgroundColor: Colors.grey.shade100,
                    child: const Icon(
                      Icons.receipt_long,
                      color: Colors.black87,
                    ),
                  ),

                  title: inv.invoiceId,

                  subtitles: [
                    customer?.name ?? "Unknown Customer",
                    vehicle?.registrationNumber ?? "Unknown Vehicle",
                  ],

                  trailing: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,

                        children: [
                          SizedBox(height: 5),
                          Text(
                            '₹${inv.grandTotal.toStringAsFixed(0)}',

                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          Text(
                            formatDate(inv.dateTime),

                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),

                          const SizedBox(height: 8),
                        ],
                      ),
                      AppPopupMenu(
                        onEdit: () {
                          Get.to(() => CreateInvoiceScreen(invoice: inv));
                        },

                        onDelete: () {
                          showDialog(
                            context: context,

                            builder: (_) => DeleteConfirmationDialog(
                              title: 'Delete Invoice',

                              message:
                                  'Are you sure you want to delete '
                                  '${inv.invoiceId}?',

                              onDelete: () async {
                                await Get.find<InvoiceController>()
                                    .deleteInvoice(inv.invoiceId);
                              },
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              }),
          ],
        );
      },
    );
  }

  Widget _buildMobileReminders() {
    return GetBuilder<ReminderController>(
      builder: (reminderCtrl) {
        final overdue = reminderCtrl.getOverdueReminders();
        final dueThisWeek = reminderCtrl.getDueThisWeek();
        final dueThisMonth = reminderCtrl.getDueThisMonth();

        final allRelevant = <_ReminderGroup>{};

        for (final r in overdue) {
          allRelevant.add(_ReminderGroup(r, ReminderUrgency.overdue));
        }

        for (final r in dueThisWeek) {
          if (!allRelevant.any((g) => g.reminder.reminderId == r.reminderId)) {
            allRelevant.add(_ReminderGroup(r, ReminderUrgency.dueThisWeek));
          }
        }

        for (final r in dueThisMonth) {
          if (!allRelevant.any((g) => g.reminder.reminderId == r.reminderId)) {
            allRelevant.add(_ReminderGroup(r, ReminderUrgency.dueThisMonth));
          }
        }

        final sorted = allRelevant.toList()
          ..sort((a, b) => a.reminder.dueDate.compareTo(b.reminder.dueDate));

        final top5 = sorted.take(5).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Reminders',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            if (top5.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: Text('No pending reminders')),
              )
            else
              ...top5.map((group) => _buildMobileReminderTile(group)),
          ],
        );
      },
    );
  }

  Widget _buildMobileReminderTile(_ReminderGroup group) {
    final reminder = group.reminder;

    final vehicleCtrl = Get.find<VehicleController>();
    final customerCtrl = Get.find<CustomerController>();

    final vehicle = vehicleCtrl.getVehicleById(reminder.vehicleId);

    final customer = customerCtrl.getCustomerById(reminder.customerId);

    Color color;
    String label;

    switch (group.urgency) {
      case ReminderUrgency.overdue:
        color = Colors.red;
        label = 'Overdue';
        break;

      case ReminderUrgency.dueThisWeek:
        color = Colors.orange;
        label = 'This Week';
        break;

      case ReminderUrgency.dueThisMonth:
        color = Colors.blue;
        label = 'This Month';
        break;
    }

    return ErpMobileTile(
      onTap: () {},

      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.1),
        child: Icon(Icons.notifications_outlined, color: color),
      ),

      title: reminder.title,

      subtitles: [
        if (customer != null) customer.name,

        if (vehicle != null)
          '${vehicle.make} ${vehicle.model} \n${vehicle.registrationNumber}',

        // 'Due: '
        //     '${reminder.dueDate.day.toString().padLeft(2, '0')}-'
        //     '${reminder.dueDate.month.toString().padLeft(2, '0')}-'
        //     '${reminder.dueDate.year.toString()}',
        if (reminder.notes != null && reminder.notes!.trim().isNotEmpty)
          reminder.notes!,
      ],

      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${reminder.dueDate.day.toString().padLeft(2, '0')}-'
            '${reminder.dueDate.month.toString().padLeft(2, '0')}-'
            '${reminder.dueDate.year.toString().substring(2)}',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // SEARCH BAR
  // =====================================================
  Widget _buildSearchBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            onChanged: _performSearch,
            decoration: InputDecoration(
              hintText: 'Search customers, vehicles, invoices...',
              prefixIcon: const Icon(Icons.search, color: Colors.black54),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        _performSearch('');
                        _searchFocusNode.unfocus();
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        if (_isSearching && _searchResults.isNotEmpty) ...[
          const SizedBox(height: 4),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: _searchResults.map((result) {
                IconData icon;
                switch (result.type) {
                  case SearchResultType.customer:
                    icon = Icons.person_outline;
                    break;
                  case SearchResultType.vehicle:
                    icon = Icons.directions_car_outlined;
                    break;
                  case SearchResultType.invoice:
                    icon = Icons.receipt_outlined;
                    break;
                }
                return InkWell(
                  onTap: () => _openResult(result),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Icon(icon, size: 18, color: Colors.black54),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                result.primary,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                result.secondary,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            result.type.name,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }

  // =====================================================
  // KPI CARDS ROW
  // =====================================================
  Widget _buildKpiRow(
    int totalCustomers,
    int totalVehicles,
    int totalItems,
    int totalInvoices,
    double totalRevenue,
  ) {
    return Row(
      children: [
        Expanded(
          child: _kpiCard(
            "Total Customers",
            totalCustomers.toString(),
            Icons.people_outline,
            () {},
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _kpiCard(
            "Total Vehicles",
            totalVehicles.toString(),
            Icons.directions_car_outlined,
            () {},
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _kpiCard(
            "Total Items",
            totalItems.toString(),
            Icons.inventory_2_outlined,
            () {},
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _kpiCard(
            "Total Invoices",
            totalInvoices.toString(),
            Icons.receipt_outlined,
            () {},
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _kpiCard(
            "Total Revenue",
            "₹${totalRevenue.toStringAsFixed(2)}",
            Icons.currency_rupee,
            () {},
            isRevenue: true,
          ),
        ),
      ],
    );
  }

  Widget _kpiCard(
    String label,
    String value,
    IconData icon,
    VoidCallback onTap, {
    bool isRevenue = false,
  }) {
    final isMobile = Responsive.isMobile(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(isMobile ? 14 : 20),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: isMobile ? 18 : 20, color: Colors.black54),

                  const Spacer(),

                  if (isRevenue)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 5 : 6,
                        vertical: isMobile ? 1 : 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        "Revenue",
                        style: TextStyle(
                          fontSize: isMobile ? 8 : 9,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),

              SizedBox(height: isMobile ? 10 : 12),

              Text(
                value,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: isMobile
                      ? (isRevenue ? 16 : 20)
                      : (isRevenue ? 20 : 24),
                  fontWeight: FontWeight.bold,
                  color: isRevenue ? Colors.green.shade700 : Colors.black,
                ),
              ),

              SizedBox(height: isMobile ? 2 : 4),

              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: isMobile ? 11 : 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =====================================================
  // RECENT INVOICES TABLE
  // =====================================================
  Widget _buildRecentInvoices() {
    return GetBuilder<InvoiceController>(
      builder: (invoiceCtrl) {
        final customerCtrl = Get.find<CustomerController>();
        final vehicleCtrl = Get.find<VehicleController>();

        final recentInvoices = invoiceCtrl.invoices.toList()
          ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
        final latest5 = recentInvoices.take(5).toList();

        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.receipt_outlined,
                      size: 18,
                      color: Colors.black87,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "Recent Invoices",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      "Latest 5",
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              if (latest5.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text("No invoices found")),
                )
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    showCheckboxColumn: false,
                    headingRowHeight: 36,
                    dataRowMinHeight: 36,
                    dataRowMaxHeight: 44,
                    // columnSpacing: 24,
                    columns: const [
                      DataColumn(
                        label: Text(
                          "Invoice ID",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          "Customer",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          "Vehicle",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          "Total",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          "Date",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    rows: latest5.map((inv) {
                      final customer = customerCtrl.getCustomerById(
                        inv.customerId,
                      );
                      final vehicle = vehicleCtrl.getVehicleById(inv.vehicleId);
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
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              customer?.name ?? "Unknown",
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          DataCell(
                            Text(
                              vehicle?.registrationNumber ?? "Unknown",
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          DataCell(
                            Text(
                              "₹${inv.grandTotal.toStringAsFixed(2)}",
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          DataCell(
                            Text(
                              "${inv.dateTime.day.toString().padLeft(2, '0')}-"
                              "${inv.dateTime.month.toString().padLeft(2, '0')}-"
                              "${(inv.dateTime.year % 100).toString().padLeft(2, '0')}",
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // =====================================================
  // REMINDER PANEL
  // =====================================================
  Widget _buildReminderPanel() {
    return GetBuilder<ReminderController>(
      builder: (reminderCtrl) {
        final overdue = reminderCtrl.getOverdueReminders();
        final dueThisWeek = reminderCtrl.getDueThisWeek();
        final dueThisMonth = reminderCtrl.getDueThisMonth();

        // Combine and sort: overdue first, then due this week, then due this month
        final allRelevant = <_ReminderGroup>{};
        for (final r in overdue) {
          allRelevant.add(_ReminderGroup(r, ReminderUrgency.overdue));
        }
        for (final r in dueThisWeek) {
          if (!allRelevant.any((g) => g.reminder.reminderId == r.reminderId)) {
            allRelevant.add(_ReminderGroup(r, ReminderUrgency.dueThisWeek));
          }
        }
        for (final r in dueThisMonth) {
          if (!allRelevant.any((g) => g.reminder.reminderId == r.reminderId)) {
            allRelevant.add(_ReminderGroup(r, ReminderUrgency.dueThisMonth));
          }
        }

        final sorted = allRelevant.toList()
          ..sort((a, b) => a.reminder.dueDate.compareTo(b.reminder.dueDate));
        final top5 = sorted.take(5).toList();

        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.notifications_outlined,
                      size: 18,
                      color: Colors.black87,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "Reminders",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    if (overdue.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          "${overdue.length} overdue",
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Divider(height: 1, thickness: 1.2, color: Colors.grey.shade300),
              if (top5.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text("No pending reminders")),
                )
              else
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: top5.length,
                    // separatorBuilder: (_, _) =>
                    //     const Divider(height: 1, indent: 16, endIndent: 16),
                    itemBuilder: (context, i) {
                      final group = top5[i];
                      return _buildReminderTile(group);
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReminderTile(_ReminderGroup group) {
    final r = group.reminder;
    final vehicleCtrl = Get.find<VehicleController>();
    final customerCtrl = Get.find<CustomerController>();
    final vehicle = vehicleCtrl.getVehicleById(r.vehicleId);
    final customer = customerCtrl.getCustomerById(r.customerId);
    final vehicleInfo = vehicle != null
        ? '${vehicle.make} ${vehicle.model} (${vehicle.registrationNumber})'
        : null;
    final customerName = customer?.name;
    Color dotColor;
    Color bgColor;
    String label;

    switch (group.urgency) {
      case ReminderUrgency.overdue:
        dotColor = Colors.red;
        bgColor = Colors.red.shade50;
        label = "Overdue";
        break;
      case ReminderUrgency.dueThisWeek:
        dotColor = Colors.orange;
        bgColor = Colors.orange.shade50;
        label = "This week";
        break;
      case ReminderUrgency.dueThisMonth:
        dotColor = Colors.blue;
        bgColor = Colors.blue.shade50;
        label = "This month";
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 5,
                  decoration: BoxDecoration(
                    color: dotColor.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                r.title,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: bgColor,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 8,
                                    color: dotColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            "${r.dueDate.day.toString().padLeft(2, '0')}-"
                            "${r.dueDate.month.toString().padLeft(2, '0')}-"
                            "${r.dueDate.year}",
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      if (customerName != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 1),
                          child: Row(
                            children: [
                              Icon(
                                Icons.person_outline,
                                size: 12,
                                color: Colors.grey.shade900,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                customerName,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade900,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      if (vehicleInfo != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 1),
                          child: Row(
                            children: [
                              Icon(
                                Icons.directions_car_outlined,
                                size: 12,
                                color: Colors.grey.shade900,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                vehicleInfo,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade900,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      if (r.notes != null && r.notes!.isNotEmpty)
                        Text(
                          r.notes!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade900,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =====================================================
// SEARCH RESULT MODEL
// =====================================================
enum SearchResultType { customer, vehicle, invoice }

class SearchResult {
  final SearchResultType type;
  final String primary;
  final String secondary;
  final String payload;

  SearchResult({
    required this.type,
    required this.primary,
    required this.secondary,
    required this.payload,
  });
}

// =====================================================
// REMINDER GROUP MODEL
// =====================================================
enum ReminderUrgency { overdue, dueThisWeek, dueThisMonth }

class _ReminderGroup {
  final Reminder reminder;
  final ReminderUrgency urgency;

  _ReminderGroup(this.reminder, this.urgency);
}
