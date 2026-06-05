import 'package:hive/hive.dart';

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

  Customer({
    required this.customerId,
    required this.name,
    required this.contact1,
    this.contact2,
    this.address,
    this.email,
    this.gstNumber,
    this.panNumber,
  });
}