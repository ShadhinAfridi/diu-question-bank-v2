// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'slider_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SliderItemAdapter extends TypeAdapter<SliderItem> {
  @override
  final int typeId = 5;

  @override
  SliderItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SliderItem(
      id: fields[0] as String,
      imageUrl: fields[1] as String,
      order: fields[2] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, SliderItem obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.imageUrl)
      ..writeByte(2)
      ..write(obj.order);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SliderItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
