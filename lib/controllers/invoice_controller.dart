import 'dart:convert';

import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:tcs/controllers/payment_controller.dart';
import 'package:tcs/controllers/reminder_controller.dart';
import 'package:tcs/models/invoice_payment_status.dart';
import 'package:tcs/utils/billing_document_type.dart';

import '../database/hive_boxes.dart';
import '../database/id_generator.dart';
import '../models/invoice_model.dart';
import '../models/sync_status.dart';
import '../services/invoice_pdf_cache.dart';
import '../services/supabase_sync_service.dart';

class InvoiceController extends GetxController {
  final Box<Invoice> invoiceBox = Hive.box<Invoice>(HiveBoxes.invoices);

  /// Storage key for tracking which quotations have been converted to invoices.
  static const String _convertedQuotationsKey = 'converted_quotations';

  /// Returns the set of quotation IDs that have been converted to invoices.
  Set<String> get convertedQuotationIds {
    final settingsBox = Hive.box(HiveBoxes.settings);
    final raw = settingsBox.get(_convertedQuotationsKey, defaultValue: '[]');
    try {
      final list = jsonDecode(raw) as List;
      return list.cast<String>().toSet();
    } catch (_) {
      return {};
    }
  }

  /// Marks a quotation as having been converted at least once.
  void _markQuotationConverted(String quotationId) {
    final settingsBox = Hive.box(HiveBoxes.settings);
    final ids = convertedQuotationIds;
    ids.add(quotationId);
    settingsBox.put(_convertedQuotationsKey, jsonEncode(ids.toList()));
  }

  /// Checks if the quotation has already been converted at least once.
  bool hasQuotationBeenConverted(String quotationId) {
    return convertedQuotationIds.contains(quotationId);
  }

  /// Tracks which billing tab is selected on mobile (true = quotations tab).
  /// Used by HomePage's FAB to create the correct document type.
  final RxBool isQuotationTabSelected = false.obs;

  /// SOURCE OF TRUTH – all non-deleted billing documents
  List<Invoice> get invoices =>
      invoiceBox.values.where((invoice) => !invoice.isDeleted).toList();

  /// Only real invoices (INV- prefix)
  List<Invoice> get onlyInvoices => invoices
      .where((inv) => BillingDocumentType.isInvoice(inv.invoiceId))
      .toList();

  /// Only quotations (QUO- prefix)
  List<Invoice> get onlyQuotations => invoices
      .where((inv) => BillingDocumentType.isQuotation(inv.invoiceId))
      .toList();

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

  /// Converts a quotation into a real invoice.
  /// Returns the newly created invoice ID, or null if the document is not a quotation.
  Future<String?> convertQuotationToInvoice(String quotationId) async {
    final quotation = invoiceBox.get(quotationId);
    if (quotation == null) return null;
    if (!BillingDocumentType.isQuotation(quotationId)) return null;

    final newInvoiceId = IdGenerator.generateInvoiceId();
    final newInvoice = Invoice(
      invoiceId: newInvoiceId,
      customerId: quotation.customerId,
      vehicleId: quotation.vehicleId,
      dateTime: DateTime.now(),
      dueDate: quotation.dueDate,
      items: quotation.items.map((item) {
        return InvoiceItem(
          itemId: item.itemId,
          name: item.name,
          hsnSac: item.hsnSac,
          qty: item.qty,
          rate: item.rate,
          taxPercent: item.taxPercent,
          taxAmount: item.taxAmount,
          totalAmount: item.totalAmount,
          type: item.type,
          discount: item.discount,
          discountIsPercent: item.discountIsPercent,
        );
      }).toList(),
      grandTotal: quotation.grandTotal,
      discount: quotation.discount,
      advanceAmount: quotation.advanceAmount,
      paymentMethod: quotation.paymentMethod,
    );

    await addInvoice(newInvoice);
    _markQuotationConverted(quotationId);
    return newInvoiceId;
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
