import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:tcs/controllers/vehicle_controller.dart';

import 'package:tcs/models/customer_model.dart';
import 'package:tcs/models/vehicle_model.dart';

import 'package:tcs/screens/vehicles/add_vehicle_dialog.dart';
import 'package:tcs/screens/vehicles/vehicle_detail_screen.dart';
import 'package:tcs/services/customer_cache.dart';
import 'package:tcs/utils/responsive.dart';

import 'package:tcs/widgets/adder_button.dart';
import 'package:tcs/widgets/app_popup_menu.dart';
import 'package:tcs/widgets/delete_confirmation_dialog.dart';
import 'package:tcs/widgets/erp_mobile_tile.dart';

class VehiclesScreen extends StatefulWidget {
  const VehiclesScreen({super.key});

  @override
  State<VehiclesScreen> createState() => _VehiclesScreenState();
}

class _VehiclesScreenState extends State<VehiclesScreen> {
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
      return _buildDesktopVehicles();
    }

    return _buildMobileVehicles();
  }

  Widget _buildDesktopVehicles() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                'Vehicles',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),

              const Spacer(),

              adderButton(
                label: 'Add Vehicle',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return const AddVehicleDialog();
                    },
                  );
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
              hintText: 'Search vehicle...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),

          const SizedBox(height: 20),

          Expanded(
            child: GetBuilder<VehicleController>(
              builder: (vehicleController) {
                final vehicles = vehicleController.vehicles.where((vehicle) {
                  if (_searchQuery.isEmpty) return true;

                  final customer = CustomerCache.getById(vehicle.customerId);

                  return vehicle.vehicleId.toLowerCase().contains(
                        _searchQuery,
                      ) ||
                      vehicle.registrationNumber.toLowerCase().contains(
                        _searchQuery,
                      ) ||
                      vehicle.make.toLowerCase().contains(_searchQuery) ||
                      vehicle.model.toLowerCase().contains(_searchQuery) ||
                      (customer?.name ?? '').toLowerCase().contains(
                        _searchQuery,
                      );
                }).toList();

                if (vehicles.isEmpty) {
                  return Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(child: Text('No vehicles found')),
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
                        DataColumn(label: Text('Vehicle ID')),
                        DataColumn(label: Text('Registration No')),
                        DataColumn(label: Text('Customer')),
                        DataColumn(label: Text('Make')),
                        DataColumn(label: Text('Model')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: vehicles.map((vehicle) {
                        return buildVehicleRow(context, vehicle);
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

  Widget _buildMobileVehicles() {
    return
    // backgroundColor: Colors.transparent,
    // extendBody: true,
    // floatingActionButton: FloatingActionButton.extended(
    //   label: Text("Add Vehicle"),
    //   icon: const Icon(Icons.add),
    //   backgroundColor: Colors.black,
    //   foregroundColor: Colors.white,
    //   onPressed: () {
    //     showModalBottomSheet(
    //       context: context,
    //       isScrollControlled: true,
    //       isDismissible: true,
    //       enableDrag: true,
    //       backgroundColor: Colors.transparent,
    //       builder: (_) => AddVehicleDialog(),
    //     );
    //   },
    // ),
    SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Column(
          children: [
            _buildMobileHeader(),

            const SizedBox(height: 16),

            _buildSearch(),

            const SizedBox(height: 16),

            Expanded(child: _buildMobileVehicleList()),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileHeader() {
    return const Align(
      alignment: Alignment.centerLeft,
      child: Text(
        'Vehicles',
        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildSearch() {
    return TextField(
      controller: _searchController,
      onChanged: (value) {
        setState(() {
          _searchQuery = value.trim().toLowerCase();
        });
      },
      decoration: InputDecoration(
        hintText: 'Search vehicle...',
        prefixIcon: const Icon(Icons.search),

        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }

  Widget _buildMobileVehicleList() {
    return GetBuilder<VehicleController>(
      builder: (vehicleController) {
        final vehicles = vehicleController.vehicles.where((vehicle) {
          if (_searchQuery.isEmpty) {
            return true;
          }

          final customer = CustomerCache.getById(vehicle.customerId);

          return vehicle.vehicleId.toLowerCase().contains(_searchQuery) ||
              vehicle.registrationNumber.toLowerCase().contains(_searchQuery) ||
              vehicle.make.toLowerCase().contains(_searchQuery) ||
              vehicle.model.toLowerCase().contains(_searchQuery) ||
              (customer?.name ?? '').toLowerCase().contains(_searchQuery);
        }).toList();

        if (vehicles.isEmpty) {
          return const Center(child: Text('No vehicles found'));
        }

        return ListView.builder(
          padding: EdgeInsets.only(bottom: 150),

          itemCount: vehicles.length,

          itemBuilder: (context, index) {
            return _buildVehicleTile(vehicles[vehicles.length - index - 1]);
          },
        );
      },
    );
  }

  Widget _buildVehicleTile(Vehicle vehicle) {
    Customer? customer;

    try {
      customer = CustomerCache.getById(vehicle.customerId);
    } catch (_) {
      customer = null;
    }

    return ErpMobileTile(
      onTap: () {
        Get.to(() => VehicleDetailScreen(vehicleId: vehicle.vehicleId));
      },

      leading: CircleAvatar(
        backgroundColor: Colors.grey.shade100,

        child: const Icon(Icons.directions_car, color: Colors.black87),
      ),

      // title: vehicle.registrationNumber,
      title: '${vehicle.make} ${vehicle.model}',

      subtitles: [
        customer?.name ?? 'Unknown Customer',

        // '${vehicle.make} ${vehicle.model}',
        (vehicle.registrationNumber),

        // vehicle.fuelType,
      ],

      trailing: AppPopupMenu(
        onEdit: () {
          showModalBottomSheet(
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
                  return AddVehicleDialog(scrollController: scrollController);
                },
              );
            },
          );
        },

        onDelete: () {
          showDialog(
            context: context,

            builder: (_) {
              return DeleteConfirmationDialog(
                title: 'Delete Vehicle',

                message:
                    'Are you sure you want to delete '
                    '${vehicle.registrationNumber}?',

                onDelete: () async {
                  await Get.find<VehicleController>().deleteVehicle(
                    vehicle.vehicleId,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  DataRow buildVehicleRow(BuildContext context, Vehicle vehicle) {
    // final customerController = Get.find<CustomerController>();

    Customer? customer;

    try {
      customer = CustomerCache.getById(vehicle.customerId);
    } catch (_) {
      customer = null;
    }

    return DataRow(
      onSelectChanged: (selected) {
        if (selected == true) {
          Get.to(() => VehicleDetailScreen(vehicleId: vehicle.vehicleId));
        }
      },
      cells: [
        DataCell(
          Text(
            vehicle.vehicleId,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),

        DataCell(Text(vehicle.registrationNumber)),

        DataCell(Text(customer?.name ?? 'Unknown Customer')),

        DataCell(Text(vehicle.make)),

        DataCell(Text(vehicle.model)),

        DataCell(
          AppPopupMenu(
            onEdit: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AddVehicleDialog(vehicle: vehicle);
                },
              );
            },

            onDelete: () {
              showDialog(
                context: context,
                builder: (dialogContext) {
                  return DeleteConfirmationDialog(
                    title: 'Delete Vehicle',
                    message:
                        'Are you sure you want to delete ${vehicle.registrationNumber}?',
                    onDelete: () async {
                      final vehicleController = Get.find<VehicleController>();

                      await vehicleController.deleteVehicle(vehicle.vehicleId);
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
