import 'package:hive/hive.dart';

import 'sync_status.dart';

part 'payment_model.g.dart';

@HiveType(typeId: 7)
class Payment extends HiveObject {
  @HiveField(0)
  String paymentId;

  @HiveField(1)
  String invoiceId;

  @HiveField(2)
  DateTime dateTime;

  @HiveField(3)
  String mode;

  @HiveField(4)
  double amount;

  @HiveField(5)
  String? notes;

  // ==========================
  // SYNC FIELDS
  // ==========================

  @HiveField(6)
  DateTime updatedAt;

  @HiveField(7)
  bool isDeleted;

  @HiveField(8)
  SyncStatus syncStatus;

  Payment({
    required this.paymentId,
    required this.invoiceId,
    required this.dateTime,
    required this.mode,
    required this.amount,
    this.notes,

    DateTime? updatedAt,
    this.isDeleted = false,
    this.syncStatus = SyncStatus.pending,
  }) : updatedAt = updatedAt ?? DateTime.now();
}