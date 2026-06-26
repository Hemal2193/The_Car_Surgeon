import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tcs/controllers/payment_controller.dart';
import 'package:tcs/models/payment_model.dart';
import 'package:tcs/models/sync_status.dart';
import 'package:tcs/screens/auth/login_screen.dart';
import 'package:tcs/services/auth_service.dart';
import 'package:tcs/services/supabase_sync_service.dart';
import 'package:window_manager/window_manager.dart';

import 'controllers/customer_controller.dart';
import 'controllers/app_navigation_controller.dart';
import 'controllers/invoice_controller.dart';
import 'controllers/item_controller.dart';
import 'controllers/reminder_controller.dart';
import 'controllers/vehicle_controller.dart';

import 'database/hive_boxes.dart';
import 'database/id_resolver.dart';

import 'models/customer_model.dart';
import 'models/invoice_model.dart';
import 'models/invoice_payment_status.dart';
import 'models/item_model.dart';
import 'models/reminder_model.dart';
import 'models/vehicle_model.dart';

import 'screens/homepage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://korzmnwwxywxqybyjiux.supabase.co',

    publishableKey: 'sb_publishable_jKGuzcvKNbe0hbC7qsotng_RhqAMxLW',
  );

  // WINDOWS / DESKTOP ONLY
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();

    const WindowOptions windowOptions = WindowOptions(
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }
  // HIVE
  final dir = await getApplicationSupportDirectory();
  await Hive.initFlutter(dir.path);

  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(CustomerAdapter());
  }

  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(VehicleAdapter());
  }

  if (!Hive.isAdapterRegistered(2)) {
    Hive.registerAdapter(ItemAdapter());
  }

  if (!Hive.isAdapterRegistered(3)) {
    Hive.registerAdapter(InvoiceAdapter());
  }

  if (!Hive.isAdapterRegistered(4)) {
    Hive.registerAdapter(InvoiceItemAdapter());
  }

  if (!Hive.isAdapterRegistered(5)) {
    Hive.registerAdapter(ReminderAdapter());
  }

  if (!Hive.isAdapterRegistered(6)) {
    Hive.registerAdapter(SyncStatusAdapter());
  }

  if (!Hive.isAdapterRegistered(7)) {
    Hive.registerAdapter(PaymentAdapter());
  }

  if (!Hive.isAdapterRegistered(8)) {
    Hive.registerAdapter(InvoicePaymentStatusAdapter());
  }

  if (!Hive.isAdapterRegistered(9)) {
    Hive.registerAdapter(ReminderTypeAdapter());
  }

  // OPEN BOXES
  await Hive.openBox<Customer>(HiveBoxes.customers);
  await Hive.openBox<Vehicle>(HiveBoxes.vehicles);
  await Hive.openBox<Item>(HiveBoxes.items);
  await Hive.openBox<Invoice>(HiveBoxes.invoices);
  await Hive.openBox<Payment>(HiveBoxes.payments);
  await Hive.openBox<Reminder>(HiveBoxes.reminders);
  await Hive.openBox(HiveBoxes.settings);

  // SEED ID GENERATORS from Supabase (prevents ID conflicts on reinstall / multi-device)
  await IdResolver.seedAllGenerators();

  // CONTROLLERS (register BEFORE sync service so Get.find works)
  Get.put(AppNavigationController(), permanent: true);
  final customerController = Get.put(CustomerController(), permanent: true);
  Get.put(ItemController(), permanent: true);
  Get.put(VehicleController(), permanent: true);
  Get.put(InvoiceController(), permanent: true);
  Get.put(PaymentController(), permanent: true);
  Get.put(ReminderController(), permanent: true);

  // CACHE
  customerController.initCache();

  // SUPABASE SYNC (after controllers are registered)
  final syncService = Get.put(SupabaseSyncService(), permanent: true);
  syncService.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<bool> _isApproved() async {
    if (!AuthService.isLoggedIn) return false;
    return AuthService.getUserApprovalStatus(AuthService.currentUser!.id);
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          extendedSizeConstraints: BoxConstraints(
            minHeight: 40, // Default is around 56
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          extendedPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          extendedIconLabelSpacing: 4,

          iconSize: 12,
          extendedTextStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      home: FutureBuilder<bool>(
        future: _isApproved(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: Colors.white,
              body: Center(
                child: CircularProgressIndicator(color: Colors.black),
              ),
            );
          }
          final approved = snapshot.data ?? false;
          if (AuthService.isLoggedIn && approved) {
            return const HomePage();
          }
          return const LoginScreen();
        },
      ),
    );
  }
}
