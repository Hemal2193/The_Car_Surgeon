import 'dart:async';

import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tcs/controllers/app_navigation_controller.dart';
import 'package:tcs/controllers/customer_controller.dart';
import 'package:tcs/controllers/invoice_controller.dart';
import 'package:tcs/controllers/item_controller.dart';
import 'package:tcs/controllers/payment_controller.dart';
import 'package:tcs/controllers/reminder_controller.dart';
import 'package:tcs/controllers/vehicle_controller.dart';
import 'package:tcs/database/hive_boxes.dart';
import 'package:tcs/database/id_resolver.dart';
import 'package:tcs/models/customer_model.dart';
import 'package:tcs/models/invoice_model.dart';
import 'package:tcs/models/invoice_payment_status.dart';
import 'package:tcs/models/item_model.dart';
import 'package:tcs/models/payment_model.dart';
import 'package:tcs/models/reminder_model.dart';
import 'package:tcs/models/sync_status.dart';
import 'package:tcs/models/vehicle_model.dart';
import 'package:tcs/services/supabase_sync_service.dart';

/// Centralized application initializer.
///
/// Guarantees:
/// - Idempotent: `initialize()` runs at most once.
/// - Thread-safe: concurrent calls return the same shared future.
/// - On failure, an [AppInitializationException] is thrown with details.
class AppInitializer {
  AppInitializer._();

  static Completer<void>? _completer;
  static bool _initialized = false;
  static bool _initializing = false;

  /// Returns a Future that completes when initialization finishes.
  ///
  /// If called multiple times, subsequent calls return the same future.
  /// Never throws after the first successful initialization.
  static Future<void> initialize() async {
    // Fast-path: already done.
    if (_initialized) {
      assert(_completer != null);
      return _completer!.future;
    }

    // First caller creates the completer and runs initialization.
    if (_completer == null) {
      _completer = Completer<void>();
      _initializing = true;

      try {
        await _runInitialization();
        _initialized = true;
        _completer!.complete();
      } catch (e, s) {
        _initializing = false;
        final error = AppInitializationException(
          'App initialization failed',
          e,
          s,
        );
        _completer!.completeError(error, s);
        _completer = null; // Allow retry on next call.
        throw error;
      }
    }

    return _completer!.future;
  }

  /// Returns `true` once initialization has completed successfully.
  static bool get isInitialized => _initialized;

  /// Returns `true` while initialization is in progress.
  static bool get isInitializing => _initializing;

  /// The actual initialization work.
  static Future<void> _runInitialization() async {
    // --- Supabase ---
    await Supabase.initialize(
      url: 'https://korzmnwwxywxqybyjiux.supabase.co',
      publishableKey: 'sb_publishable_jKGuzcvKNbe0hbC7qsotng_RhqAMxLW',
    );

    // --- Hive ---
    final dir = await getApplicationSupportDirectory();
    await Hive.initFlutter(dir.path);

    _registerAdapters();

    await _openBoxes();

    // --- ID generators ---
    await IdResolver.seedAllGenerators();

    // --- Controllers ---
    Get.put(AppNavigationController(), permanent: true);
    final customerController = Get.put(CustomerController(), permanent: true);
    Get.put(ItemController(), permanent: true);
    Get.put(VehicleController(), permanent: true);
    Get.put(InvoiceController(), permanent: true);
    Get.put(PaymentController(), permanent: true);
    Get.put(ReminderController(), permanent: true);

    // --- Cache ---
    customerController.initCache();

    // --- Sync service ---
    final syncService = Get.put(SupabaseSyncService(), permanent: true);
    syncService.init();
  }

  static void _registerAdapters() {
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter<Customer>(CustomerAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter<Vehicle>(VehicleAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter<Item>(ItemAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter<Invoice>(InvoiceAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter<InvoiceItem>(InvoiceItemAdapter());
    }
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter<Reminder>(ReminderAdapter());
    }
    if (!Hive.isAdapterRegistered(6)) {
      Hive.registerAdapter<SyncStatus>(SyncStatusAdapter());
    }
    if (!Hive.isAdapterRegistered(7)) {
      Hive.registerAdapter<Payment>(PaymentAdapter());
    }
    if (!Hive.isAdapterRegistered(8)) {
      Hive.registerAdapter<InvoicePaymentStatus>(
        InvoicePaymentStatusAdapter(),
      );
    }
    if (!Hive.isAdapterRegistered(9)) {
      Hive.registerAdapter<ReminderType>(ReminderTypeAdapter());
    }
  }

  static Future<void> _openBoxes() async {
    await Hive.openBox<Customer>(HiveBoxes.customers);
    await Hive.openBox<Vehicle>(HiveBoxes.vehicles);
    await Hive.openBox<Item>(HiveBoxes.items);
    await Hive.openBox<Invoice>(HiveBoxes.invoices);
    await Hive.openBox<Payment>(HiveBoxes.payments);
    await Hive.openBox<Reminder>(HiveBoxes.reminders);
    await Hive.openBox(HiveBoxes.settings);
  }
}

/// Exception thrown when app initialization fails.
class AppInitializationException implements Exception {
  AppInitializationException(this.message, this.cause, this.stackTrace);

  final String message;
  final Object cause;
  final StackTrace stackTrace;

  @override
  String toString() => '$message: $cause';
}
