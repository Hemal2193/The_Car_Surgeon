import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '../database/hive_boxes.dart';
import '../models/customer_model.dart';
import '../services/customer_cache.dart';

class CustomerController extends GetxController {
  final Box<Customer> customerBox = Hive.box<Customer>(HiveBoxes.customers);

  /// SINGLE SOURCE OF TRUTH
  List<Customer> get customers => customerBox.values.toList();

  Customer? getCustomerById(String id) {
    return customers.firstWhereOrNull((c) => c.customerId == id);
  }

  /// CALL ON APP START
  void initCache() {
    CustomerCache.build(customers);
  }

  Future<void> addCustomer(Customer customer) async {
    await customerBox.put(customer.customerId, customer);

    _refreshCacheAndUI();
  }

  Future<void> updateCustomer(Customer customer) async {
    await customerBox.put(customer.customerId, customer);

    _refreshCacheAndUI();
  }

  Future<void> deleteCustomer(String id) async {
    await customerBox.delete(id);

    _refreshCacheAndUI();
  }

  void _refreshCacheAndUI() {
    CustomerCache.build(customers);
    update();
  }
}
