// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invoice_payment_status.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class InvoicePaymentStatusAdapter extends TypeAdapter<InvoicePaymentStatus> {
  @override
  final int typeId = 8;

  @override
  InvoicePaymentStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return InvoicePaymentStatus.unpaid;
      case 1:
        return InvoicePaymentStatus.partiallyPaid;
      case 2:
        return InvoicePaymentStatus.paid;
      default:
        return InvoicePaymentStatus.unpaid;
    }
  }

  @override
  void write(BinaryWriter writer, InvoicePaymentStatus obj) {
    switch (obj) {
      case InvoicePaymentStatus.unpaid:
        writer.writeByte(0);
        break;
      case InvoicePaymentStatus.partiallyPaid:
        writer.writeByte(1);
        break;
      case InvoicePaymentStatus.paid:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InvoicePaymentStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
