import 'package:hive/hive.dart';

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

  Item({
    required this.itemId,
    required this.name,
    required this.type,
    this.hsnSac,
    required this.gst,
    this.price,
  });
}
