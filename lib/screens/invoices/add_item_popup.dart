import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tcs/models/item_model.dart';
import 'package:tcs/screens/items/add_item_dialog.dart';
import 'package:tcs/utils/responsive.dart';
import 'package:tcs/widgets/app_selector.dart';
import 'package:tcs/widgets/app_text_field.dart';
import '../../controllers/item_controller.dart';

/// Popup dialog/bottom-sheet for adding or editing an invoice item.
/// - Desktop: shown as Dialog
/// - Mobile: shown as BottomSheet
///
/// [initialData] can contain: item, qty, rate, taxPercent, taxAmount, discount, discountIsPercent
/// If provided, the popup opens in edit mode with those values pre-filled.
class AddItemPopup extends StatefulWidget {
  final Map<String, dynamic>? initialData;

  const AddItemPopup({super.key, this.initialData});

  /// Show as dialog on desktop, or as a bottom sheet on mobile.
  /// Returns a Map with keys: item, qty, rate, taxPercent, taxAmount, discount, discountIsPercent
  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    Map<String, dynamic>? initialData,
  }) {
    if (Responsive.isDesktop(context)) {
      return showDialog<Map<String, dynamic>>(
        context: context,
        builder: (_) => AddItemPopup(initialData: initialData),
      );
    } else {
      return showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          minChildSize: 0.50,
          maxChildSize: 0.92,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: AddItemPopup(initialData: initialData),
                ),
              ),
            );
          },
        ),
      );
    }
  }

  @override
  State<AddItemPopup> createState() => _AddItemPopupState();
}

class _AddItemPopupState extends State<AddItemPopup> {
  Item? _selectedItem;
  int _qty = 1;
  double _rate = 0;
  double _discount = 0;
  bool _discountIsPercent = true;
  double _taxPercent = 0;

  final TextEditingController _qtyController = TextEditingController(text: "1");
  final TextEditingController _rateController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _taxController = TextEditingController();

  bool get _isEditing => widget.initialData != null;

  @override
  void initState() {
    super.initState();
    final data = widget.initialData;
    if (data != null) {
      _selectedItem = data['item'] as Item;
      _qty = data['qty'] as int;
      _rate = (data['rate'] as num).toDouble();
      _taxPercent = (data['taxPercent'] as num).toDouble();
      _discount = (data['discount'] as num).toDouble();
      _discountIsPercent = data['discountIsPercent'] as bool;

      _qtyController.text = _qty.toString();
      _rateController.text = _rate.toStringAsFixed(2);
      _taxController.text = _taxPercent.toStringAsFixed(1);
      _discountController.text = _discount.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _rateController.dispose();
    _discountController.dispose();
    _taxController.dispose();
    super.dispose();
  }

  double get _baseAmount => _qty * _rate;

  double get _discountAmount {
    if (_discountIsPercent) {
      return _baseAmount * _discount / 100;
    }
    return _discount;
  }

  double get _taxableValue => _baseAmount - _discountAmount;

  double get _taxAmount => _taxableValue * _taxPercent / 100;

  double get _totalAmount => _taxableValue + _taxAmount;

  void _onItemSelected(Item? i) {
    setState(() {
      _selectedItem = i;
      if (i != null) {
        _rate = (i.price ?? 0).toDouble();
        _rateController.text = _rate.toStringAsFixed(2);
        _taxPercent = i.gst;
        _taxController.text = _taxPercent.toStringAsFixed(1);
      }
    });
  }

  void _toggleDiscountMode() {
    setState(() {
      if (_discountIsPercent) {
        final currentAmount = _baseAmount * _discount / 100;
        _discount = currentAmount;
        _discountIsPercent = false;
      } else {
        final currentPercent = _baseAmount > 0
            ? (_discount / _baseAmount) * 100
            : 0.0;
        _discount = currentPercent;
        _discountIsPercent = true;
      }
      _discountController.text = _discount.toStringAsFixed(2);
    });
  }

  Map<String, dynamic>? _buildResult() {
    if (_selectedItem == null || _qty <= 0 || _rate < 0) return null;

    return {
      'item': _selectedItem!,
      'qty': _qty,
      'rate': _rate,
      'taxPercent': _taxPercent,
      'taxAmount': _taxAmount,
      'discount': _discount,
      'discountIsPercent': _discountIsPercent,
    };
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    final content = _buildContent(context, isDesktop);

    if (isDesktop) {
      return Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
        child: Container(
          width: 500,
          constraints: const BoxConstraints(maxHeight: 700),
          padding: const EdgeInsets.all(24),
          child: content,
        ),
      );
    }

    return content;
  }

