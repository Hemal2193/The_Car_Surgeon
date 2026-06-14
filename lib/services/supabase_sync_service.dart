// import 'dart:async';
// import 'package:get/get.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// import '../controllers/customer_controller.dart';
// import '../controllers/vehicle_controller.dart';
// import '../controllers/item_controller.dart';
// import '../controllers/invoice_controller.dart';
// import '../controllers/reminder_controller.dart';

// import '../models/customer_model.dart';
// import '../models/vehicle_model.dart';
// import '../models/item_model.dart';
// import '../models/invoice_model.dart';
// import '../models/reminder_model.dart';

// import '../models/sync_status.dart';

// class SupabaseSyncService {
//   final SupabaseClient supabase = Supabase.instance.client;

//   Timer? _timer;
//   bool _isSyncing = false;

//   /// call once in main()
//   void init() {
//     print("Supabase sync service initialized");
//     startRealtimeSync();
//     // initial sync

//     // periodic sync every 2 minutes (recommended)
//     _timer = Timer.periodic(const Duration(minutes: 2), (_) {
//       syncAll();
//     });
//   }

//   void startRealtimeSync() {
//     supabase
//         .channel('public-sync')
//         .onPostgresChanges(
//           event: PostgresChangeEvent.all,
//           schema: 'public',
//           table: 'customers',
//           callback: (payload) {
//             syncAll(); // or smarter partial sync
//           },
//         )
//         .subscribe();
//   }

//   void dispose() {
//     _timer?.cancel();
//   }

//   // =====================================================
//   // MAIN SYNC ENTRY
//   // =====================================================
//   Future<void> syncAll() async {
//     if (_isSyncing) return;

//     _isSyncing = true;

//     try {
//       await _syncCustomers();
//       await _syncVehicles();
//       await _syncItems();
//       await _syncInvoices();
//       await _syncReminders();
//     } catch (e) {
//       print("SYNC ERROR: $e");
//     }

//     _isSyncing = false;
//   }

//   // =====================================================
//   // CUSTOMERS
//   // =====================================================
//   Future<void> _syncCustomers() async {
//     final controller = Get.find<CustomerController>();

//     final pending = controller.customers
//         .where((c) => c.syncStatus != SyncStatus.synced)
//         .toList();

//     for (final c in pending) {
//       try {
//         await supabase.from('customers').upsert({
//           'customer_id': c.customerId,
//           'name': c.name,
//           'contact1': c.contact1,
//           'contact2': c.contact2,
//           'address': c.address,
//           'email': c.email,
//           'gst_number': c.gstNumber,
//           'pan_number': c.panNumber,
//           'updated_at': c.updatedAt.toIso8601String(),
//           'is_deleted': c.isDeleted,
//         });

//         controller.markAsSynced(c.customerId);
//       } catch (e) {
//         print("Customer sync error: $e");
//       }
//     }

//     final remote = await supabase.from('customers').select();

//     for (final r in remote) {
//       final customer = Customer(
//         customerId: r['customer_id'],
//         name: r['name'],
//         contact1: r['contact1'],
//         contact2: r['contact2'],
//         address: r['address'],
//         email: r['email'],
//         gstNumber: r['gst_number'],
//         panNumber: r['pan_number'],
//       );

//       customer.updatedAt = DateTime.parse(r['updated_at']);
//       customer.isDeleted = r['is_deleted'] ?? false;
//       customer.syncStatus = SyncStatus.synced;

//       controller.upsertFromRemote(customer);
//     }
//   }

//   // =====================================================
//   // VEHICLES
//   // =====================================================
//   Future<void> _syncVehicles() async {
//     final controller = Get.find<VehicleController>();

//     final pending = controller.vehicles
//         .where((v) => v.syncStatus != SyncStatus.synced)
//         .toList();

//     for (final v in pending) {
//       try {
//         await supabase.from('vehicles').upsert({
//           'vehicle_id': v.vehicleId,
//           'customer_id': v.customerId,
//           'registration_number': v.registrationNumber,
//           'make': v.make,
//           'model': v.model,
//           'vehicle_color': v.vehicleColor,
//           'fuel_type': v.fuelType,
//           'chassis_number': v.chassisNumber,
//           'engine_number': v.engineNumber,
//           'odo_meter': v.odoMeter,
//           'updated_at': v.updatedAt.toIso8601String(),
//           'is_deleted': v.isDeleted,
//         });

