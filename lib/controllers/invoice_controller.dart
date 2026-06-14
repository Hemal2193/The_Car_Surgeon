import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '../database/hive_boxes.dart';
import '../models/invoice_model.dart';
import '../models/sync_status.dart';
import '../services/invoice_pdf_cache.dart';
import '../services/supabase_sync_service.dart';

class InvoiceController extends GetxController {
  final Box<Invoice> invoiceBox = Hive.box<Invoice>(HiveBoxes.invoices);

  /// SOURCE OF TRUTH
  List<Invoice> get invoices =>
      invoiceBox.values.where((invoice) => !invoice.isDeleted).toList();

  /// ALL INVOICES (INCLUDING DELETED)
  List<Invoice> get allInvoices => invoiceBox.values.toList();

  Invoice? getInvoiceById(String id) {
    return invoices.firstWhereOrNull((invoice) => invoice.invoiceId == id);
  }

  /// PENDING RECORDS FOR SUPABASE SYNC
  List<Invoice> get pendingInvoices {
    return invoiceBox.values
        .where((invoice) => invoice.syncStatus == SyncStatus.pending)
        .toList();
  }

  Future<void> addInvoice(Invoice invoice) async {
    invoice.updatedAt = DateTime.now();
    invoice.isDeleted = false;
    invoice.syncStatus = SyncStatus.pending;

    await invoiceBox.put(invoice.invoiceId, invoice);

    invalidatePdfCache(invoice.invoiceId);
    update();
    Get.find<SupabaseSyncService>().syncInvoices();
  }

  Future<void> updateInvoice(Invoice invoice) async {
    invoice.updatedAt = DateTime.now();
    invoice.syncStatus = SyncStatus.pending;

    await invoiceBox.put(invoice.invoiceId, invoice);

    invalidatePdfCache(invoice.invoiceId);
    update();
    Get.find<SupabaseSyncService>().syncInvoices();
  }

  Future<void> deleteInvoice(String id) async {
    final invoice = invoiceBox.get(id);

    if (invoice == null) return;

    invoice.updatedAt = DateTime.now();
    invoice.isDeleted = true;
    invoice.syncStatus = SyncStatus.pending;

    await invoiceBox.put(id, invoice);

    invalidatePdfCache(id);
    update();
    Get.find<SupabaseSyncService>().syncInvoices();
  }

  /// CALLED BY SUPABASE SYNC SERVICE
  Future<void> markAsSynced(String invoiceId) async {
    final invoice = invoiceBox.get(invoiceId);

    if (invoice == null) return;

    invoice.syncStatus = SyncStatus.synced;

    await invoiceBox.put(invoiceId, invoice);

    invalidatePdfCache(invoiceId);
    update();
  }

  /// CALLED WHEN PULLING DATA FROM SUPABASE
  Future<void> upsertFromRemote(Invoice remoteInvoice) async {
    final local = invoiceBox.get(remoteInvoice.invoiceId);

    if (local == null || remoteInvoice.updatedAt.isAfter(local.updatedAt)) {
      remoteInvoice.syncStatus = SyncStatus.synced;

      await invoiceBox.put(remoteInvoice.invoiceId, remoteInvoice);

      invalidatePdfCache(remoteInvoice.invoiceId);
      update();
    }
  }
}
