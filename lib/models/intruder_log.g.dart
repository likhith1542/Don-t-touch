// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'intruder_log.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class IntruderLogAdapter extends TypeAdapter<IntruderLog> {
  @override
  final int typeId = 0;

  @override
  IntruderLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return IntruderLog(
      id: fields[0] as String,
      timestamp: fields[1] as DateTime,
      photoPath: fields[2] as String?,
      triggerType: fields[3] as String,
      accelerometerMagnitude: fields[4] as double?,
      wasDisarmed: fields[5] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, IntruderLog obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.timestamp)
      ..writeByte(2)
      ..write(obj.photoPath)
      ..writeByte(3)
      ..write(obj.triggerType)
      ..writeByte(4)
      ..write(obj.accelerometerMagnitude)
      ..writeByte(5)
      ..write(obj.wasDisarmed);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IntruderLogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
