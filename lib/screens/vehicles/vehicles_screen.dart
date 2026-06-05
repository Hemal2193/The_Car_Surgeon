import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:tcs/controllers/vehicle_controller.dart';

import 'package:tcs/models/customer_model.dart';
import 'package:tcs/models/vehicle_model.dart';

import 'package:tcs/screens/vehicles/add_vehicle_dialog.dart';
import 'package:tcs/services/customer_cache.dart';

import 'package:tcs/widgets/adder_button.dart';
import 'package:tcs/widgets/app_popup_menu.dart';
import 'package:tcs/widgets/delete_confirmation_dialog.dart';

class VehiclesScreen extends StatelessWidget {
  const VehiclesScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                if (vehicleController.vehicles.isEmpty) {
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
                      columns: const [
                        DataColumn(label: Text('Vehicle ID')),
                        DataColumn(label: Text('Registration No')),
                        DataColumn(label: Text('Customer')),
                        DataColumn(label: Text('Make')),
                        DataColumn(label: Text('Model')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: vehicleController.vehicles.map((vehicle) {
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

  DataRow buildVehicleRow(BuildContext context, Vehicle vehicle) {
    // final customerController = Get.find<CustomerController>();

    Customer? customer;

    try {
      customer = CustomerCache.getById(vehicle.customerId);
    } catch (_) {
      customer = null;
    }

    return DataRow(
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
              print('Edit ${vehicle.vehicleId}');
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
