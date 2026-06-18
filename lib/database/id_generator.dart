import 'package:hive/hive.dart';
import 'hive_boxes.dart';

class IdGenerator {
  /// Seeds the customer counter so the next ID continues from [maxValue].
  /// Called once on startup by [IdResolver].
  static void setInitialCustomerId(int maxValue) {
    final settingsBox = Hive.box(HiveBoxes.settings);
    final existing = settingsBox.get('customer_counter', defaultValue: 0);
    if (maxValue > existing) {
      settingsBox.put('customer_counter', maxValue);
    }
  }

  static String generateCustomerId() {
    final settingsBox = Hive.box(HiveBoxes.settings);

    int currentNumber = settingsBox.get('customer_counter', defaultValue: 0);

    currentNumber++;

    settingsBox.put('customer_counter', currentNumber);

    return 'CUST-${currentNumber.toString().padLeft(4, '0')}';
  }

  /// Seeds the vehicle counter so the next ID continues from [maxValue].
  static void setInitialVehicleId(int maxValue) {
    final settingsBox = Hive.box(HiveBoxes.settings);
    final existing = settingsBox.get('vehicle_counter', defaultValue: 0);
    if (maxValue > existing) {
      settingsBox.put('vehicle_counter', maxValue);
    }
  }

  static String generateVehicleId() {
    final settingsBox = Hive.box(HiveBoxes.settings);

    int currentNumber = settingsBox.get('vehicle_counter', defaultValue: 0);

    currentNumber++;

    settingsBox.put('vehicle_counter', currentNumber);

    return 'VEH-${currentNumber.toString().padLeft(4, '0')}';
  }

  /// Seeds the item counter so the next ID continues from [maxValue].
  static void setInitialItemId(int maxValue) {
    final settingsBox = Hive.box(HiveBoxes.settings);
    final existing = settingsBox.get('item_counter', defaultValue: 0);
    if (maxValue > existing) {
      settingsBox.put('item_counter', maxValue);
    }
  }

  static String generateItemId() {
    final settingsBox = Hive.box(HiveBoxes.settings);

    int currentNumber = settingsBox.get('item_counter', defaultValue: 0);

    currentNumber++;

    settingsBox.put('item_counter', currentNumber);

    return 'ITEM-${currentNumber.toString().padLeft(4, '0')}';
  }

  /// Seeds the invoice counter so the next ID continues from [maxValue].
  static void setInitialInvoiceId(int maxValue) {
    final settingsBox = Hive.box(HiveBoxes.settings);
    final existing = settingsBox.get('invoice_counter', defaultValue: 0);
    if (maxValue > existing) {
      settingsBox.put('invoice_counter', maxValue);
    }
  }

  static String generateInvoiceId() {
    final settingsBox = Hive.box(HiveBoxes.settings);

    int currentNumber = settingsBox.get('invoice_counter', defaultValue: 0);

    currentNumber++;

    settingsBox.put('invoice_counter', currentNumber);

    return 'INV-${currentNumber.toString().padLeft(4, '0')}';
  }

  /// Seeds the reminder counter so the next ID continues from [maxValue].
  static void setInitialReminderId(int maxValue) {
    final settingsBox = Hive.box(HiveBoxes.settings);
    final existing = settingsBox.get('reminder_counter', defaultValue: 0);
    if (maxValue > existing) {
      settingsBox.put('reminder_counter', maxValue);
    }
  }

  static String generateReminderId() {
    final settingsBox = Hive.box(HiveBoxes.settings);

    int currentNumber = settingsBox.get('reminder_counter', defaultValue: 0);

    currentNumber++;

    settingsBox.put('reminder_counter', currentNumber);

    return 'REM-${currentNumber.toString().padLeft(4, '0')}';
  }

  /// Seeds the payment counter so the next ID continues from [maxValue].
  static void setInitialPaymentId(int maxValue) {
    final settingsBox = Hive.box(HiveBoxes.settings);
    final existing = settingsBox.get('payment_counter', defaultValue: 0);
    if (maxValue > existing) {
      settingsBox.put('payment_counter', maxValue);
    }
  }

  static String generatePaymentId() {
    final settingsBox = Hive.box(HiveBoxes.settings);

    int currentNumber = settingsBox.get('payment_counter', defaultValue: 0);

    currentNumber++;

    settingsBox.put('payment_counter', currentNumber);

    return 'PAY-${currentNumber.toString().padLeft(4, '0')}';
  }
}
