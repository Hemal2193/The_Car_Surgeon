import 'package:hive/hive.dart';
import 'hive_boxes.dart';

class IdGenerator {
  static String generateCustomerId() {
    final settingsBox = Hive.box(HiveBoxes.settings);

    int currentNumber = settingsBox.get('customer_counter', defaultValue: 0);

    currentNumber++;

    settingsBox.put('customer_counter', currentNumber);

    return 'CUST-${currentNumber.toString().padLeft(4, '0')}';
  }

  static String generateVehicleId() {
    final settingsBox = Hive.box(HiveBoxes.settings);

    int currentNumber = settingsBox.get('vehicle_counter', defaultValue: 0);

    currentNumber++;

    settingsBox.put('vehicle_counter', currentNumber);

    return 'VEH-${currentNumber.toString().padLeft(4, '0')}';
  }

  static String generateItemId() {
    final settingsBox = Hive.box(HiveBoxes.settings);

    int currentNumber = settingsBox.get('item_counter', defaultValue: 0);

    currentNumber++;

    settingsBox.put('item_counter', currentNumber);

    return 'ITEM-${currentNumber.toString().padLeft(4, '0')}';
  }

  static String generateInvoiceId() {
    final settingsBox = Hive.box(HiveBoxes.settings);

    int currentNumber = settingsBox.get('invoice_counter', defaultValue: 0);

    currentNumber++;

    settingsBox.put('invoice_counter', currentNumber);

    return 'INV-${currentNumber.toString().padLeft(4, '0')}';
  }

  static String generateReminderId() {
    final settingsBox = Hive.box(HiveBoxes.settings);

    int currentNumber = settingsBox.get('reminder_counter', defaultValue: 0);

    currentNumber++;

    settingsBox.put('reminder_counter', currentNumber);

    return 'REM-${currentNumber.toString().padLeft(4, '0')}';
  }
}
