import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:tcs/controllers/invoice_controller.dart';

import '../database/hive_boxes.dart';
import '../models/item_model.dart';
import '../models/invoice_model.dart';

class ItemController extends GetxController {
  final Box<Item> itemBox = Hive.box<Item>(HiveBoxes.items);

  List<Item> get items => itemBox.values.toList();

  Future<void> addItem(Item item) async {
    await itemBox.put(item.itemId, item);
    update();
  }

  Future<void> updateItem(Item item) async {
    await itemBox.put(item.itemId, item);

    // Update all invoices that reference this item so previews/PDFs reflect changes
    _updateInvoiceItems(item);

    update();
  }

  Future<void> deleteItem(String id) async {
    await itemBox.delete(id);
    update();
  }

  void _updateInvoiceItems(Item item) {
    final invoiceBox = Hive.box<Invoice>(HiveBoxes.invoices);
    bool changed = false;

    for (final invoice in invoiceBox.values) {
      bool invoiceChanged = false;

      for (int i = 0; i < invoice.items.length; i++) {
        final invoiceItem = invoice.items[i];
        if (invoiceItem.itemId == item.itemId) {
          final newTaxAmount = invoiceItem.qty * invoiceItem.rate * item.gst / 100;
          final newTotalAmount = (invoiceItem.qty * invoiceItem.rate) + newTaxAmount;
          invoice.items[i] = InvoiceItem(
            itemId: invoiceItem.itemId,
            name: item.name,
            hsnSac: item.hsnSac ?? invoiceItem.hsnSac,
            qty: invoiceItem.qty,
            rate: invoiceItem.rate,
            taxPercent: item.gst,
            taxAmount: newTaxAmount,
            totalAmount: newTotalAmount,
            type: invoiceItem.type,
          );
          invoiceChanged = true;
        }
      }

      if (invoiceChanged) {
        // Recalculate grand total
        double newGrandTotal = 0;
        for (final invItem in invoice.items) {
          newGrandTotal += invItem.totalAmount;
        }
        invoice.grandTotal = newGrandTotal;

        invoiceBox.put(invoice.invoiceId, invoice);
        changed = true;
      }
    }

    if (changed) {
      Get.find<InvoiceController>().update();
    }
  }
}