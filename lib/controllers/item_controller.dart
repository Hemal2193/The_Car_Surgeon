import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:tcs/controllers/invoice_controller.dart';

import '../database/hive_boxes.dart';
import '../models/item_model.dart';
import '../models/invoice_model.dart';
import '../models/sync_status.dart';
import '../services/supabase_sync_service.dart';

class ItemController extends GetxController {
  final Box<Item> itemBox = Hive.box<Item>(HiveBoxes.items);

  /// SOURCE OF TRUTH
  List<Item> get items =>
      itemBox.values.where((item) => !item.isDeleted).toList();

  /// ALL ITEMS (INCLUDING DELETED)
  List<Item> get allItems => itemBox.values.toList();

  Item? getItemById(String id) {
    return items.firstWhereOrNull((item) => item.itemId == id);
  }

  /// PENDING UPSERTS FOR SUPABASE

  /// PENDING DELETES FOR SUPABASE

  Future<void> addItem(Item item) async {
    item.updatedAt = DateTime.now();
    item.isDeleted = false;
    item.syncStatus = SyncStatus.pending;

    await itemBox.put(item.itemId, item);

    update();
    Get.find<SupabaseSyncService>().syncItems();

    print("NEW ITEM ID: ${item.itemId}");

    print(itemBox.keys.toList());
    print(itemBox.values.toList());
  }

  Future<void> updateItem(Item item) async {
    item.updatedAt = DateTime.now();
    item.syncStatus = SyncStatus.pending;

    await itemBox.put(item.itemId, item);

    _updateInvoiceItems(item);

    update();
    Get.find<SupabaseSyncService>().syncItems();
  }

  Future<void> deleteItem(String id) async {
    final item = itemBox.get(id);

    if (item == null) return;

    item.updatedAt = DateTime.now();
    item.isDeleted = true;
    item.syncStatus = SyncStatus.pending;

    await itemBox.put(id, item);

    update();
    Get.find<SupabaseSyncService>().syncItems();
  }

  List<Item> get pendingItems => itemBox.values
      .where((item) => item.syncStatus == SyncStatus.pending)
      .toList();

  /// CALLED BY SUPABASE SYNC SERVICE
  Future<void> markAsSynced(String itemId) async {
    final item = itemBox.get(itemId);

    if (item == null) return;

    item.syncStatus = SyncStatus.synced;

    await itemBox.put(itemId, item);

    update();
  }

  /// CALLED BY SUPABASE SYNC SERVICE

  /// CALLED WHEN PULLING DATA FROM SUPABASE
  Future<void> upsertFromRemote(Item remoteItem) async {
    final local = itemBox.get(remoteItem.itemId);

    if (local == null || remoteItem.updatedAt.isAfter(local.updatedAt)) {
      remoteItem.syncStatus = SyncStatus.synced;

      await itemBox.put(remoteItem.itemId, remoteItem);

      update();
    }
  }

  void _updateInvoiceItems(Item item) {
    final invoiceBox = Hive.box<Invoice>(HiveBoxes.invoices);

    bool changed = false;

    for (final invoice in invoiceBox.values) {
      if (invoice.isDeleted) continue;

      bool invoiceChanged = false;

      for (int i = 0; i < invoice.items.length; i++) {
        final invoiceItem = invoice.items[i];

        if (invoiceItem.itemId == item.itemId) {
          final newTaxAmount =
              invoiceItem.qty * invoiceItem.rate * item.gst / 100;

          final newTotalAmount =
              (invoiceItem.qty * invoiceItem.rate) + newTaxAmount;

          invoice.items[i] = InvoiceItem(
            itemId: invoiceItem.itemId,
            name: item.name,
            type: invoiceItem.type,
            hsnSac: item.hsnSac ?? invoiceItem.hsnSac,
            qty: invoiceItem.qty,
            rate: invoiceItem.rate,
            taxPercent: item.gst,
            taxAmount: newTaxAmount,
            totalAmount: newTotalAmount,
          );

          invoiceChanged = true;
        }
      }

      if (invoiceChanged) {
        invoice.grandTotal = invoice.items.fold(
          0,
          (sum, item) => sum + item.totalAmount,
        );

        invoice.updatedAt = DateTime.now();
        invoice.syncStatus = SyncStatus.pending;

        invoiceBox.put(invoice.invoiceId, invoice);

        changed = true;
      }
    }

    if (changed) {
      Get.find<InvoiceController>().update();
      Get.find<SupabaseSyncService>().syncInvoices();
    }
  }
}
