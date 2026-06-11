import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tcs/database/id_generator.dart';
import 'package:tcs/utils/responsive.dart';

import '../../controllers/item_controller.dart';
import '../../models/item_model.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/custom_button.dart';

class AddItemDialog extends StatefulWidget {
  final ScrollController? scrollController;

  final Item? item;

  const AddItemDialog({super.key, this.item, this.scrollController});

  @override
  State<AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<AddItemDialog> {
  final nameController = TextEditingController();
  final hsnController = TextEditingController();
  final priceController = TextEditingController();

  final types = ['Product', 'Service', 'Labour'];
  final gstOptions = ['0%', '5%', '12%', '18%', '28%', '40%'];

  String selectedType = 'Product';
  String selectedGst = '18%';

  // =====================================================
  // QTY TYPE SYSTEM (UPDATED)
  // =====================================================
  final List<String> qtyTypes = ['Pcs', 'Litre'];
  String selectedQtyType = 'Pcs';

  final LayerLink _gstLink = LayerLink();
  OverlayEntry? _gstOverlay;

  bool get isEditing => widget.item != null;

  @override
  void initState() {
    super.initState();

    final item = widget.item;
    if (item != null) {
      nameController.text = item.name;
      hsnController.text = item.hsnSac ?? '';
      priceController.text = item.price?.toString() ?? '';
      selectedType = item.type;
      selectedGst =
          '${item.gst.toStringAsFixed(item.gst.truncateToDouble() == item.gst ? 0 : 2)}%';
    }
  }

  @override
  void dispose() {
    _removeGstOverlay();
    nameController.dispose();
    hsnController.dispose();
    priceController.dispose();
    super.dispose();
  }

  // =====================================================
  // GST DROPDOWN
  // =====================================================
  void _toggleGstDropdown() {
    if (_gstOverlay != null) {
      _removeGstOverlay();
    } else {
      _showGstOverlay();
    }
  }

  void _showGstOverlay() {
    final overlay = Overlay.of(context);

    _gstOverlay = OverlayEntry(
      builder: (context) {
        return Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: _removeGstOverlay,
                  child: Container(color: Colors.transparent),
                ),
              ),

              Positioned(
                width: 200,
                child: CompositedTransformFollower(
                  link: _gstLink,
                  showWhenUnlinked: false,
                  offset: const Offset(0, 50),
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.black26),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: gstOptions.map((g) {
                          return InkWell(
                            onTap: () {
                              setState(() {
                                selectedGst = g;
                              });
                              _removeGstOverlay();
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              child: Text(g),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    overlay.insert(_gstOverlay!);
  }

  void _removeGstOverlay() {
    _gstOverlay?.remove();
    _gstOverlay = null;
  }

  // =====================================================
  // ADD CUSTOM QTY TYPE
  // =====================================================
  void _showAddUnitDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add Qty Type"),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: "e.g. kg, box, meter"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                final value = controller.text.trim();

                if (value.isEmpty) return;

                setState(() {
                  qtyTypes.add(value);
                  selectedQtyType = value;
                });

                Navigator.pop(context);
              },
              child: const Text("Add"),
            ),
          ],
        );
      },
    );
  }

  // =====================================================
  // UI
  // =====================================================
  @override
  Widget build(BuildContext context) {
    if (Responsive.isDesktop(context)) {
      return _buildDesktopAddItem(context);
    }

    return _buildMobileAddItem(context);
  }

  Widget _buildDesktopAddItem(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 650,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEditing ? 'Edit Item' : 'Add Item',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            const Text(
              'Item Name *',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            AppTextField(
              hintText: 'Enter item name',
              controller: nameController,
            ),

            const SizedBox(height: 14),

            const Text('Type *', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),

            Row(
              children: types.map((t) {
                final selected = selectedType == t;

                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: GestureDetector(
                    onTap: () => setState(() => selectedType = t),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: selected ? Colors.black : Colors.white,
                        border: Border.all(color: Colors.black26),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        t,
                        style: TextStyle(
                          color: selected ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 14),

            // =====================================================
            // HSN + GST
            // =====================================================
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'HSN / SAC',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      AppTextField(
                        hintText: 'HSN code',
                        controller: hsnController,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'GST % *',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      CompositedTransformTarget(
                        link: _gstLink,
                        child: GestureDetector(
                          onTap: _toggleGstDropdown,
                          child: Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.black26),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(selectedGst),
                                const Icon(Icons.keyboard_arrow_down),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // =====================================================
            // QTY TYPE (UPDATED)
            // =====================================================
            const Text(
              'Qty Type',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),

            Wrap(
              spacing: 10,
              children: [
                ...qtyTypes.map((q) {
                  final selected = selectedQtyType == q;

                  return GestureDetector(
                    onTap: () => setState(() => selectedQtyType = q),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: selected ? Colors.black : Colors.white,
                        border: Border.all(color: Colors.black26),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        q,
                        style: TextStyle(
                          color: selected ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  );
                }),

                GestureDetector(
                  onTap: _showAddUnitDialog,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.black26),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text("+ Add"),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            const Text('Price', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            AppTextField(
              hintText: 'Optional price',
              controller: priceController,
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 22),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                cButton(() => Navigator.pop(context), 'Cancel', false),
                const SizedBox(width: 10),
                cButton(() => _saveItem(), isEditing ? 'Update' : 'Save', true),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileAddItem(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.92,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            SizedBox(height: 14),
            _handleBar(),

            Expanded(
              child: SingleChildScrollView(
                controller: widget.scrollController,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _title(),
                    const SizedBox(height: 20),

                    _field("Item Name *", nameController),
                    const SizedBox(height: 14),

                    _label("Type"),
                    Wrap(
                      spacing: 10,
                      children: types.map((t) {
                        final selected = selectedType == t;

                        return _chip(
                          t,
                          selected,
                          () => setState(() => selectedType = t),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(child: _field("HSN / SAC", hsnController)),
                        const SizedBox(width: 12),

                        Expanded(child: _gstField()),
                      ],
                    ),

                    const SizedBox(height: 14),

                    _label("Qty Type"),
                    Wrap(
                      spacing: 10,
                      children: [
                        ...qtyTypes.map((q) {
                          final selected = selectedQtyType == q;
                          return _chip(
                            q,
                            selected,
                            () => setState(() => selectedQtyType = q),
                          );
                        }),
                        _chip("+ Add", false, _showAddUnitDialog),
                      ],
                    ),

                    const SizedBox(height: 14),

                    _field(
                      "Price",
                      priceController,
                      keyboard: TextInputType.number,
                    ),

                    const SizedBox(height: 24),

                    _buttons(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _handleBar() {
    return Center(
      child: Container(
        width: 50,
        height: 5,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _title() {
    return Text(
      isEditing ? "Edit Item" : "Add Item",
      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    TextInputType? keyboard,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        AppTextField(
          controller: controller,
          hintText: label,
          keyboardType: keyboard,
        ),
      ],
    );
  }

  Widget _chip(String text, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.black : Colors.white,
          border: Border.all(color: Colors.black26),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(color: selected ? Colors.white : Colors.black),
        ),
      ),
    );
  }

  Widget _gstField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label("GST %"),
        CompositedTransformTarget(
          link: _gstLink,
          child: GestureDetector(
            onTap: _toggleGstDropdown,
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black26),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(selectedGst),
                  const Icon(Icons.keyboard_arrow_down),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buttons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        cButton(() => Navigator.pop(context), "Cancel", false),
        const SizedBox(width: 10),
        cButton(_saveItem, isEditing ? "Update" : "Save", true),
      ],
    );
  }

  // =====================================================
  // SAVE ITEM
  // =====================================================
  void _saveItem() {
    final name = nameController.text.trim();
    final gstValue = double.tryParse(selectedGst.replaceAll('%', '')) ?? 0;

    final price = priceController.text.trim().isEmpty
        ? null
        : double.tryParse(priceController.text.trim());

    if (name.isEmpty) return;

    final item = Item(
      itemId: widget.item?.itemId ?? IdGenerator.generateItemId(),
      name: name,
      type: selectedType,
      hsnSac: hsnController.text.trim().isEmpty
          ? null
          : hsnController.text.trim(),
      gst: gstValue,
      price: price,

      // If model supports:
      // qtyType: selectedQtyType,
    );

    if (isEditing) {
      Get.find<ItemController>().updateItem(item);
    } else {
      Get.find<ItemController>().addItem(item);
    }

    Navigator.pop(context);
  }
}
