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
      items: (fields[4] as List).cast<InvoiceItem>(),
      grandTotal: fields[5] as double,
    );
  }

  @override
  void write(BinaryWriter writer, Invoice obj) {
    writer
      ..writeByte(6)
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
      ..write(obj.grandTotal);
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
    );
  }

  @override
  void write(BinaryWriter writer, InvoiceItem obj) {
    writer
      ..writeByte(9)
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
      ..write(obj.type);
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
