import 'package:hive/hive.dart';

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

  Reminder({
    required this.reminderId,
    required this.customerId,
    required this.vehicleId,
    this.invoiceId,
    required this.dueDate,
    required this.title,
    this.notes,
    this.completed = false,
  });
}