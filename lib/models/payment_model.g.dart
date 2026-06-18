// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PaymentAdapter extends TypeAdapter<Payment> {
  @override
  final int typeId = 7;

  @override
  Payment read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Payment(
      paymentId: fields[0] as String,
      invoiceId: fields[1] as String,
      dateTime: fields[2] as DateTime,
      mode: fields[3] as String,
      amount: fields[4] as double,
      notes: fields[5] as String?,
      updatedAt: fields[6] as DateTime?,
      isDeleted: fields[7] as bool,
      syncStatus: fields[8] as SyncStatus,
    );
  }

  @override
  void write(BinaryWriter writer, Payment obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.paymentId)
      ..writeByte(1)
      ..write(obj.invoiceId)
      ..writeByte(2)
      ..write(obj.dateTime)
      ..writeByte(3)
      ..write(obj.mode)
      ..writeByte(4)
      ..write(obj.amount)
      ..writeByte(5)
      ..write(obj.notes)
      ..writeByte(6)
      ..write(obj.updatedAt)
      ..writeByte(7)
      ..write(obj.isDeleted)
      ..writeByte(8)
      ..write(obj.syncStatus);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
