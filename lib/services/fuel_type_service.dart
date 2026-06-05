import 'package:hive/hive.dart';
import 'package:tcs/database/hive_boxes.dart';

class FuelTypeService {
  static Box get box => Hive.box(HiveBoxes.settings);

  static List<String> getAll() {
    final list = box.get('fuel_types', defaultValue: <String>[]);
    return List<String>.from(list);
  }

  static void add(String value) {
    final list = getAll();

    if (!list.contains(value)) {
      list.add(value);
      box.put('fuel_types', list);
    }
  }
}
