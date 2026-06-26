import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tcs/models/invoice_payment_status.dart';
import 'package:tcs/screens/invoices/invoice_preview_screen.dart';
import 'package:tcs/screens/invoices/create_invoice_screen.dart';
import 'package:tcs/screens/vehicles/add_vehicle_dialog.dart';
import 'package:tcs/utils/responsive.dart';
import 'package:tcs/widgets/app_popup_menu.dart';
import 'package:tcs/widgets/app_titlebar.dart';
import 'package:tcs/widgets/custom_button.dart';
import 'package:tcs/widgets/delete_confirmation_dialog.dart';
import 'package:tcs/widgets/erp_mobile_tile.dart';

import '../../controllers/customer_controller.dart';
import '../../controllers/vehicle_controller.dart';
import '../../controllers/invoice_controller.dart';

import '../../models/customer_model.dart';
import '../../models/vehicle_model.dart';
import '../../models/invoice_model.dart';

class VehicleDetailScreen extends StatelessWidget {
  final String vehicleId;

  const VehicleDetailScreen({super.key, required this.vehicleId});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<VehicleController>(
      builder: (_) {
        return GetBuilder<CustomerController>(
          builder: (_) {
            return GetBuilder<InvoiceController>(
              builder: (_) {
                if (Responsive.isDesktop(context)) {
                  return _buildDesktopVehicles(context);
                }

                return _buildMobileVehicleDetails(context);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildDesktopVehicles(BuildContext context) {
    final vehicleController = Get.find<VehicleController>();
    final customerController = Get.find<CustomerController>();
    final invoiceController = Get.find<InvoiceController>();

    final Vehicle? vehicle = vehicleController.getVehicleById(vehicleId);

    if (vehicle == null) {
      return const Scaffold(body: Center(child: Text("Vehicle not found")));
    }

    final Customer? customer = customerController.getCustomerById(
      vehicle.customerId,
    );

    final List<Invoice> invoices = invoiceController.invoices
        .where((i) => i.vehicleId == vehicle.vehicleId)
        .toList();

    double totalRevenue = 0;

    for (final invoice in invoices) {
      totalRevenue += invoice.grandTotal;
    }
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const AppTitleBar(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // =====================================================
                  // HEADER
                  // =====================================================
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Get.back(),
                        icon: const Icon(Icons.arrow_back),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        "Vehicle Details",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      cButton(
                        () {
                          showDialog(
                            context: context,
                            builder: (context) {
                              return AddVehicleDialog(vehicle: vehicle);
                            },
                          );
                        },
                        'Edit Vehicle',
                        true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          // =====================================================
                          // STATS
                          // =====================================================
                          Row(
                            children: [
                              Expanded(
                                child: _statCard(
                                  "Invoices",
                                  invoices.length.toString(),
                                  Icons.receipt_long,
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: _statCard(
                                  "Revenue",
                                  "₹${totalRevenue.toStringAsFixed(2)}",
                                  Icons.currency_rupee,
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: _statCard(
                                  "Customer",
                                  customer?.name ?? "-",
                                  Icons.person_outline,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // =====================================================
                          // VEHICLE CARD
                          // =====================================================
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  vehicle.registrationNumber,
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  vehicle.vehicleId,
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                                const SizedBox(height: 25),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _infoTile("Make", vehicle.make),
                                    ),
                                    const SizedBox(width: 15),
                                    Expanded(
                                      child: _infoTile("Model", vehicle.model),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 15),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _infoTile(
                                        "Registration Number",
                                        vehicle.registrationNumber,
                                      ),
                                    ),
                                    const SizedBox(width: 15),
                                    Expanded(
                                      child: _infoTile(
                                        "Fuel Type",
                                        vehicle.fuelType,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 15),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _infoTile(
                                        "Vehicle Color",
                                        vehicle.vehicleColor ?? "-",
                                      ),
                                    ),
                                    const SizedBox(width: 15),
                                    Expanded(
                                      child: _infoTile(
                                        "Engine Number",
                                        vehicle.engineNumber ?? "-",
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 15),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _infoTile(
                                        "Chassis Number",
                                        vehicle.chassisNumber ?? "-",
                                      ),
                                    ),
                                    const SizedBox(width: 15),
                                    Expanded(
                                      child: _infoTile(
                                        "Customer",
                                        customer?.name ?? "-",
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          // =====================================================
                          // CUSTOMER CARD
                          // =====================================================
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  customer!.name,
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  customer.customerId,
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                                const SizedBox(height: 25),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _infoTile(
                                        "Primary Contact",
                                        customer.contact1,
                                      ),
                                    ),
                                    const SizedBox(width: 15),
                                    Expanded(
                                      child: _infoTile(
                                        "Secondary Contact",
                                        customer.contact2 ?? "-",
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 15),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _infoTile(
                                        "Email",
                                        customer.email ?? "-",
                                      ),
                                    ),
                                    const SizedBox(width: 15),
                                    Expanded(
                                      child: _infoTile(
                                        "GST Number",
                                        customer.gstNumber ?? "-",
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 15),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _infoTile(
                                        "PAN Number",
                                        customer.panNumber ?? "-",
                                      ),
                                    ),
                                    const SizedBox(width: 15),
                                    Expanded(
                                      child: _infoTile(
                                        "Address",
                                        customer.address ?? "-",
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          // =====================================================
                          // INVOICES
                          // =====================================================
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Invoices",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: invoices.isEmpty
                                ? const Padding(
                                    padding: EdgeInsets.all(30),
                                    child: Center(
                                      child: Text("No invoices found"),
                                    ),
                                  )
                                : SingleChildScrollView(
                                    child: DataTable(
                                      showCheckboxColumn: false,
                                      columns: const [
                                        DataColumn(label: Text("Invoice ID")),
                                        DataColumn(label: Text("Items")),
                                        DataColumn(label: Text("Balance")),
                                        DataColumn(label: Text("Date")),
                                        DataColumn(label: Text("Actions")),
                                      ],
                                      rows: invoices.map((invoice) {
                                        return DataRow(
                                          onSelectChanged: (selected) {
                                            if (selected == true) {
                                              Get.to(
                                                () => InvoicePreviewScreen(
                                                  invoiceId: invoice.invoiceId,
                                                ),
                                              );
                                            }
                                          },
                                          cells: [
                                            DataCell(Text(invoice.invoiceId)),
                                            DataCell(
                                              Text(
                                                invoice.items.length.toString(),
                                              ),
                                            ),
                                            DataCell(
                                              Text(
                                                invoice.balanceAmount
                                                    .toStringAsFixed(2),
                                              ),
                                            ),
                                            DataCell(
                                              Text(
                                                invoice.dateTime
                                                    .toString()
                                                    .split(' ')
                                                    .first,
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
                                                        () =>
                                                            CreateInvoiceScreen(
                                                              invoice: invoice,
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
                                                        builder: (_) => DeleteConfirmationDialog(
                                                          title:
                                                              "Delete Invoice",
                                                          message:
                                                              "Are you sure you want to delete ${invoice.invoiceId}?",
                                                          onDelete: () async {
                                                            await invoiceController
                                                                .deleteInvoice(
                                                                  invoice
                                                                      .invoiceId,
                                                                );
                                                          },
                                                        ),
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
                          ),
                        ],
                      ),
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

  Widget _buildMobileVehicleDetails(BuildContext context) {
    final vehicleController = Get.find<VehicleController>();
    final customerController = Get.find<CustomerController>();
    final invoiceController = Get.find<InvoiceController>();

    final Vehicle? vehicle = vehicleController.getVehicleById(vehicleId);

    if (vehicle == null) {
      return const Scaffold(body: Center(child: Text("Vehicle not found")));
    }

    final Customer? customer = customerController.getCustomerById(
      vehicle.customerId,
    );

    final List<Invoice> invoices = invoiceController.invoices
        .where((i) => i.vehicleId == vehicle.vehicleId)
        .toList();

    double totalRevenue = 0;
    for (final i in invoices) {
      totalRevenue += i.grandTotal;
    }

    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: Get.back,
          icon: const Icon(Icons.arrow_back, color: Colors.black),
        ),
        title: const Text(
          "Vehicle Details",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => AddVehicleDialog(vehicle: vehicle),
              );
            },
            icon: const Icon(Icons.edit_outlined, color: Colors.black),
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: 24,
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMobileVehicleCard(vehicle, customer),

            const SizedBox(height: 20),

            _buildMobileStats(vehicle, invoices, totalRevenue, customer),

            const SizedBox(height: 20),

            _buildMobileCustomerCard(customer),

            const SizedBox(height: 20),

            _buildMobileInvoices(context, invoices, invoiceController),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileStats(
    Vehicle vehicle,
    List<Invoice> invoices,
    double revenue,
    Customer? customer,
  ) {
    DateTime? getLastServiceDate(List invoices, String vehicleId) {
      final vehicleInvoices = invoices
          .where((inv) => inv.vehicleId == vehicleId)
          .toList();

      if (vehicleInvoices.isEmpty) return null;

      vehicleInvoices.sort((a, b) => b.dateTime.compareTo(a.dateTime));

      return vehicleInvoices.first.dateTime;
    }

    final lastService = getLastServiceDate(invoices, vehicle.vehicleId);

    return Row(
      children: [
        Expanded(
          child: _mobileStatCard(
            invoices.length.toString(),
            "Invoices",
            Icons.receipt_long_outlined,
          ),
        ),
        const SizedBox(width: 12),

        Expanded(
          child: _mobileStatCard(
            "₹${revenue.toStringAsFixed(0)}",
            "Revenue",
            Icons.currency_rupee,
          ),
        ),
        const SizedBox(width: 12),

        Expanded(
          child: _mobileStatCard(
            lastService != null
                ? formatDate(lastService)
                // ? "${lastService.day.toString().padLeft(2, '0')}-"
                //       "${lastService.month.toString().padLeft(2, '0')}-"
                //       "${lastService.year.toString().substring(2)}"
                : "New",
            "Last Service",
            Icons.build_outlined,
          ),
        ),
      ],
    );
  }

  Widget _mobileStatCard(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: Colors.black87),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileVehicleCard(Vehicle vehicle, Customer? customer) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            vehicle.registrationNumber,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 4),

          Text(
            vehicle.vehicleId,
            style: TextStyle(color: Colors.grey.shade600),
          ),

          const SizedBox(height: 20),

          _mobileInfoTile(Icons.directions_car, "Make", vehicle.make),

          _mobileInfoTile(Icons.model_training, "Model", vehicle.model),

          _mobileInfoTile(Icons.speed, "Odometer", vehicle.odoMeter ?? ''),

          _mobileInfoTile(Icons.local_gas_station, "Fuel", vehicle.fuelType),

          _mobileInfoTile(
            Icons.color_lens,
            "Color",
            vehicle.vehicleColor ?? "-",
          ),

          _mobileInfoTile(
            Icons.engineering,
            "Engine No",
            vehicle.engineNumber ?? "-",
          ),

          _mobileInfoTile(
            Icons.confirmation_number,
            "Chassis No",
            vehicle.chassisNumber ?? "-",
          ),
        ],
      ),
    );
  }

  Widget _buildMobileCustomerCard(Customer? customer) {
    bool isNotEmpty(String? value) {
      return value != null && value.trim().isNotEmpty;
    }

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),

        borderRadius: BorderRadius.circular(16),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Text(
            customer!.name,

            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 4),

          Text(
            customer.customerId,

            style: TextStyle(color: Colors.grey.shade600),
          ),

          const SizedBox(height: 20),

          _mobileInfoTile(Icons.phone_outlined, "Contact 1", customer.contact1),

          if (isNotEmpty(customer.contact2))
            _mobileInfoTile(
              Icons.phone_outlined,
              "Contact 2",
              customer.contact2!,
            ),

          if (isNotEmpty(customer.email))
            _mobileInfoTile(Icons.email_outlined, "Email", customer.email!),

          if (isNotEmpty(customer.gstNumber))
            _mobileInfoTile(
              Icons.receipt_long_outlined,
              "GST No",
              customer.gstNumber!,
            ),

          if (isNotEmpty(customer.panNumber))
            _mobileInfoTile(
              Icons.badge_outlined,
              "PAN No",
              customer.panNumber!,
            ),

          if (isNotEmpty(customer.address))
            _mobileInfoTile(
              Icons.location_on_outlined,
              "Address",
              customer.address!,
            ),
        ],
      ),
    );
  }

  Widget _buildMobileInvoices(
    BuildContext context,
    List<Invoice> invoices,
    InvoiceController invoiceController,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Invoices",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 12),

        if (invoices.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(child: Text("No invoices found")),
          )
        else
          Column(
            children: invoices.map((invoice) {
              return ErpMobileTile(
                onTap: () {
                  Get.to(
                    () => InvoicePreviewScreen(invoiceId: invoice.invoiceId),
                  );
                },

                leading: CircleAvatar(
                  backgroundColor: Colors.grey.shade100,

                  child: const Icon(Icons.receipt_long, color: Colors.black87),
                ),

                title: invoice.invoiceId,

                subtitles: [
                  '${invoice.items.length} items',

                  formatDate(invoice.dateTime),
                ],

                trailing: Row(
                  // mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      children: [
                        Text(
                          '₹${invoice.balanceAmount.toStringAsFixed(0)}',

                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 5),
                        Container(
                          width: 50,
                          decoration: BoxDecoration(
                            color: invoice.paymentStatus.color.withOpacity(0.1),

                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            child: Center(
                              child: Text(
                                invoice.paymentStatus.label,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: invoice.paymentStatus.color,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // const SizedBox(width: 5),
                    AppPopupMenu(
                      options: [
                        AppPopupMenuOption(
                          icon: Icons.edit_outlined,
                          label: 'Edit',
                          onTap: () {
                            Get.to(() => CreateInvoiceScreen(invoice: invoice));
                          },
                        ),

                        AppPopupMenuOption(
                          icon: Icons.delete_outline,
                          label: 'Delete',
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (_) {
                                return DeleteConfirmationDialog(
                                  title: 'Delete Invoice',

                                  message:
                                      'Are you sure you want to delete '
                                      '${invoice.invoiceId}?',

                                  onDelete: () async {
                                    await invoiceController.deleteInvoice(
                                      invoice.invoiceId,
                                    );
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _mobileInfoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Icon(icon, size: 18, color: Colors.grey.shade700),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Table(
              columnWidths: const {
                0: IntrinsicColumnWidth(), // label auto sizes to longest label
                1: FixedColumnWidth(8), // spacing column
                2: FlexColumnWidth(), // value takes remaining space
              },
              children: [
                TableRow(
                  children: [
                    Text(
                      "$label :",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(), // spacer column
                    Text(value, style: const TextStyle(fontSize: 15)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _infoTile(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  static Widget _statCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(title),
        ],
      ),
    );
  }

  String formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString().substring(2);

    return "$day-$month-$year";
  }
}
