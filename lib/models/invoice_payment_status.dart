import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'invoice_payment_status.g.dart';

@HiveType(typeId: 8)
enum InvoicePaymentStatus {
  @HiveField(0)
  unpaid,

  @HiveField(1)
  partiallyPaid,

  @HiveField(2)
  paid,
}

extension InvoicePaymentStatusExtension on InvoicePaymentStatus {
  String get label {
    switch (this) {
      case InvoicePaymentStatus.unpaid:
        return 'Unpaid';
      case InvoicePaymentStatus.partiallyPaid:
        return 'Partial';
      case InvoicePaymentStatus.paid:
        return 'Paid';
    }
  }

  Color get color {
    switch (this) {
      case InvoicePaymentStatus.unpaid:
        return Colors.red;
      case InvoicePaymentStatus.partiallyPaid:
        return Colors.orange;
      case InvoicePaymentStatus.paid:
        return Colors.green;
    }
  }
}
