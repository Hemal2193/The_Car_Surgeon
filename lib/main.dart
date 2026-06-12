import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tcs/models/sync_status.dart';
import 'package:tcs/services/supabase_sync_service.dart';
import 'package:window_manager/window_manager.dart';

import 'controllers/customer_controller.dart';
import 'controllers/invoice_controller.dart';
import 'controllers/item_controller.dart';
import 'controllers/reminder_controller.dart';
import 'controllers/vehicle_controller.dart';

import 'database/hive_boxes.dart';

import 'models/customer_model.dart';
import 'models/invoice_model.dart';
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

  SupabaseSyncService().init();

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

  // OPEN BOXES
  await Hive.openBox<Customer>(HiveBoxes.customers);
  await Hive.openBox<Vehicle>(HiveBoxes.vehicles);
  await Hive.openBox<Item>(HiveBoxes.items);
  await Hive.openBox<Invoice>(HiveBoxes.invoices);
  await Hive.openBox<Reminder>(HiveBoxes.reminders);
  await Hive.openBox(HiveBoxes.settings);

  // CONTROLLERS
  final customerController = Get.put(CustomerController(), permanent: true);

  Get.put(ItemController(), permanent: true);
  Get.put(VehicleController(), permanent: true);
  Get.put(InvoiceController(), permanent: true);
  Get.put(ReminderController(), permanent: true);

  // CACHE
  customerController.initCache();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}