//         controller.markAsSynced(v.vehicleId);
//       } catch (e) {
//         print("Vehicle sync error: $e");
//       }
//     }

//     final remote = await supabase.from('vehicles').select();

//     for (final r in remote) {
//       final vehicle = Vehicle(
//         vehicleId: r['vehicle_id'],
//         customerId: r['customer_id'],
//         registrationNumber: r['registration_number'],
//         make: r['make'],
//         model: r['model'],
//         vehicleColor: r['vehicle_color'],
//         fuelType: r['fuel_type'],
//         chassisNumber: r['chassis_number'],
//         engineNumber: r['engine_number'],
//         odoMeter: r['odo_meter'],
//       );

//       vehicle.updatedAt = DateTime.parse(r['updated_at']);
//       vehicle.isDeleted = r['is_deleted'] ?? false;
//       vehicle.syncStatus = SyncStatus.synced;

//       controller.upsertFromRemote(vehicle);
//     }
//   }

//   // =====================================================
//   // ITEMS
//   // =====================================================
//   Future<void> _syncItems() async {
//     final controller = Get.find<ItemController>();

//     final pending = controller.items
//         .where((i) => i.syncStatus != SyncStatus.synced)
//         .toList();

//     for (final i in pending) {
//       try {
//         await supabase.from('items').upsert({
//           'item_id': i.itemId,
//           'name': i.name,
//           'type': i.type,
//           'hsn_sac': i.hsnSac,
//           'gst': i.gst,
//           'price': i.price,
//           'updated_at': i.updatedAt.toIso8601String(),
//           'is_deleted': i.isDeleted,
//         });

//         controller.markAsSynced(i.itemId);
//       } catch (e) {
//         print("Item sync error: $e");
//       }
//     }

//     final remote = await supabase.from('items').select();

//     for (final r in remote) {
//       final item = Item(
//         itemId: r['item_id'],
//         name: r['name'],
//         type: r['type'],
//         hsnSac: r['hsn_sac'],
//         gst: (r['gst'] as num).toDouble(),
//         price: r['price'] != null ? (r['price'] as num).toDouble() : null,
//       );

//       item.updatedAt = DateTime.parse(r['updated_at']);
//       item.isDeleted = r['is_deleted'] ?? false;
//       item.syncStatus = SyncStatus.synced;

//       controller.upsertFromRemote(item);
//     }
//   }

//   // =====================================================
//   // INVOICES
//   // =====================================================
//   Future<void> _syncInvoices() async {
//     final controller = Get.find<InvoiceController>();

//     final pending = controller.invoices
//         .where((i) => i.syncStatus != SyncStatus.synced)
//         .toList();

//     for (final i in pending) {
//       try {
//         await supabase.from('invoices').upsert({
//           'invoice_id': i.invoiceId,
//           'customer_id': i.customerId,
//           'vehicle_id': i.vehicleId,
//           'date_time': i.dateTime.toIso8601String(),
//           'items': i.items
//               .map(
//                 (e) => {
//                   'item_id': e.itemId,
//                   'name': e.name,
//                   'hsn_sac': e.hsnSac,
//                   'qty': e.qty,
//                   'rate': e.rate,
//                   'tax_percent': e.taxPercent,
//                   'tax_amount': e.taxAmount,
//                   'total_amount': e.totalAmount,
//                   'type': e.type,
//                 },
//               )
//               .toList(),
//           'grand_total': i.grandTotal,
//           'updated_at': i.updatedAt.toIso8601String(),
//           'is_deleted': i.isDeleted,
//         });

//         controller.markAsSynced(i.invoiceId);
//       } catch (e) {
//         print("Invoice sync error: $e");
//       }
//     }
//   }

//   // =====================================================
//   // REMINDERS
//   // =====================================================
//   Future<void> _syncReminders() async {
//     final controller = Get.find<ReminderController>();

//     final pending = controller.reminders
//         .where((r) => r.syncStatus != SyncStatus.synced)
//         .toList();

