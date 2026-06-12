import 'package:hive/hive.dart';

import 'sync_status.dart';

part 'reminder_model.g.dart';

@HiveType(typeId: 5)
class Reminder extends HiveObject {
  @HiveField(0)
  String reminderId;

  @HiveField(1)
  String customerId;

  @HiveField(2)
  String vehicleId;

  @HiveField(3)
  String? invoiceId;

  @HiveField(4)
  DateTime dueDate;

  @HiveField(5)
  String title;

  @HiveField(6)
  String? notes;

  @HiveField(7)
  bool completed;

  // ==========================
  // SYNC FIELDS
  // ==========================

  @HiveField(8)
  DateTime updatedAt;

  @HiveField(9)
  bool isDeleted;

  @HiveField(10)
  SyncStatus syncStatus;

  Reminder({
    required this.reminderId,
    required this.customerId,
    required this.vehicleId,
    this.invoiceId,
    required this.dueDate,
    required this.title,
    this.notes,
    this.completed = false,

    DateTime? updatedAt,
    this.isDeleted = false,
    this.syncStatus = SyncStatus.pending,
  }) : updatedAt = updatedAt ?? DateTime.now();
}
