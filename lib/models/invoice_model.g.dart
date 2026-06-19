// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invoice_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class InvoiceAdapter extends TypeAdapter<Invoice> {
  @override
  final int typeId = 3;

  @override
  Invoice read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Invoice(
      invoiceId: fields[0] as String,
      customerId: fields[1] as String,
      vehicleId: fields[2] as String,
      dateTime: fields[3] as DateTime,
      dueDate: fields[14] as DateTime,
      items: (fields[4] as List).cast<InvoiceItem>(),
      grandTotal: fields[5] as double,
      updatedAt: fields[6] as DateTime?,
      isDeleted: fields[7] as bool,
      syncStatus: fields[8] as SyncStatus,
      advanceAmount: fields[9] as double,
      paymentMethod: fields[10] as String,
      paymentStatus: fields[11] as InvoicePaymentStatus,
      balanceAmount: fields[12] as double?,
      discount: fields[13] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, Invoice obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.invoiceId)
      ..writeByte(1)
      ..write(obj.customerId)
      ..writeByte(2)
      ..write(obj.vehicleId)
      ..writeByte(3)
      ..write(obj.dateTime)
      ..writeByte(4)
      ..write(obj.items)
      ..writeByte(5)
      ..write(obj.grandTotal)
      ..writeByte(6)
      ..write(obj.updatedAt)
      ..writeByte(7)
      ..write(obj.isDeleted)
      ..writeByte(8)
      ..write(obj.syncStatus)
      ..writeByte(9)
      ..write(obj.advanceAmount)
      ..writeByte(10)
      ..write(obj.paymentMethod)
      ..writeByte(11)
      ..write(obj.paymentStatus)
      ..writeByte(12)
      ..write(obj.balanceAmount)
      ..writeByte(13)
      ..write(obj.discount)
      ..writeByte(14)
      ..write(obj.dueDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InvoiceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class InvoiceItemAdapter extends TypeAdapter<InvoiceItem> {
  @override
  final int typeId = 4;

  @override
  InvoiceItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return InvoiceItem(
      itemId: fields[0] as String,
      name: fields[1] as String,
      hsnSac: fields[2] as String?,
      qty: fields[3] as int,
      rate: fields[4] as double,
      taxPercent: fields[5] as double,
      taxAmount: fields[6] as double,
      totalAmount: fields[7] as double,
      type: fields[8] as String,
      discount: fields[9] as double,
      discountIsPercent: fields[10] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, InvoiceItem obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.itemId)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.hsnSac)
      ..writeByte(3)
      ..write(obj.qty)
      ..writeByte(4)
      ..write(obj.rate)
      ..writeByte(5)
      ..write(obj.taxPercent)
      ..writeByte(6)
      ..write(obj.taxAmount)
      ..writeByte(7)
      ..write(obj.totalAmount)
      ..writeByte(8)
      ..write(obj.type)
      ..writeByte(9)
      ..write(obj.discount)
      ..writeByte(10)
      ..write(obj.discountIsPercent);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InvoiceItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
