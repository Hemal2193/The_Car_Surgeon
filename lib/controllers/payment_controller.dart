import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:tcs/database/hive_boxes.dart';

import '../models/payment_model.dart';
import '../models/sync_status.dart';
import 'invoice_controller.dart';

class PaymentController extends GetxController {
  static PaymentController get instance => Get.find();

  Box<Payment> get _box => Hive.box<Payment>(HiveBoxes.payments);

  List<Payment> get allPayments => _box.values
      .where((p) => !(p).isDeleted)
      .cast<Payment>()
      .toList();

  List<Payment> get pendingPayments => allPayments
      .where((p) => p.syncStatus != SyncStatus.synced)
      .toList();

  List<Payment> getPaymentsByInvoiceId(String invoiceId) {
    return allPayments.where((p) => p.invoiceId == invoiceId).toList();
  }

  double getPaidAmountByInvoice(String invoiceId) {
    return getPaymentsByInvoiceId(invoiceId)
        .fold(0, (sum, p) => sum + p.amount);
  }

  Future<void> addPayment(Payment payment) async {
    await _box.put(payment.paymentId, payment);
    Get.find<InvoiceController>().updateInvoicePaymentStatus(payment.invoiceId);
    update();
  }

  Future<void> updatePayment(Payment payment) async {
    await payment.save();
    Get.find<InvoiceController>().updateInvoicePaymentStatus(payment.invoiceId);
    update();
  }

  Future<void> deletePayment(String paymentId) async {
    final payment = _box.get(paymentId);
    if (payment != null) {
      (payment).isDeleted = true;
      await payment.save();
      Get.find<InvoiceController>().updateInvoicePaymentStatus(payment.invoiceId);
      update();
    }
  }

  Payment? getPaymentById(String paymentId) {
    final payment = _box.get(paymentId);
    if (payment != null && !(payment).isDeleted) {
      return payment;
    }
    return null;
  }

  Future<void> upsertFromRemote(Payment payment) async {
    final existing = _box.get(payment.paymentId);
    if (existing == null) {
      await _box.put(payment.paymentId, payment);
    } else {
      existing
        ..invoiceId = payment.invoiceId
        ..dateTime = payment.dateTime
        ..mode = payment.mode
        ..amount = payment.amount
        ..notes = payment.notes
        ..updatedAt = payment.updatedAt
        ..isDeleted = payment.isDeleted
        ..syncStatus = payment.syncStatus
        ..save();
    }
    update();
  }

  void markAsSynced(String paymentId) {
    final payment = _box.get(paymentId);
    if (payment != null) {
      payment
        ..syncStatus = SyncStatus.synced
        ..save();
    }
  }
}