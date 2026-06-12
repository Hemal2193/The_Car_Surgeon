import 'package:hive/hive.dart';
import 'package:tcs/models/sync_status.dart';

part 'customer_model.g.dart';

@HiveType(typeId: 0)
class Customer extends HiveObject {
  @HiveField(0)
  String customerId;

  @HiveField(1)
  String name;

  @HiveField(2)
  String contact1;

  @HiveField(3)
  String? contact2;

  @HiveField(4)
  String? address;

  @HiveField(5)
  String? email;

  @HiveField(6)
  String? gstNumber;

  @HiveField(7)
  String? panNumber;

  @HiveField(8)
  DateTime updatedAt;

  @HiveField(9)
  bool isDeleted;

  @HiveField(10)
  SyncStatus syncStatus;

  Customer({
    required this.customerId,
    required this.name,
    required this.contact1,
    this.contact2,
    this.address,
    this.email,
    this.gstNumber,
    this.panNumber,

    DateTime? updatedAt,
    this.isDeleted = false,
    this.syncStatus = SyncStatus.synced,
  }) : updatedAt = updatedAt ?? DateTime.now();
}
