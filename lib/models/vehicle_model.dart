import 'package:hive/hive.dart';

part 'vehicle_model.g.dart';

@HiveType(typeId: 1)
class Vehicle extends HiveObject {
  @HiveField(0)
  String vehicleId;

  @HiveField(1)
  String customerId;

  @HiveField(2)
  String registrationNumber;

  @HiveField(3)
  String make;

  @HiveField(4)
  String model;

  @HiveField(5)
  String? vehicleColor;

  @HiveField(6)
  String fuelType;

  @HiveField(7)
  String? chassisNumber;

  @HiveField(8)
  String? engineNumber;

  Vehicle({
    required this.vehicleId,
    required this.customerId,
    required this.registrationNumber,
    required this.make,
    required this.model,
    this.vehicleColor,
    required this.fuelType,
    this.chassisNumber,
    this.engineNumber,
  });
}
