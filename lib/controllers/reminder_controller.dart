// import 'package:get/get.dart';
// import 'package:hive/hive.dart';

// import '../database/hive_boxes.dart';
// import '../models/reminder_model.dart';
// import '../models/sync_status.dart';
// import '../services/supabase_sync_service.dart';

// class ReminderController extends GetxController {
//   final Box<Reminder> reminderBox = Hive.box<Reminder>(HiveBoxes.reminders);

//   /// SOURCE OF TRUTH
//   List<Reminder> get reminders =>
//       reminderBox.values.where((r) => !r.isDeleted).toList();

//   /// ALL REMINDERS (INCLUDING DELETED)
//   List<Reminder> get allReminders => reminderBox.values.toList();

//   /// PENDING RECORDS FOR SUPABASE SYNC
//   List<Reminder> get pendingReminders {
//     return reminderBox.values
//         .where((r) => r.syncStatus == SyncStatus.pending)
//         .toList();
//   }

//   Future<void> addReminder(Reminder reminder) async {
//     reminder.updatedAt = DateTime.now();
//     reminder.isDeleted = false;
//     reminder.syncStatus = SyncStatus.pending;

//     await reminderBox.put(reminder.reminderId, reminder);

//     update();
//     Get.find<SupabaseSyncService>().syncReminders();
//   }

//   Future<void> updateReminder(Reminder reminder) async {
//     reminder.updatedAt = DateTime.now();
//     reminder.syncStatus = SyncStatus.pending;

//     await reminderBox.put(reminder.reminderId, reminder);

//     update();
//     Get.find<SupabaseSyncService>().syncReminders();
//   }

//   Future<void> deleteReminder(String reminderId) async {
//     final reminder = reminderBox.get(reminderId);

//     if (reminder == null) return;

//     reminder.updatedAt = DateTime.now();
//     reminder.isDeleted = true;
//     reminder.syncStatus = SyncStatus.pending;

//     await reminderBox.put(reminderId, reminder);

//     update();
//     Get.find<SupabaseSyncService>().syncReminders();
//   }

//   /// CALLED BY SUPABASE SYNC SERVICE
//   Future<void> markAsSynced(String reminderId) async {
//     final reminder = reminderBox.get(reminderId);

//     if (reminder == null) return;

//     reminder.syncStatus = SyncStatus.synced;

//     await reminderBox.put(reminderId, reminder);

//     update();
//   }

//   /// CALLED WHEN PULLING DATA FROM SUPABASE
//   Future<void> upsertFromRemote(Reminder remoteReminder) async {
//     final local = reminderBox.get(remoteReminder.reminderId);

//     if (local == null || remoteReminder.updatedAt.isAfter(local.updatedAt)) {
//       remoteReminder.syncStatus = SyncStatus.synced;

//       await reminderBox.put(remoteReminder.reminderId, remoteReminder);

//       update();
//     }
//   }

//   List<Reminder> getUpcomingReminders() {
//     return reminders
//         .where(
//           (reminder) =>
//               !reminder.completed && reminder.dueDate.isAfter(DateTime.now()),
//         )
//         .toList();
//   }

//   List<Reminder> getOverdueReminders() {
//     return reminders
//         .where(
//           (reminder) =>
//               !reminder.completed && reminder.dueDate.isBefore(DateTime.now()),
//         )
//         .toList();
//   }

//   List<Reminder> getDueThisWeek() {
//     final now = DateTime.now();
//     final endOfWeek = now.add(Duration(days: 7 - now.weekday));

//     return reminders
//         .where(
//           (reminder) =>
//               !reminder.completed &&
//               reminder.dueDate.isAfter(now) &&
//               reminder.dueDate.isBefore(endOfWeek),
//         )
//         .toList();
//   }

//   List<Reminder> getDueThisMonth() {
//     final now = DateTime.now();
//     final endOfMonth = DateTime(now.year, now.month + 1, 1);

