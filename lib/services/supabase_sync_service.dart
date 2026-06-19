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
import '../controllers/payment_controller.dart';

import '../models/customer_model.dart';
import '../models/vehicle_model.dart';
import '../models/item_model.dart';
import '../models/invoice_model.dart';
import '../models/reminder_model.dart';
import '../models/payment_model.dart';

import '../models/sync_status.dart';
import '../models/invoice_payment_status.dart';

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
    'payments': DateTime.fromMillisecondsSinceEpoch(0),
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

    _timer = Timer.periodic(const Duration(minutes: 10), (_) {
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
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'payments',
          callback: (_) => syncPayments(),
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
    } catch (e, st) {
      print("CUSTOMERS SYNC ERROR: $e");
      print(st);
    }

    try {
      await syncVehicles();
    } catch (e, st) {
      print("VEHICLES SYNC ERROR: $e");
      print(st);
    }

    try {
      await syncItems();
    } catch (e, st) {
      print("ITEMS SYNC ERROR: $e");
      print(st);
    }

    try {
      await syncInvoices();
    } catch (e, st) {
      print("INVOICES SYNC ERROR: $e");
      print(st);
    }

    try {
      await syncReminders();
    } catch (e, st) {
      print("REMINDERS SYNC ERROR: $e");
      print(st);
    }

    try {
      await syncPayments();
    } catch (e, st) {
      print("PAYMENTS SYNC ERROR: $e");
      print(st);
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
          'odo_meter': v.odoMeter.toString(),
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
              vehicleId: r['vehicle_id']?.toString() ?? '',
              customerId: r['customer_id']?.toString() ?? '',
              registrationNumber: r['registration_number']?.toString() ?? '',
              make: r['make']?.toString() ?? '',
              model: r['model']?.toString() ?? '',
              vehicleColor: r['vehicle_color']?.toString() ?? '',
              fuelType: r['fuel_type']?.toString() ?? '',
              chassisNumber: r['chassis_number']?.toString() ?? '',
              engineNumber: r['engine_number']?.toString() ?? '',
              odoMeter: r['odo_meter']?.toString() ?? '0',
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
                  'discount': e.discount,
                  'discount_is_percent': e.discountIsPercent,
                },
              )
              .toList(),
          'grand_total': i.grandTotal,
          'discount': i.discount,
          'advance_amount': i.advanceAmount,
          'balance_amount': i.balanceAmount,
          'payment_method': i.paymentMethod,
          'payment_status': i.paymentStatus.name,
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
            itemId: map['item_id']?.toString() ?? '',
            name: map['name']?.toString() ?? '',
            type: map['type']?.toString() ?? '',
            hsnSac: map['hsn_sac']?.toString(),
            qty: (map['qty'] is int)
                ? (map['qty'] as int)
                : ((map['qty'] as num?)?.toInt() ?? 0),
            rate: (map['rate'] as num?)?.toDouble() ?? 0.0,
            taxPercent: (map['tax_percent'] as num?)?.toDouble() ?? 0.0,
            taxAmount: (map['tax_amount'] as num?)?.toDouble() ?? 0.0,
            totalAmount: (map['total_amount'] as num?)?.toDouble() ?? 0.0,
            discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
            discountIsPercent: map['discount_is_percent'] ?? false,
          );
        }).toList();
      }

      final paymentStatusStr = r['payment_status']?.toString();
      final InvoicePaymentStatus paymentStatus;
      switch (paymentStatusStr) {
        case 'paid':
          paymentStatus = InvoicePaymentStatus.paid;
          break;
        case 'partiallyPaid':
          paymentStatus = InvoicePaymentStatus.partiallyPaid;
          break;
        default:
          paymentStatus = InvoicePaymentStatus.unpaid;
      }

      final invoice =
          Invoice(
              invoiceId: r['invoice_id']?.toString() ?? '',
              customerId: r['customer_id']?.toString() ?? '',
              vehicleId: r['vehicle_id']?.toString() ?? '',
              dateTime: DateTime.parse(r['date_time']),
              dueDate: DateTime.parse(r['due_date']),
              items: parsedItems,
              grandTotal: (r['grand_total'] as num?)?.toDouble() ?? 0.0,
              discount: (r['discount'] as num?)?.toDouble() ?? 0.0,
              advanceAmount: (r['advance_amount'] as num?)?.toDouble() ?? 0.0,
              balanceAmount: (r['balance_amount'] as num?)?.toDouble(),
              paymentMethod: r['payment_method']?.toString() ?? 'Cash',
              paymentStatus: paymentStatus,
            )
            ..updatedAt = DateTime.parse(r['updated_at'])
            ..isDeleted = r['is_deleted'] ?? false
            ..syncStatus = SyncStatus.synced;

      controller.upsertFromRemote(invoice);
    }

    // 3. CASCADE DELETE: if a remote invoice was deleted, cascade-mark
    //    related local payments and reminders as deleted so they get synced
    final deletedInvoices = remote
        .where((r) => r['is_deleted'] == true)
        .toList();
    if (deletedInvoices.isNotEmpty) {
      final paymentCtrl = Get.find<PaymentController>();
      final reminderCtrl = Get.find<ReminderController>();

      for (final r in deletedInvoices) {
        final invoiceId = r['invoice_id']?.toString();
        if (invoiceId == null) continue;

        // Cascade-delete payments for this invoice
        final paymentsForInv = paymentCtrl.allPaymentsIncludingDeleted
            .where((p) => p.invoiceId == invoiceId && !p.isDeleted)
            .toList();
        for (final p in paymentsForInv) {
          p.updatedAt = DateTime.now();
          p.isDeleted = true;
          p.syncStatus = SyncStatus.pending;
          await p.save();
        }
        if (paymentsForInv.isNotEmpty) {
          paymentCtrl.update();
          unawaited(syncPayments());
        }

        // Cascade-delete reminders for this invoice
        final remindersForInv = reminderCtrl.allReminders
            .where((rm) => rm.invoiceId == invoiceId && !rm.isDeleted)
            .toList();
        for (final rm in remindersForInv) {
          rm.updatedAt = DateTime.now();
          rm.isDeleted = true;
          rm.syncStatus = SyncStatus.pending;
          await reminderCtrl.reminderBox.put(rm.reminderId, rm);
        }
        if (remindersForInv.isNotEmpty) {
          reminderCtrl.update();
          unawaited(syncReminders());
        }
      }
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
          'type': r.type.name,
          'customer_id': r.customerId,
          'vehicle_id': r.vehicleId,
          'invoice_id': r.invoiceId,
          'title': r.title,
          'notes': r.notes,
          'due_date': r.dueDate.toIso8601String(),
          'completed': r.completed,
          'created_at': r.createdAt.toIso8601String(),
          'updated_at': r.updatedAt.toIso8601String(),
          'device_id': deviceId,
          'is_deleted': r.isDeleted,
        });

        await controller.markAsSynced(r.reminderId);
      } catch (e) {
        print("Reminder push error: $e");
      }
    }

    final remote = await supabase
        .from('reminders')
        .select()
        .gte('updated_at', lastSync['reminders']!.toIso8601String());

    for (final r in remote) {
      final reminder =
          Reminder(
              reminderId: r['reminder_id'],
              type: ReminderType.values.firstWhere(
                (e) => e.name == r['type'],
                orElse: () => ReminderType.service,
              ),
              customerId: r['customer_id'],
              vehicleId: r['vehicle_id'],
              invoiceId: r['invoice_id'],
              title: r['title'],
              notes: r['notes'],
              dueDate: DateTime.parse(r['due_date']),
              completed: r['completed'] ?? false,
              createdAt: DateTime.parse(r['created_at']),
              updatedAt: DateTime.parse(r['updated_at']),
            )
            ..isDeleted = r['is_deleted'] ?? false
            ..syncStatus = SyncStatus.synced;

      controller.upsertFromRemote(reminder);
    }

    await _saveLastSync('reminders', DateTime.now());
  }

  // =====================================================
  // PAYMENTS
  // =====================================================
  Future<void> syncPayments() async {
    print("[syncPayments] called | _isSyncing=$_isSyncing");
    final controller = Get.find<PaymentController>();

    final pending = controller.pendingPaymentsIncludingDeleted;

    print("[syncPayments] pending=${pending.length}");
    for (final p in pending) {
      print(
        "[syncPayments] pushing ${p.paymentId} invoice=${p.invoiceId} amount=${p.amount} isDeleted=${p.isDeleted}",
      );
      try {
        await supabase.from('payments').upsert({
          'payment_id': p.paymentId,
          'invoice_id': p.invoiceId,
          'date_time': p.dateTime.toIso8601String(),
          'mode': p.mode,
          'amount': p.amount,
          'notes': p.notes,
          'updated_at': p.updatedAt.toIso8601String(),
          'device_id': deviceId,
          'is_deleted': p.isDeleted,
        });

        controller.markAsSynced(p.paymentId);
        print("[syncPayments] synced=${p.paymentId}");
      } catch (e) {
        print("Payment push error: $e");
      }
    }

    final remote = await supabase
        .from('payments')
        .select()
        .gte('updated_at', lastSync['payments']!.toIso8601String());

    for (final r in remote) {
      final payment =
          Payment(
              paymentId: r['payment_id']?.toString() ?? '',
              invoiceId: r['invoice_id']?.toString() ?? '',
              dateTime: DateTime.parse(r['date_time']),
              mode: r['mode']?.toString() ?? 'Cash',
              amount: (r['amount'] as num?)?.toDouble() ?? 0.0,
              notes: r['notes']?.toString(),
            )
            ..updatedAt = DateTime.parse(r['updated_at'])
            ..isDeleted = r['is_deleted'] ?? false
            ..syncStatus = SyncStatus.synced;
      controller.upsertFromRemote(payment);
    }

    print("[syncPayments] remote count=${remote.length}");
    await _saveLastSync('payments', DateTime.now());
  }
}
