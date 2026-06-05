import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tcs/widgets/delete_confirmation_dialog.dart';

import '../../controllers/item_controller.dart';
import '../../models/item_model.dart';
import '../../widgets/adder_button.dart';
import '../../widgets/app_popup_menu.dart';
import 'add_item_dialog.dart';

class ItemsScreen extends StatelessWidget {
  const ItemsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // HEADER
          Row(
            children: [
              const Text(
                'Items',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              adderButton(
                label: 'Add Item',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => const AddItemDialog(),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 20),

          // SEARCH (UI only for now)
          TextField(
            decoration: InputDecoration(
              hintText: 'Search item...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.black26),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.black, width: 1.5),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // TABLE
          Expanded(
            child: GetBuilder<ItemController>(
              builder: (controller) {
                final List<Item> items = controller.items;

                if (items.isEmpty) {
                  return Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(child: Text('No items found')),
                  );
                }

                return Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Item')),
                        DataColumn(label: Text('Type')),
                        DataColumn(label: Text('HSN/SAC')),
                        DataColumn(label: Text('GST %')),
                        DataColumn(label: Text('Rate')),
                        DataColumn(label: Text('Total')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: items
                          .map((item) => _buildRow(context, controller, item))
                          .toList(),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  DataRow _buildRow(
    BuildContext context,
    ItemController controller,
    Item item,
  ) {
    final double rate = item.price ?? 0;
    final double gst = item.gst;

    // FINAL TOTAL CALCULATION
    final double total = rate + (rate * gst / 100);

    return DataRow(
      cells: [
        DataCell(Text(item.name)),
        DataCell(Text(item.type)),
        DataCell(Text(item.hsnSac ?? '-')),
        DataCell(Text('${item.gst}%')),

        // RATE COLUMN (was Price)
        DataCell(Text(rate.toStringAsFixed(2))),

        // TOTAL COLUMN (Rate + GST)
        DataCell(Text(total.toStringAsFixed(2))),

        DataCell(
          AppPopupMenu(
            onEdit: () {
              print('Edit ${item.itemId}');
            },

            onDelete: () {
              showDialog(
                context: context,
                builder: (dialogContext) {
                  return DeleteConfirmationDialog(
                    title: 'Delete Item',
                    message:
                        'Are you sure you want to delete ${item.name}?',
                    onDelete: () async {
                      final itemController = Get.find<ItemController>();

                      await itemController.deleteItem(
                        item.itemId,
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