  Widget _buildContent(BuildContext context, bool isDesktop) {
    final crossAxis = isDesktop
        ? CrossAxisAlignment.start
        : CrossAxisAlignment.stretch;

    return ScrollConfiguration(
      behavior: const ScrollBehavior().copyWith(scrollbars: false),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: crossAxis,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ---------- HEADER ----------
            if (isDesktop)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isEditing ? "Edit Item" : "Add Item",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _isEditing ? "Edit Item" : "Add Item",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: isDesktop ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ---------- ITEM SELECTOR ----------
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Select Item",
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      InkWell(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            isDismissible: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) {
                              return DraggableScrollableSheet(
                                expand: false,
                                initialChildSize: 0.80,
                                minChildSize: 0.80,
                                maxChildSize: 0.92,
                                shouldCloseOnMinExtent: true,
                                builder: (context, scrollController) {
                                  return AddItemDialog(
                                    scrollController: scrollController,
                                  );
                                },
                              );
                            },
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 3,
                            ),
                            child: Text(
                              "Add New Item",
                              style: TextStyle(fontSize: 9),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  AppSelector<Item>(
                    key: ValueKey(
                      'popup_item_${_selectedItem?.itemId ?? 'none'}',
                    ),
                    items: Get.find<ItemController>().items,
                    initialItem: _selectedItem,
                    hintText: 'Select Item',
                    displayText: (i) => i.name,
                    searchText: (i) => i.name,
                    itemBuilder: (i) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(i.name),
                        Text(
                          'Rs. ${i.price ?? 0}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    onSelected: _onItemSelected,
                  ),
                  const SizedBox(height: 16),

                  // ---------- QTY & RATE ROW ----------
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Quantity",
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 8),
                            AppTextField(
                              hintText: "Qty",
                              controller: _qtyController,
                              keyboardType: TextInputType.number,
                              onChanged: (v) {
                                _qty = int.tryParse(v) ?? 1;
                                setState(() {});
                              },
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
                              "Rate",
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 8),
                            AppTextField(
                              hintText: "Rate",
                              controller: _rateController,
                              keyboardType: TextInputType.number,
                              onChanged: (v) {
                                _rate = double.tryParse(v) ?? 0;
                                setState(() {});
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ---------- DISCOUNT FIELD ----------
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _discountIsPercent
                                  ? "Discount (%)"
                                  : "Discount (₹)",
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            AppTextField(
                              hintText: _discountIsPercent
                                  ? "Discount %"
                                  : "Discount ₹",
                              controller: _discountController,
                              keyboardType: TextInputType.number,
                              suffixText: _discountIsPercent ? "%" : "₹",
                              onChanged: (v) {
                                _discount = double.tryParse(v) ?? 0;
                                setState(() {});
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Mode",
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 40,
                            child: ToggleButtons(
                              isSelected: [
                                _discountIsPercent,
                                !_discountIsPercent,
                              ],
                              onPressed: (index) {
                                if (index == 0 && !_discountIsPercent) {
                                  _toggleDiscountMode();
                                } else if (index == 1 && _discountIsPercent) {
                                  _toggleDiscountMode();
                                }
                              },
                              borderRadius: BorderRadius.circular(8),
                              selectedColor: Colors.white,
                              fillColor: Colors.black,
                              constraints: const BoxConstraints(
                                minWidth: 40,
                                minHeight: 40,
                              ),
                              textStyle: const TextStyle(fontSize: 13),
                              children: const [Text("%"), Text("₹")],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ---------- TAX RATE ----------
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Tax Rate (%)",
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      AppTextField(
                        hintText: "Tax %",
                        controller: _taxController,
                        keyboardType: TextInputType.number,
                        suffixText: "%",
                        onChanged: (v) {
                          _taxPercent = double.tryParse(v) ?? 0;
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ---------- DETAILS SUMMARY ----------
                  if (_selectedItem != null && _qty > 0 && _rate > 0) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey.shade50,
                      ),
                      child: Column(
                        children: [
                          _detailRow(
                            "Exclusive Price × Qty",
                            "$_qty × ${_rate.toStringAsFixed(2)} = ${_baseAmount.toStringAsFixed(2)}",
                          ),
                          const Divider(height: 12),
                          _detailRow(
                            "Discount",
                            _discountIsPercent
                                ? "${_discount.toStringAsFixed(1)}% (-${_discountAmount.toStringAsFixed(2)})"
                                : "-${_discountAmount.toStringAsFixed(2)}",
                          ),
                          const Divider(height: 12),
                          _detailRow(
                            "Taxable Value",
                            _taxableValue.toStringAsFixed(2),
                          ),
                          const Divider(height: 12),
                          _detailRow(
                            "Tax Rate (${_taxPercent.toStringAsFixed(1)}%)",
                            _taxAmount.toStringAsFixed(2),
                          ),
                          const Divider(height: 12),
                          _detailRow(
                            "Total Amount",
                            _totalAmount.toStringAsFixed(2),
                            bold: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ---------- ADD / UPDATE BUTTON ----------
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        final result = _buildResult();
                        if (result == null) return;
                        Navigator.of(context).pop(result);
                      },
                      child: Text(
                        _isEditing ? "Update" : "Add",
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  SizedBox(height: isDesktop ? 0 : 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: bold ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