//     for (final r in pending) {
//       try {
//         await supabase.from('reminders').upsert({
//           'reminder_id': r.reminderId,
//           'customer_id': r.customerId,
//           'vehicle_id': r.vehicleId,
//           'invoice_id': r.invoiceId,
//           'due_date': r.dueDate.toIso8601String(),
//           'title': r.title,
//           'notes': r.notes,
//           'completed': r.completed,
//           'updated_at': r.updatedAt.toIso8601String(),
//           'is_deleted': r.isDeleted,
//         });

//         controller.markAsSynced(r.reminderId);
//       } catch (e) {
//         print("Reminder sync error: $e");
//       }
//     }
//   }
// }

// ignore_for_file: avoid_print

import 'dart:async';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../controllers/customer_controller.dart';
import '../controllers/vehicle_controller.dart';
import '../controllers/item_controller.dart';
import '../controllers/invoice_controller.dart';
import '../controllers/reminder_controller.dart';

import '../models/customer_model.dart';
import '../models/vehicle_model.dart';
import '../models/item_model.dart';
import '../models/invoice_model.dart';
import '../models/reminder_model.dart';

import '../models/sync_status.dart';

class SupabaseSyncService {
  final SupabaseClient supabase = Supabase.instance.client;

  Timer? _timer;
  bool _isSyncing = false;

  late Box _metaBox;
  late String deviceId;

  final Map<String, DateTime> lastSync = {
    'customers': DateTime.fromMillisecondsSinceEpoch(0),
    'vehicles': DateTime.fromMillisecondsSinceEpoch(0),
    'items': DateTime.fromMillisecondsSinceEpoch(0),
    'invoices': DateTime.fromMillisecondsSinceEpoch(0),
    'reminders': DateTime.fromMillisecondsSinceEpoch(0),
  };

  // =====================================================
  // INIT
  // =====================================================
  Future<void> init() async {
    _metaBox = await Hive.openBox('sync_meta');

    deviceId = _metaBox.get('device_id') ?? const Uuid().v4();
    await _metaBox.put('device_id', deviceId);

    _loadLastSyncTimes();

    print("Supabase sync initialized | Device: $deviceId");

    startRealtimeSync();
    syncAll();

    _timer = Timer.periodic(const Duration(minutes: 2), (_) {
      syncAll();
    });
  }

  void _loadLastSyncTimes() {
    for (final key in lastSync.keys) {
      final val = _metaBox.get(key);
      if (val != null) {
        lastSync[key] = DateTime.parse(val);
      }
    }
  }

  Future<void> _saveLastSync(String table, DateTime time) async {
    lastSync[table] = time;
    await _metaBox.put(table, time.toIso8601String());
  }

  void dispose() {
    _timer?.cancel();
  }

