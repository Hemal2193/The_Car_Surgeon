import 'package:hive/hive.dart';

import 'sync_status.dart';
import 'invoice_payment_status.dart';

part 'invoice_model.g.dart';

@HiveType(typeId: 3)
class Invoice extends HiveObject {
  @HiveField(0)
  String invoiceId;

  @HiveField(1)
  String customerId;

  @HiveField(2)
  String vehicleId;

  @HiveField(3)
  DateTime dateTime;

  @HiveField(4)
  List<InvoiceItem> items;

  @HiveField(5)
  double grandTotal;

  // ==========================
  // SYNC FIELDS
  // ==========================

  @HiveField(6)
  DateTime updatedAt;

  @HiveField(7)
  bool isDeleted;

  @HiveField(8)
  SyncStatus syncStatus;

  /// Advance payment amount (0 if no advance taken)
  @HiveField(9)
  double advanceAmount;

  /// Payment method for the advance (e.g. Cash, UPI, Card, etc.)
  @HiveField(10)
  String paymentMethod;

  @HiveField(11)
  InvoicePaymentStatus paymentStatus;

  @HiveField(12)
  double balanceAmount;

  /// Total item-wise discount already applied before [grandTotal].
  @HiveField(13)
  double discount;

  @HiveField(14)
  DateTime dueDate;

  Invoice({
    required this.invoiceId,
    required this.customerId,
    required this.vehicleId,
    required this.dateTime,
    required this.dueDate,
    required this.items,
    required this.grandTotal,

    DateTime? updatedAt,
    this.isDeleted = false,
    this.syncStatus = SyncStatus.pending,
    this.advanceAmount = 0,
    this.paymentMethod = 'Cash',
    this.paymentStatus = InvoicePaymentStatus.unpaid,
    double? balanceAmount,
    double? discount,
  }) : discount = discount ?? 0,
       balanceAmount =
           balanceAmount ??
           calculateBalance(
             grandTotal: grandTotal,
             advanceAmount: advanceAmount,
             discount: discount ?? 0.0,
           ),
       updatedAt = updatedAt ?? DateTime.now();

  static double calculateItemsDiscount(List<InvoiceItem> items) {
    return items.fold<double>(0, (sum, item) => sum + item.discountAmount);
  }

  static double calculateBalance({
    required double grandTotal,
    required double advanceAmount,
    required double discount,
    double collectedAmount = 0,
  }) {
    return grandTotal - advanceAmount - discount - collectedAmount;
  }

  double get subtotalBeforeDiscount {
    return items.fold<double>(0, (sum, item) => sum + item.grossAmount);
  }

  double get taxableAmount {
    return items.fold<double>(0, (sum, item) => sum + item.taxableAmount);
  }

  double get taxAmount {
    return items.fold<double>(0, (sum, item) => sum + item.taxAmount);
  }

  void recalculateFinancials({double collectedAmount = 0}) {
    // discount = calculateItemsDiscount(items);
    grandTotal = items.fold<double>(0, (sum, item) => sum + item.totalAmount);
    balanceAmount = calculateBalance(
      grandTotal: grandTotal,
      advanceAmount: advanceAmount,
      collectedAmount: collectedAmount,
      discount: discount,
    );
  }
}

@HiveType(typeId: 4)
class InvoiceItem {
  @HiveField(0)
  String itemId;

  @HiveField(1)
  String name;

  @HiveField(2)
  String? hsnSac;

  @HiveField(3)
  int qty;

  @HiveField(4)
  double rate;

  @HiveField(5)
  double taxPercent;

  @HiveField(6)
  double taxAmount;

  @HiveField(7)
  double totalAmount;

  @HiveField(8)
  String type;

  /// Discount amount (in currency or percentage depending on [discountIsPercent])
  @HiveField(9)
  double discount;

  /// true = discount is a percentage, false = discount is a fixed amount
  @HiveField(10)
  bool discountIsPercent;

  InvoiceItem({
    required this.itemId,
    required this.name,
    required this.hsnSac,
    required this.qty,
    required this.rate,
    required this.taxPercent,
    required this.taxAmount,
    required this.totalAmount,
    required this.type,
    this.discount = 0,
    this.discountIsPercent = false,
  });

  double get grossAmount => qty * rate;

  double get discountAmount {
    if (discountIsPercent) {
      return grossAmount * discount / 100;
    }
    return discount;
  }

  double get taxableAmount => grossAmount - discountAmount;
}
