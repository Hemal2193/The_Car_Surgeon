// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vehicle_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class VehicleAdapter extends TypeAdapter<Vehicle> {
  @override
  final int typeId = 1;

  @override
  Vehicle read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Vehicle(
      vehicleId: fields[0] as String,
      customerId: fields[1] as String,
      registrationNumber: fields[2] as String,
      make: fields[3] as String,
      model: fields[4] as String,
      vehicleColor: fields[5] as String?,
      fuelType: fields[6] as String,
      chassisNumber: fields[7] as String?,
      engineNumber: fields[8] as String?,
      odoMeter: fields[9] as String?,
      updatedAt: fields[10] as DateTime?,
      isDeleted: fields[11] as bool,
      syncStatus: fields[12] as SyncStatus,
    );
  }

  @override
  void write(BinaryWriter writer, Vehicle obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.vehicleId)
      ..writeByte(1)
      ..write(obj.customerId)
      ..writeByte(2)
      ..write(obj.registrationNumber)
      ..writeByte(3)
      ..write(obj.make)
      ..writeByte(4)
      ..write(obj.model)
      ..writeByte(5)
      ..write(obj.vehicleColor)
      ..writeByte(6)
      ..write(obj.fuelType)
      ..writeByte(7)
      ..write(obj.chassisNumber)
      ..writeByte(8)
      ..write(obj.engineNumber)
      ..writeByte(9)
      ..write(obj.odoMeter)
      ..writeByte(10)
      ..write(obj.updatedAt)
      ..writeByte(11)
      ..write(obj.isDeleted)
      ..writeByte(12)
      ..write(obj.syncStatus);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VehicleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
