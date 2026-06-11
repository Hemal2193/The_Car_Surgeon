import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:tcs/utils/responsive.dart';
import 'package:tcs/widgets/delete_confirmation_dialog.dart';
import 'package:tcs/widgets/erp_mobile_tile.dart';

import '../../controllers/item_controller.dart';
import '../../models/item_model.dart';
import '../../widgets/adder_button.dart';
import '../../widgets/app_popup_menu.dart';
import 'add_item_dialog.dart';

class ItemsScreen extends StatefulWidget {
  const ItemsScreen({super.key});

  @override
  State<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isAndroid || Platform.isIOS) {
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.white, // background
          statusBarIconBrightness: Brightness.dark, // Android icons
          statusBarBrightness: Brightness.light, // iOS icons
        ),
      );
    }
    if (Responsive.isDesktop(context)) {
      return _buildDesktopItems();
    }

    return _buildMobileItems();
  }

  Widget _buildDesktopItems() {
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
            controller: _searchController,
            onChanged: (value) {
              setState(() => _searchQuery = value.trim().toLowerCase());
            },
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
                final List<Item> items = controller.items.where((item) {
                  if (_searchQuery.isEmpty) return true;

                  return item.itemId.toLowerCase().contains(_searchQuery) ||
                      item.name.toLowerCase().contains(_searchQuery) ||
                      item.type.toLowerCase().contains(_searchQuery) ||
                      (item.hsnSac ?? '').toLowerCase().contains(_searchQuery);
                }).toList();

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

  Widget _buildMobileItems() {
    return
    // backgroundColor: Colors.transparent,
    // extendBody: true,
    // floatingActionButton: FloatingActionButton.extended(
    //   label: const Text("Add Item"),
    //   icon: const Icon(Icons.add),
    //   backgroundColor: Colors.black,
    //   foregroundColor: Colors.white,
    //   onPressed: () {
    //     showModalBottomSheet(
    //       context: context,
    //       isScrollControlled: true,
    //       isDismissible: true,
    //       enableDrag: true,
    //       backgroundColor: Colors.transparent,
    //       builder: (_) => AddItemDialog(),
    //     );
    //   },
    // ),
    SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Column(
          children: [
            _buildMobileHeader(),

            const SizedBox(height: 16),

            _buildSearch(),

            const SizedBox(height: 16),

            Expanded(child: _buildMobileItemList()),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileHeader() {
    return const Align(
      alignment: Alignment.centerLeft,
      child: Text(
        'Items',
        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildSearch() {
    return TextField(
      controller: _searchController,
      onChanged: (value) {
        setState(() {
          _searchQuery = value.trim().toLowerCase();
        });
      },
      decoration: InputDecoration(
        hintText: 'Search item...',
        prefixIcon: const Icon(Icons.search),

        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }

  Widget _buildMobileItemList() {
    return GetBuilder<ItemController>(
      builder: (controller) {
        final items = controller.items.where((item) {
          if (_searchQuery.isEmpty) {
            return true;
          }

          return item.itemId.toLowerCase().contains(_searchQuery) ||
              item.name.toLowerCase().contains(_searchQuery) ||
              item.type.toLowerCase().contains(_searchQuery) ||
              (item.hsnSac ?? '').toLowerCase().contains(_searchQuery);
        }).toList();

        if (items.isEmpty) {
          return const Center(child: Text('No items found'));
        }

        return ListView.builder(
          padding: EdgeInsets.only(bottom: 150),

          itemCount: items.length,

          itemBuilder: (context, index) {
            return _buildItemTile(items[index]);
          },
        );
      },
    );
  }

  Widget _buildItemTile(Item item) {
    final rate = item.price ?? 0.0;

    final total = rate + (rate * item.gst / 100);

    return ErpMobileTile(
      leading: CircleAvatar(
        backgroundColor: Colors.grey.shade100,

        child: Icon(
          item.type.toLowerCase() == 'product'
              ? Icons.inventory_2_outlined
              : item.type.toLowerCase() == 'service'
              ? Icons.build_outlined
              : Icons.handyman_outlined,
          color: Colors.black87,
        ),
      ),

      title: item.name,

      subtitles: [
        item.type,

        'GST ${item.gst}%',

        'Rate ₹${rate.toStringAsFixed(0)}'
            ' • Total ₹${total.toStringAsFixed(0)}',
      ],

      trailing: AppPopupMenu(
        onEdit: () {
          showDialog(
            context: context,

            builder: (_) {
              return AddItemDialog(item: item);
            },
          );
        },

        onDelete: () {
          showDialog(
            context: context,

            builder: (_) {
              return DeleteConfirmationDialog(
                title: 'Delete Item',

                message:
                    'Are you sure you want to delete '
                    '${item.name}?',

                onDelete: () async {
                  await Get.find<ItemController>().deleteItem(item.itemId);
                },
              );
            },
          );
        },
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
              showDialog(
                context: context,
                builder: (context) {
                  return AddItemDialog(item: item);
                },
              );
            },

            onDelete: () {
              showDialog(
                context: context,
                builder: (dialogContext) {
                  return DeleteConfirmationDialog(
                    title: 'Delete Item',
                    message: 'Are you sure you want to delete ${item.name}?',
                    onDelete: () async {
                      final itemController = Get.find<ItemController>();

                      await itemController.deleteItem(item.itemId);
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
