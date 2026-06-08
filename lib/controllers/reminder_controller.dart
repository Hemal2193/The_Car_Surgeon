import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:hive/hive.dart';
import 'package:tcs/database/hive_boxes.dart';
import 'package:tcs/models/reminder_model.dart';

class ReminderController extends GetxController {
  final Box<Reminder> reminderBox = Hive.box<Reminder>(HiveBoxes.reminders);

  Future<void> addReminder(Reminder reminder) async {
    await reminderBox.put(reminder.reminderId, reminder);
    update();
  }

  Future<void> updateReminder(Reminder reminder) async {
    await reminderBox.put(reminder.reminderId, reminder);
    update();
  }

  Future<void> deleteReminder(String reminderId) async {
    await reminderBox.delete(reminderId);
    update();
  }

  List<Reminder> getUpcomingReminders() {
    return reminderBox.values
        .where(
          (reminder) =>
              !reminder.completed && reminder.dueDate.isAfter(DateTime.now()),
        )
        .toList();
  }

  List<Reminder> getOverdueReminders() {
    return reminderBox.values
        .where(
          (reminder) =>
              !reminder.completed && reminder.dueDate.isBefore(DateTime.now()),
        )
        .toList();
  }

  List<Reminder> getDueThisWeek() {
    final now = DateTime.now();
    final endOfWeek = now.add(Duration(days: 7 - now.weekday));
    return reminderBox.values
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
    return reminderBox.values
        .where(
          (reminder) =>
              !reminder.completed &&
              reminder.dueDate.isAfter(now) &&
              reminder.dueDate.isBefore(endOfMonth),
        )
        .toList();
  }

  List<Reminder> getCompletedReminders() {
  return reminderBox.values.where((r) => r.completed).toList();
}

  // This controller will handle all the logic related to reminders, such as creating, updating, and deleting reminders.
}
