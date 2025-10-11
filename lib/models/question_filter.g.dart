// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'question_filter.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class QuestionFilterAdapter extends TypeAdapter<QuestionFilter> {
  @override
  final int typeId = 3;

  @override
  QuestionFilter read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return QuestionFilter.midterm;
      case 1:
        return QuestionFilter.finalExam;
      default:
        return QuestionFilter.midterm;
    }
  }

  @override
  void write(BinaryWriter writer, QuestionFilter obj) {
    switch (obj) {
      case QuestionFilter.midterm:
        writer.writeByte(0);
        break;
      case QuestionFilter.finalExam:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuestionFilterAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
