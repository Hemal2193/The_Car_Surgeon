import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '../database/hive_boxes.dart';
import '../models/sync_status.dart';
import '../models/vehicle_model.dart';
import '../services/supabase_sync_service.dart';

class VehicleController extends GetxController {
  final Box<Vehicle> vehicleBox = Hive.box<Vehicle>(HiveBoxes.vehicles);

  /// UI should only see active vehicles
  List<Vehicle> get vehicles =>
      vehicleBox.values.where((v) => !v.isDeleted).toList();

  /// Sync service will use this
  List<Vehicle> get allVehicles => vehicleBox.values.toList();

  Vehicle? getVehicleById(String id) {
    return vehicles.firstWhereOrNull((v) => v.vehicleId == id);
  }

  Future<void> addVehicle(Vehicle vehicle) async {
    vehicle.updatedAt = DateTime.now();
    vehicle.syncStatus = SyncStatus.pending;
    vehicle.isDeleted = false;

    await vehicleBox.put(vehicle.vehicleId, vehicle);

    update();
    Get.find<SupabaseSyncService>().syncVehicles();
  }

  Future<void> updateVehicle(Vehicle vehicle) async {
    vehicle.updatedAt = DateTime.now();
    vehicle.syncStatus = SyncStatus.pending;

    await vehicleBox.put(vehicle.vehicleId, vehicle);

    update();
    Get.find<SupabaseSyncService>().syncVehicles();
  }

  Future<void> deleteVehicle(String vehicleId) async {
    final vehicle = vehicleBox.get(vehicleId);

    if (vehicle == null) return;

    vehicle.isDeleted = true;
    vehicle.updatedAt = DateTime.now();
    vehicle.syncStatus = SyncStatus.pending;

    await vehicle.save();

    update();
    Get.find<SupabaseSyncService>().syncVehicles();
  }

  int getVehicleCountForCustomer(String customerId) {
    return vehicles.where((vehicle) => vehicle.customerId == customerId).length;
  }

  /// ==========================
  /// SUPABASE SYNC HELPERS
  /// ==========================

  List<Vehicle> getPendingVehicles() {
    return allVehicles
        .where((v) => v.syncStatus == SyncStatus.pending)
        .toList();
  }

  Future<void> markAsSynced(String vehicleId) async {
    final vehicle = vehicleBox.get(vehicleId);

    if (vehicle == null) return;

    vehicle.syncStatus = SyncStatus.synced;

    await vehicle.save();

    update();
  }

  Future<void> upsertFromRemote(Vehicle remoteVehicle) async {
    final local = vehicleBox.get(remoteVehicle.vehicleId);

    if (local == null || remoteVehicle.updatedAt.isAfter(local.updatedAt)) {
      remoteVehicle.syncStatus = SyncStatus.synced;

      await vehicleBox.put(remoteVehicle.vehicleId, remoteVehicle);

      update();
    }
  }
}
