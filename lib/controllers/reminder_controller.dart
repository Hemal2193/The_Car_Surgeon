import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '../database/hive_boxes.dart';
import '../models/reminder_model.dart';
import '../models/sync_status.dart';

class ReminderController extends GetxController {
  final Box<Reminder> reminderBox = Hive.box<Reminder>(HiveBoxes.reminders);

  /// SOURCE OF TRUTH
  List<Reminder> get reminders =>
      reminderBox.values.where((r) => !r.isDeleted).toList();

  /// ALL REMINDERS (INCLUDING DELETED)
  List<Reminder> get allReminders => reminderBox.values.toList();

  /// PENDING RECORDS FOR SUPABASE SYNC
  List<Reminder> get pendingReminders {
    return reminderBox.values
        .where((r) => r.syncStatus == SyncStatus.pending)
        .toList();
  }

  Future<void> addReminder(Reminder reminder) async {
    reminder.updatedAt = DateTime.now();
    reminder.isDeleted = false;
    reminder.syncStatus = SyncStatus.pending;

    await reminderBox.put(reminder.reminderId, reminder);

    update();
  }

  Future<void> updateReminder(Reminder reminder) async {
    reminder.updatedAt = DateTime.now();
    reminder.syncStatus = SyncStatus.pending;

    await reminderBox.put(reminder.reminderId, reminder);

    update();
  }

  Future<void> deleteReminder(String reminderId) async {
    final reminder = reminderBox.get(reminderId);

    if (reminder == null) return;

    reminder.updatedAt = DateTime.now();
    reminder.isDeleted = true;
    reminder.syncStatus = SyncStatus.pending;

    await reminderBox.put(reminderId, reminder);

    update();
  }

  /// CALLED BY SUPABASE SYNC SERVICE
  Future<void> markAsSynced(String reminderId) async {
    final reminder = reminderBox.get(reminderId);

    if (reminder == null) return;

    reminder.syncStatus = SyncStatus.synced;

    await reminderBox.put(reminderId, reminder);

    update();
  }

  /// CALLED WHEN PULLING DATA FROM SUPABASE
  Future<void> upsertFromRemote(Reminder remoteReminder) async {
    final local = reminderBox.get(remoteReminder.reminderId);

    if (local == null || remoteReminder.updatedAt.isAfter(local.updatedAt)) {
      remoteReminder.syncStatus = SyncStatus.synced;

      await reminderBox.put(remoteReminder.reminderId, remoteReminder);

      update();
    }
  }

  List<Reminder> getUpcomingReminders() {
    return reminders
        .where(
          (reminder) =>
              !reminder.completed && reminder.dueDate.isAfter(DateTime.now()),
        )
        .toList();
  }

  List<Reminder> getOverdueReminders() {
    return reminders
        .where(
          (reminder) =>
              !reminder.completed && reminder.dueDate.isBefore(DateTime.now()),
        )
        .toList();
  }

  List<Reminder> getDueThisWeek() {
    final now = DateTime.now();
    final endOfWeek = now.add(Duration(days: 7 - now.weekday));

    return reminders
        .where(
          (reminder) =>
              !reminder.completed &&
              reminder.dueDate.isAfter(now) &&
              reminder.dueDate.isBefore(endOfWeek),
        )
        .toList();
  }

  List<Reminder> getDueThisMonth() {
    final now = DateTime.now();
    final endOfMonth = DateTime(now.year, now.month + 1, 1);

    return reminders
        .where(
          (reminder) =>
              !reminder.completed &&
              reminder.dueDate.isAfter(now) &&
              reminder.dueDate.isBefore(endOfMonth),
        )
        .toList();
  }

  List<Reminder> getCompletedReminders() {
    return reminders.where((r) => r.completed).toList();
  }

  Reminder? getReminderByInvoiceId(String invoiceId) {
    return reminders.firstWhereOrNull(
      (reminder) => reminder.invoiceId == invoiceId,
    );
  }
}
