import 'package:flutter/material.dart';
import 'package:tcs/controllers/invoice_controller.dart';
import 'package:tcs/controllers/item_controller.dart';
import 'package:tcs/controllers/reminder_controller.dart';
import 'package:tcs/controllers/vehicle_controller.dart';
import 'package:tcs/database/hive_boxes.dart';
import 'package:tcs/models/customer_model.dart';
import 'package:tcs/models/invoice_model.dart';
import 'package:tcs/models/item_model.dart';
import 'package:tcs/models/reminder_model.dart';
import 'package:tcs/models/vehicle_model.dart';
import 'package:tcs/screens/homepage.dart';
import 'package:window_manager/window_manager.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:get/get.dart';
import 'controllers/customer_controller.dart';
import 'package:path_provider/path_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  final dir = await getApplicationSupportDirectory();
  await Hive.initFlutter(dir.path);

  Hive.registerAdapter(CustomerAdapter());
  Hive.registerAdapter(VehicleAdapter());
  Hive.registerAdapter(ItemAdapter());
  Hive.registerAdapter(InvoiceAdapter());
  Hive.registerAdapter(InvoiceItemAdapter());
  Hive.registerAdapter(ReminderAdapter());

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

  // IMPORTANT: INIT CACHE AFTER BOX IS READY
  customerController.initCache();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}
