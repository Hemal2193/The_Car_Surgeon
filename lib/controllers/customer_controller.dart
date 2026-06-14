import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:tcs/models/sync_status.dart';

import '../database/hive_boxes.dart';
import '../models/customer_model.dart';
import '../services/customer_cache.dart';
import '../services/supabase_sync_service.dart';

class CustomerController extends GetxController {
  final Box<Customer> customerBox = Hive.box<Customer>(HiveBoxes.customers);

  /// SINGLE SOURCE OF TRUTH
  List<Customer> get customers =>
      customerBox.values.where((c) => !c.isDeleted).toList();

  List<Customer> get allCustomers => customerBox.values.toList();
  Customer? getCustomerById(String id) {
    return customers.firstWhereOrNull((c) => c.customerId == id);
  }

  /// CALL ON APP START
  void initCache() {
    CustomerCache.build(customers);
  }

  Future<void> addCustomer(Customer customer) async {
    customer.updatedAt = DateTime.now();
    customer.syncStatus = SyncStatus.pending;
    customer.isDeleted = false;

    await customerBox.put(customer.customerId, customer);

    _refreshCacheAndUI();
    Get.find<SupabaseSyncService>().syncCustomers();
  }

  Future<void> updateCustomer(Customer customer) async {
    customer.updatedAt = DateTime.now();
    customer.syncStatus = SyncStatus.pending;

    await customerBox.put(customer.customerId, customer);

    _refreshCacheAndUI();
    Get.find<SupabaseSyncService>().syncCustomers();
  }

  Future<void> deleteCustomer(String id) async {
    final customer = customerBox.get(id);

    if (customer == null) return;

    customer.isDeleted = true;
    customer.updatedAt = DateTime.now();
    customer.syncStatus = SyncStatus.pending;

    await customer.save();
    print("Customer deleted: $id");

    _refreshCacheAndUI();
    Get.find<SupabaseSyncService>().syncCustomers();
  }

  List<Customer> getPendingCustomers() {
    return allCustomers
        .where((c) => c.syncStatus == SyncStatus.pending)
        .toList();
  }

  Future<void> markAsSynced(String customerId) async {
    final customer = customerBox.get(customerId);

    if (customer == null) return;

    customer.syncStatus = SyncStatus.synced;

    await customer.save();

    _refreshCacheAndUI();
  }

  Future<void> upsertFromRemote(Customer remoteCustomer) async {
    final local = customerBox.get(remoteCustomer.customerId);

    if (local == null || remoteCustomer.updatedAt.isAfter(local.updatedAt)) {
      remoteCustomer.syncStatus = SyncStatus.synced;

      await customerBox.put(remoteCustomer.customerId, remoteCustomer);

      update();
    }
  }

  void _refreshCacheAndUI() {
    CustomerCache.build(customers);
    update();
  }
}
