import 'package:hive/hive.dart';

import 'sync_status.dart';

part 'reminder_model.g.dart';

@HiveType(typeId: 5)
class Reminder extends HiveObject {
  // ==========================================================
  // BASIC
  // ==========================================================

  @HiveField(0)
  String reminderId;

  @HiveField(1)
  ReminderType type;

  @HiveField(2)
  String customerId;

  @HiveField(3)
  String vehicleId;

  @HiveField(4)
  String? invoiceId;

  // ==========================================================
  // REMINDER DETAILS
  // ==========================================================

  @HiveField(5)
  String title;

  @HiveField(6)
  String? notes;

  @HiveField(7)
  DateTime dueDate;

  @HiveField(8)
  bool completed;

  // ==========================================================
  // SYNC
  // ==========================================================

  @HiveField(9)
  DateTime createdAt;

  @HiveField(10)
  DateTime updatedAt;

  @HiveField(11)
  bool isDeleted;

  @HiveField(12)
  SyncStatus syncStatus;

  Reminder({
    required this.reminderId,
    required this.type,
    required this.customerId,
    required this.vehicleId,
    this.invoiceId,
    required this.title,
    this.notes,
    required this.dueDate,
    this.completed = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isDeleted = false,
    this.syncStatus = SyncStatus.pending,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();
}

@HiveType(typeId: 8)
enum ReminderType {
  @HiveField(0)
  service,

  @HiveField(1)
  invoice,
}