//     return reminders
//         .where(
//           (reminder) =>
//               !reminder.completed &&
//               reminder.dueDate.isAfter(now) &&
//               reminder.dueDate.isBefore(endOfMonth),
//         )
//         .toList();
//   }

//   List<Reminder> getCompletedReminders() {
//     return reminders.where((r) => r.completed).toList();
//   }

//   Reminder? getReminderByInvoiceId(String invoiceId) {
//     return reminders.firstWhereOrNull(
//       (reminder) => reminder.invoiceId == invoiceId,
//     );
//   }

//   Future<void> deleteByInvoiceId(String invoiceId) async {
//     final reminders = reminderBox.values.where((r) => r.invoiceId == invoiceId && !r.isDeleted).toList();

//     for (final reminder in reminders) {
//       reminder.updatedAt = DateTime.now();
//       reminder.isDeleted = true;
//       reminder.syncStatus = SyncStatus.pending;
//       await reminderBox.put(reminder.reminderId, reminder);
//     }

//     if (reminders.isNotEmpty) {
//       update();
//       Get.find<SupabaseSyncService>().syncReminders();
//     }
//   }
// }
import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '../database/hive_boxes.dart';
import '../models/reminder_model.dart';
import '../models/sync_status.dart';
import '../services/supabase_sync_service.dart';

class ReminderController extends GetxController {
  final Box<Reminder> reminderBox = Hive.box<Reminder>(HiveBoxes.reminders);

  // ==========================================================
  // SOURCE OF TRUTH
  // ==========================================================

  List<Reminder> get reminders =>
      reminderBox.values.where((r) => !r.isDeleted).toList();

  List<Reminder> get allReminders => reminderBox.values.toList();

  List<Reminder> get pendingReminders => reminderBox.values
      .where((r) => r.syncStatus == SyncStatus.pending)
      .toList();

  // ==========================================================
  // CRUD
  // ==========================================================

  Future<void> addReminder(Reminder reminder) async {
    reminder.updatedAt = DateTime.now();
    reminder.syncStatus = SyncStatus.pending;
    reminder.isDeleted = false;

    await reminderBox.put(reminder.reminderId, reminder);

    update();
    Get.find<SupabaseSyncService>().syncReminders();
  }

  Future<void> updateReminder(Reminder reminder) async {
    reminder.updatedAt = DateTime.now();
    reminder.syncStatus = SyncStatus.pending;

    await reminderBox.put(reminder.reminderId, reminder);

    update();
    Get.find<SupabaseSyncService>().syncReminders();
  }

  Future<void> deleteReminder(String reminderId) async {
    final reminder = reminderBox.get(reminderId);

    if (reminder == null) return;

    reminder.updatedAt = DateTime.now();
    reminder.isDeleted = true;
    reminder.syncStatus = SyncStatus.pending;

    await reminderBox.put(reminder.reminderId, reminder);

    update();
    Get.find<SupabaseSyncService>().syncReminders();
  }

  Future<void> toggleCompleted(String reminderId) async {
    final reminder = reminderBox.get(reminderId);

    if (reminder == null) return;

    reminder.completed = !reminder.completed;
    reminder.updatedAt = DateTime.now();
    reminder.syncStatus = SyncStatus.pending;

    await reminderBox.put(reminder.reminderId, reminder);

    update();
    Get.find<SupabaseSyncService>().syncReminders();
  }

  // ==========================================================
  // SYNC
  // ==========================================================

  Future<void> markAsSynced(String reminderId) async {
    final reminder = reminderBox.get(reminderId);

    if (reminder == null) return;

    reminder.syncStatus = SyncStatus.synced;

    await reminderBox.put(reminderId, reminder);

    update();
  }

  Future<void> upsertFromRemote(Reminder remoteReminder) async {
    final local = reminderBox.get(remoteReminder.reminderId);

    if (local == null || remoteReminder.updatedAt.isAfter(local.updatedAt)) {
      remoteReminder.syncStatus = SyncStatus.synced;

      await reminderBox.put(remoteReminder.reminderId, remoteReminder);

      update();
    }
  }

