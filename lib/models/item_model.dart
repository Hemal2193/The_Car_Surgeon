import 'package:hive/hive.dart';

import 'sync_status.dart';

part 'item_model.g.dart';

@HiveType(typeId: 2)
class Item extends HiveObject {
  @HiveField(0)
  String itemId;

  @HiveField(1)
  String name;

  @HiveField(2)
  String type; // Product / Service / Labour

  @HiveField(3)
  String? hsnSac;

  @HiveField(4)
  double gst;

  @HiveField(5)
  double? price;

  @HiveField(6)
  DateTime updatedAt;

  @HiveField(7)
  bool isDeleted;

  @HiveField(8)
  SyncStatus syncStatus;

  Item({
    required this.itemId,
    required this.name,
    required this.type,
    this.hsnSac,
    required this.gst,
    this.price,
    DateTime? updatedAt,
    this.isDeleted = false,
    this.syncStatus = SyncStatus.pending,
  }) : updatedAt = updatedAt ?? DateTime.now();
}