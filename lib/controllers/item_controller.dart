import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '../database/hive_boxes.dart';
import '../models/item_model.dart';

class ItemController extends GetxController {
  final Box<Item> itemBox = Hive.box<Item>(HiveBoxes.items);

  List<Item> get items => itemBox.values.toList();

  Future<void> addItem(Item item) async {
    await itemBox.put(item.itemId, item);
    update();
  }

  Future<void> deleteItem(String id) async {
    await itemBox.delete(id);
    update();
  }
}
