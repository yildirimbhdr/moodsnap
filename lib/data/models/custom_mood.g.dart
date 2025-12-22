// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'custom_mood.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CustomMoodAdapter extends TypeAdapter<CustomMood> {
  @override
  final int typeId = 3;

  @override
  CustomMood read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CustomMood(
      id: fields[0] as String,
      name: fields[1] as String,
      emoji: fields[2] as String,
      createdAt: fields[3] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, CustomMood obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.emoji)
      ..writeByte(3)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomMoodAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
