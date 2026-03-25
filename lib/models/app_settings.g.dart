// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AppSettingsAdapter extends TypeAdapter<AppSettings> {
  @override
  final int typeId = 1;

  @override
  AppSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppSettings(
      pin: fields[0] as String,
      sensitivity: fields[1] as String,
      alarmTone: fields[2] as String,
      vibrationEnabled: fields[3] as bool,
      flashlightEnabled: fields[4] as bool,
      intruderSelfieEnabled: fields[5] as bool,
      activationDelay: fields[6] as int,
      biometricEnabled: fields[7] as bool,
      patternHash: fields[8] as String?,
      wrongPinAttempts: fields[9] as int,
      isFirstLaunch: fields[10] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, AppSettings obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.pin)
      ..writeByte(1)
      ..write(obj.sensitivity)
      ..writeByte(2)
      ..write(obj.alarmTone)
      ..writeByte(3)
      ..write(obj.vibrationEnabled)
      ..writeByte(4)
      ..write(obj.flashlightEnabled)
      ..writeByte(5)
      ..write(obj.intruderSelfieEnabled)
      ..writeByte(6)
      ..write(obj.activationDelay)
      ..writeByte(7)
      ..write(obj.biometricEnabled)
      ..writeByte(8)
      ..write(obj.patternHash)
      ..writeByte(9)
      ..write(obj.wrongPinAttempts)
      ..writeByte(10)
      ..write(obj.isFirstLaunch);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