  // ==========================================================
  // LOOKUPS
  // ==========================================================

  Reminder? getReminderById(String reminderId) {
    return reminders.firstWhereOrNull((r) => r.reminderId == reminderId);
  }

  List<Reminder> getRemindersByInvoiceId(String invoiceId) {
    return reminders.where((r) => r.invoiceId == invoiceId).toList();
  }

  Reminder? getReminderByInvoiceId(String invoiceId) {
    final list = getRemindersByInvoiceId(invoiceId);
    if (list.isEmpty) return null;
    list.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return list.first;
  }

  List<Reminder> getRemindersForVehicle(String vehicleId) {
    final list = reminders.where((r) => r.vehicleId == vehicleId).toList();

    list.sort((a, b) => a.dueDate.compareTo(b.dueDate));

    return list;
  }

  List<Reminder> getRemindersForCustomer(String customerId) {
    final list = reminders.where((r) => r.customerId == customerId).toList();

    list.sort((a, b) => a.dueDate.compareTo(b.dueDate));

    return list;
  }

  List<Reminder> getServiceReminders() {
    return reminders.where((r) => r.type == ReminderType.service).toList();
  }

  List<Reminder> getInvoiceReminders() {
    return reminders.where((r) => r.type == ReminderType.invoice).toList();
  }

  // ==========================================================
  // FILTERS
  // ==========================================================

  List<Reminder> getUpcomingReminders() {
    final list = reminders
        .where((r) => !r.completed && r.dueDate.isAfter(DateTime.now()))
        .toList();

    list.sort((a, b) => a.dueDate.compareTo(b.dueDate));

    return list;
  }

  List<Reminder> getOverdueReminders() {
    final list = reminders
        .where((r) => !r.completed && r.dueDate.isBefore(DateTime.now()))
        .toList();

    list.sort((a, b) => a.dueDate.compareTo(b.dueDate));

    return list;
  }

  List<Reminder> getDueToday() {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final endOfToday = startOfToday.add(const Duration(days: 1));

    return reminders.where((r) {
      return !r.completed &&
          r.dueDate.isAfter(startOfToday) &&
          r.dueDate.isBefore(endOfToday);
    }).toList();
  }

  List<Reminder> getDueThisWeek() {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final endOfWeek = startOfToday.add(
      Duration(days: 8 - now.weekday),
    );

    final list = reminders
        .where(
          (r) =>
              !r.completed &&
              r.dueDate.isAfter(startOfToday) &&
              r.dueDate.isBefore(endOfWeek),
        )
        .toList();

    list.sort((a, b) => a.dueDate.compareTo(b.dueDate));

    return list;
  }

  List<Reminder> getDueThisMonth() {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final endOfMonth = DateTime(now.year, now.month + 1, 1);

    final list = reminders
        .where(
          (r) =>
              !r.completed &&
              r.dueDate.isAfter(startOfToday) &&
              r.dueDate.isBefore(endOfMonth),
        )
        .toList();

    list.sort((a, b) => a.dueDate.compareTo(b.dueDate));

    return list;
  }

  List<Reminder> getCompletedReminders() {
    final list = reminders.where((r) => r.completed).toList();

    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    return list;
  }

  // ==========================================================
  // BULK OPERATIONS
  // ==========================================================

  Future<void> deleteByInvoiceId(String invoiceId) async {
    final list = reminderBox.values
        .where((r) => r.invoiceId == invoiceId && !r.isDeleted)
        .toList();

    for (final reminder in list) {
      reminder.updatedAt = DateTime.now();
      reminder.isDeleted = true;
      reminder.syncStatus = SyncStatus.pending;

      await reminderBox.put(reminder.reminderId, reminder);
    }

    if (list.isNotEmpty) {
      update();
      Get.find<SupabaseSyncService>().syncReminders();
    }
  }
}