  // =====================================================
  // REALTIME
  // =====================================================
  void startRealtimeSync() {
    supabase
        .channel('erp-realtime')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'customers',
          callback: (_) => syncCustomers(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'vehicles',
          callback: (_) => syncVehicles(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'items',
          callback: (_) => syncItems(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'invoices',
          callback: (_) => syncInvoices(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'reminders',
          callback: (_) => syncReminders(),
        )
        .subscribe();
  }

  // =====================================================
  // MAIN SYNC
  // =====================================================
  Future<void> syncAll() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      await syncCustomers();
      await syncVehicles();
      await syncItems();
      await syncInvoices();
      await syncReminders();
    } catch (e) {
      print("SYNC ERROR: $e");
    }

    _isSyncing = false;
  }

  // =====================================================
  // CUSTOMERS
  // =====================================================
  Future<void> syncCustomers() async {
    print("Syncing customers...");
    final controller = Get.find<CustomerController>();

    // 1. PUSH LOCAL CHANGES
    final pending = controller.allCustomers
        .where((c) => c.syncStatus != SyncStatus.synced)
        .toList();
    print("Pending customers: ${pending.length}");
    for (final c in pending) {
      try {
        await supabase.from('customers').upsert({
          'customer_id': c.customerId,
          'name': c.name,
          'contact1': c.contact1,
          'contact2': c.contact2,
          'address': c.address,
          'email': c.email,
          'gst_number': c.gstNumber,
          'pan_number': c.panNumber,
          'updated_at': c.updatedAt.toIso8601String(),
          'device_id': deviceId,
          'is_deleted': c.isDeleted,
        });

        controller.markAsSynced(c.customerId);
        print("Customer delete pushed: ${c.customerId}");
      } catch (e) {
        print("Customer push error: $e");
      }
    }

    // 2. PULL ONLY CHANGES (INCREMENTAL SYNC)
    final remote = await supabase
        .from('customers')
        .select()
        .gte('updated_at', lastSync['customers']!.toIso8601String());

    for (final r in remote) {
      final remoteUpdated = DateTime.parse(r['updated_at']);

      final customer =
          Customer(
              customerId: r['customer_id'],
              name: r['name'],
              contact1: r['contact1'],
              contact2: r['contact2'],
              address: r['address'],
              email: r['email'],
              gstNumber: r['gst_number'],
              panNumber: r['pan_number'],
            )
            ..updatedAt = remoteUpdated
            ..isDeleted = r['is_deleted'] ?? false
            ..syncStatus = SyncStatus.synced;

      controller.upsertFromRemote(customer);
    }

    await _saveLastSync('customers', DateTime.now());
  }

  // =====================================================
  // VEHICLES
  // =====================================================
  Future<void> syncVehicles() async {
    final controller = Get.find<VehicleController>();

    final pending = controller.allVehicles
        .where((v) => v.syncStatus != SyncStatus.synced)
        .toList();

    for (final v in pending) {
      try {
        await supabase.from('vehicles').upsert({
          'vehicle_id': v.vehicleId,
          'customer_id': v.customerId,
          'registration_number': v.registrationNumber,
          'make': v.make,
          'model': v.model,
          'vehicle_color': v.vehicleColor,
          'fuel_type': v.fuelType,
          'chassis_number': v.chassisNumber,
          'engine_number': v.engineNumber,
          'odo_meter': v.odoMeter,
          'updated_at': v.updatedAt.toIso8601String(),
          'device_id': deviceId,
          'is_deleted': v.isDeleted,
        });

        controller.markAsSynced(v.vehicleId);
      } catch (e) {
        print("Vehicle push error: $e");
      }
    }

    final remote = await supabase
        .from('vehicles')
        .select()
        .gte('updated_at', lastSync['vehicles']!.toIso8601String());

    for (final r in remote) {
      final vehicle =
          Vehicle(
              vehicleId: r['vehicle_id'],
              customerId: r['customer_id'],
              registrationNumber: r['registration_number'],
              make: r['make'],
              model: r['model'],
              vehicleColor: r['vehicle_color'],
              fuelType: r['fuel_type'],
              chassisNumber: r['chassis_number'],
              engineNumber: r['engine_number'],
              odoMeter: r['odo_meter'],
            )
            ..updatedAt = DateTime.parse(r['updated_at'])
            ..isDeleted = r['is_deleted'] ?? false
            ..syncStatus = SyncStatus.synced;

      controller.upsertFromRemote(vehicle);
    }

    await _saveLastSync('vehicles', DateTime.now());
  }

  // =====================================================
  // ITEMS
  // =====================================================
  Future<void> syncItems() async {
    final controller = Get.find<ItemController>();

    final pending = controller.allItems
        .where((i) => i.syncStatus != SyncStatus.synced)
        .toList();

    for (final i in pending) {
      try {
        await supabase.from('items').upsert({
          'item_id': i.itemId,
          'name': i.name,
          'type': i.type,
          'hsn_sac': i.hsnSac,
          'gst': i.gst,
          'price': i.price,
          'updated_at': i.updatedAt.toIso8601String(),
          'device_id': deviceId,
          'is_deleted': i.isDeleted,
        });

        controller.markAsSynced(i.itemId);
      } catch (e) {
        print("Item push error: $e");
      }
    }

    final remote = await supabase
        .from('items')
        .select()
        .gte('updated_at', lastSync['items']!.toIso8601String());

    for (final r in remote) {
      final item =
          Item(
              itemId: r['item_id'],
              name: r['name'],
              type: r['type'],
              hsnSac: r['hsn_sac'],
              gst: (r['gst'] as num).toDouble(),
              price: r['price'] != null ? (r['price'] as num).toDouble() : null,
            )
            ..updatedAt = DateTime.parse(r['updated_at'])
            ..isDeleted = r['is_deleted'] ?? false
            ..syncStatus = SyncStatus.synced;

      controller.upsertFromRemote(item);
    }

    await _saveLastSync('items', DateTime.now());
  }

  // =====================================================
  // INVOICES
  // =====================================================
  Future<void> syncInvoices() async {
    final controller = Get.find<InvoiceController>();

    final pending = controller.allInvoices
        .where((i) => i.syncStatus != SyncStatus.synced)
        .toList();

    for (final i in pending) {
      try {
        await supabase.from('invoices').upsert({
          'invoice_id': i.invoiceId,
          'customer_id': i.customerId,
          'vehicle_id': i.vehicleId,
          'date_time': i.dateTime.toIso8601String(),
          'items': i.items
              .map(
                (e) => {
                  'item_id': e.itemId,
                  'name': e.name,
                  'type': e.type,
                  'hsn_sac': e.hsnSac,
                  'qty': e.qty,
                  'rate': e.rate,
                  'tax_percent': e.taxPercent,
                  'tax_amount': e.taxAmount,
                  'total_amount': e.totalAmount,
                },
              )
              .toList(),
          'grand_total': i.grandTotal,
          'updated_at': i.updatedAt.toIso8601String(),
          'device_id': deviceId,
          'is_deleted': i.isDeleted,
        });

        controller.markAsSynced(i.invoiceId);
      } catch (e) {
        print("Invoice push error: $e");
      }
    }

    final remote = await supabase
        .from('invoices')
        .select()
        .gte('updated_at', lastSync['invoices']!.toIso8601String());

    for (final r in remote) {
      final rawItems = r['items'];

      List<InvoiceItem> parsedItems = [];

      if (rawItems != null && rawItems is List) {
        parsedItems = rawItems.map((e) {
          final map = Map<String, dynamic>.from(e);

          return InvoiceItem(
            itemId: map['item_id'] ?? '',
            name: map['name'] ?? '',
            type: map['type'] ?? '',
            hsnSac: map['hsn_sac'] ?? '',
            qty: (map['qty'] ?? 0) is int
                ? (map['qty'] as int)
                : ((map['qty'] as num).toInt()),
            rate: (map['rate'] ?? 0).toDouble(),
            taxPercent: (map['tax_percent'] ?? 0).toDouble(),
            taxAmount: (map['tax_amount'] ?? 0).toDouble(),
            totalAmount: (map['total_amount'] ?? 0).toDouble(),
          );
        }).toList();
      }

      final invoice =
          Invoice(
              invoiceId: r['invoice_id'],
              customerId: r['customer_id'],
              vehicleId: r['vehicle_id'],
              dateTime: DateTime.parse(r['date_time']),
              items: parsedItems,
              grandTotal: (r['grand_total'] ?? 0).toDouble(),
            )
            ..updatedAt = DateTime.parse(r['updated_at'])
            ..isDeleted = r['is_deleted'] ?? false
            ..syncStatus = SyncStatus.synced;

      controller.upsertFromRemote(invoice);
    }

    await _saveLastSync('invoices', DateTime.now());
  }

  // =====================================================
  // REMINDERS
  // =====================================================
  Future<void> syncReminders() async {
    final controller = Get.find<ReminderController>();

    final pending = controller.allReminders
        .where((r) => r.syncStatus != SyncStatus.synced)
        .toList();

    for (final r in pending) {
      try {
        await supabase.from('reminders').upsert({
          'reminder_id': r.reminderId,
          'customer_id': r.customerId,
          'vehicle_id': r.vehicleId,
          'invoice_id': r.invoiceId,
          'due_date': r.dueDate.toIso8601String(),
          'title': r.title,
          'notes': r.notes,
          'completed': r.completed,
          'updated_at': r.updatedAt.toIso8601String(),
          'device_id': deviceId,
          'is_deleted': r.isDeleted,
        });

        controller.markAsSynced(r.reminderId);
      } catch (e) {
        print("Reminder push error: $e");
      }
    }

    final remote = await supabase
        .from('reminders')
        .select()
        .gte('updated_at', lastSync['reminders']!.toIso8601String());

    for (final r in remote) {
      final reminder = Reminder(
        reminderId: r['reminder_id'],
        customerId: r['customer_id'],
        vehicleId: r['vehicle_id'],
        invoiceId: r['invoice_id'],
        dueDate: DateTime.parse(r['due_date']),
        title: r['title'],
        notes: r['notes'],
        completed: r['completed'],
      );
      controller.upsertFromRemote(reminder);
    }

    await _saveLastSync('reminders', DateTime.now());
  }
}
