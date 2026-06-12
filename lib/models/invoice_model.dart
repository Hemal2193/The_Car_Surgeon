import 'package:hive/hive.dart';

import 'sync_status.dart';

part 'invoice_model.g.dart';

@HiveType(typeId: 3)
class Invoice extends HiveObject {
  @HiveField(0)
  String invoiceId;

  @HiveField(1)
  String customerId;

  @HiveField(2)
  String vehicleId;

  @HiveField(3)
  DateTime dateTime;

  @HiveField(4)
  List<InvoiceItem> items;

  @HiveField(5)
  double grandTotal;

  // ==========================
  // SYNC FIELDS
  // ==========================

  @HiveField(6)
  DateTime updatedAt;

  @HiveField(7)
  bool isDeleted;

  @HiveField(8)
  SyncStatus syncStatus;

  Invoice({
    required this.invoiceId,
    required this.customerId,
    required this.vehicleId,
    required this.dateTime,
    required this.items,
    required this.grandTotal,

    DateTime? updatedAt,
    this.isDeleted = false,
    this.syncStatus = SyncStatus.pending,
  }) : updatedAt = updatedAt ?? DateTime.now();
}

@HiveType(typeId: 4)
class InvoiceItem {
  @HiveField(0)
  String itemId;

  @HiveField(1)
  String name;

  @HiveField(2)
  String? hsnSac;

  @HiveField(3)
  int qty;

  @HiveField(4)
  double rate;

  @HiveField(5)
  double taxPercent;

  @HiveField(6)
  double taxAmount;

  @HiveField(7)
  double totalAmount;

  @HiveField(8)
  String type;

  InvoiceItem({
    required this.itemId,
    required this.name,
    required this.hsnSac,
    required this.qty,
    required this.rate,
    required this.taxPercent,
    required this.taxAmount,
    required this.totalAmount,
    required this.type,
  });
}
