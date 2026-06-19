import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:tcs/controllers/payment_controller.dart';
import 'package:tcs/controllers/reminder_controller.dart';
import 'package:tcs/models/invoice_payment_status.dart';

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
    _refreshInvoicePaymentState(invoice);
    invoice.updatedAt = DateTime.now();
    invoice.isDeleted = false;
    invoice.syncStatus = SyncStatus.pending;

    await invoiceBox.put(invoice.invoiceId, invoice);

    invalidatePdfCache(invoice.invoiceId);
    update();
    Get.find<SupabaseSyncService>().syncInvoices();
  }

  Future<void> updateInvoice(Invoice invoice) async {
    _refreshInvoicePaymentState(invoice);
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
    _refreshInvoicePaymentState(invoice);

    await invoiceBox.put(id, invoice);

    invalidatePdfCache(id);
    update();

    // Also delete attached reminders and payments
    try {
      final reminderController = Get.find<ReminderController>();
      await reminderController.deleteByInvoiceId(id);
    } catch (e) {
      print("Reminder cascade delete error: $e");
    }

    try {
      final paymentController = Get.find<PaymentController>();
      await paymentController.deleteByInvoiceId(id);
    } catch (e) {
      print("Payment cascade delete error: $e");
    }

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

  void updateInvoicePaymentStatus(String invoiceId) {
    final invoice = invoiceBox.get(invoiceId);
    if (invoice == null) return;

    _refreshInvoicePaymentState(invoice);

    // Mark pending so Supabase sync picks up the status change
    invoice.updatedAt = DateTime.now();
    invoice.syncStatus = SyncStatus.pending;

    invoiceBox.put(invoiceId, invoice);
    update();
    Get.find<SupabaseSyncService>().syncInvoices();
  }

  /// CALLED WHEN PULLING DATA FROM SUPABASE
  Future<void> upsertFromRemote(Invoice remoteInvoice) async {
    final local = invoiceBox.get(remoteInvoice.invoiceId);

    if (local == null || remoteInvoice.updatedAt.isAfter(local.updatedAt)) {
      remoteInvoice.syncStatus = SyncStatus.synced;
      _refreshInvoicePaymentState(remoteInvoice);

      await invoiceBox.put(remoteInvoice.invoiceId, remoteInvoice);

      invalidatePdfCache(remoteInvoice.invoiceId);
      update();
    }
  }

  void _refreshInvoicePaymentState(Invoice invoice) {
    final paidAmount = Get.isRegistered<PaymentController>()
        ? Get.find<PaymentController>().getPaidAmountByInvoice(
            invoice.invoiceId,
          )
        : 0.0;
    invoice.recalculateFinancials(collectedAmount: paidAmount);

    if (invoice.advanceAmount + paidAmount <= 0) {
      invoice.paymentStatus = InvoicePaymentStatus.unpaid;
    } else if (invoice.balanceAmount <= 0) {
      invoice.paymentStatus = InvoicePaymentStatus.paid;
    } else {
      invoice.paymentStatus = InvoicePaymentStatus.partiallyPaid;
    }
  }
}
