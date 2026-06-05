import '../models/customer_model.dart';

class CustomerCache {
  static final Map<String, Customer> _byId = {};
  static final Map<String, Customer> _byName = {};

  /// Call this after loading customers from Hive
  static void build(List<Customer> customers) {
    _byId.clear();
    _byName.clear();

    for (final c in customers) {
      _byId[c.customerId] = c;
      _byName[c.name.toLowerCase()] = c;
    }
  }

  static Customer? getById(String id) {
    return _byId[id];
  }

  static Customer? getByName(String name) {
    return _byName[name.toLowerCase()];
  }

  static List<Customer> search(String query, List<Customer> source) {
    final q = query.toLowerCase();

    return source.where((c) {
      return c.name.toLowerCase().contains(q) ||
          c.customerId.toLowerCase().contains(q) ||
          (c.contact1).contains(q);
    }).toList();
  }
}
