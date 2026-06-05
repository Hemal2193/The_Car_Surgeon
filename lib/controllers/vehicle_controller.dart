import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '../database/hive_boxes.dart';
import '../models/vehicle_model.dart';

class VehicleController extends GetxController {
  final Box<Vehicle> vehicleBox = Hive.box<Vehicle>(HiveBoxes.vehicles);

  List<Vehicle> get vehicles => vehicleBox.values.toList();

  Vehicle? getVehicleById(String id) {
    return vehicles.firstWhereOrNull((v) => v.vehicleId == id);
  }

  Future<void> addVehicle(Vehicle vehicle) async {
    await vehicleBox.put(vehicle.vehicleId, vehicle);

    update();
  }

  Future<void> deleteVehicle(String vehicleId) async {
    await vehicleBox.delete(vehicleId);

    update();
  }

  int getVehicleCountForCustomer(String customerId) {
    return vehicleBox.values
        .where((vehicle) => vehicle.customerId == customerId)
        .length;
  }
}
