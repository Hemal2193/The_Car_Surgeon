import 'package:supabase_flutter/supabase_flutter.dart';

import 'id_generator.dart';

/// Resolves the max numeric ID from Supabase for each entity type
/// and seeds the IdGenerator on app startup.
///
/// Prefers Supabase as source of truth.
/// If Supabase has no records, generators fall back to Hive defaults.
class IdResolver {
  final SupabaseClient supabase = Supabase.instance.client;

  /// Fetches the max numeric ID for all entity types from Supabase
  /// and seeds the IdGenerator counters so new IDs continue from there.
  static Future<void> seedAllGenerators() async {
    final resolver = IdResolver();

    final maxCustomer =
        await resolver._resolveMax('customers', 'customer_id', 'CUST-');
    final maxVehicle =
        await resolver._resolveMax('vehicles', 'vehicle_id', 'VEH-');
    final maxItem =
        await resolver._resolveMax('items', 'item_id', 'ITEM-');
    final maxInvoice =
        await resolver._resolveMax('invoices', 'invoice_id', 'INV-');
    final maxReminder =
        await resolver._resolveMax('reminders', 'reminder_id', 'REM-');

    if (maxCustomer != null) {
      IdGenerator.setInitialCustomerId(maxCustomer);
    }
    if (maxVehicle != null) {
      IdGenerator.setInitialVehicleId(maxVehicle);
    }
    if (maxItem != null) {
      IdGenerator.setInitialItemId(maxItem);
    }
    if (maxInvoice != null) {
      IdGenerator.setInitialInvoiceId(maxInvoice);
    }
    if (maxReminder != null) {
      IdGenerator.setInitialReminderId(maxReminder);
    }
  }

  /// Queries Supabase for all IDs in the given [table] and [column],
  /// parses the numeric portion after [prefix], and returns the highest value.
  ///
  /// Returns `null` if the table is empty or on error (Hive fallback).
  Future<int?> _resolveMax(String table, String column, String prefix) async {
    try {
      final response = await supabase.from(table).select(column);

      if (response.isEmpty) return null;

      int maxNumber = 0;
      for (final row in response) {
        final id = row[column] as String?;
        if (id != null && id.startsWith(prefix)) {
          final numericPart = id.substring(prefix.length);
          final number = int.tryParse(numericPart);
          if (number != null && number > maxNumber) {
            maxNumber = number;
          }
        }
      }

      return maxNumber;
    } catch (e) {
      // Supabase query failed — fall back to Hive defaults
      print('IdResolver error for $table: $e');
      return null;
    }
  }
}