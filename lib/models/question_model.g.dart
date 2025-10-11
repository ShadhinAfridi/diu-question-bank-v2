// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'question_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class QuestionAdapter extends TypeAdapter<Question> {
  @override
  final int typeId = 4;

  @override
  Question read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Question(
      id: fields[0] as String,
      courseCode: fields[1] as String,
      courseName: fields[2] as String,
      department: fields[3] as String,
      examType: fields[4] as String,
      examYear: fields[5] as String,
      pdfUrl: fields[6] as String,
      semester: fields[7] as String,
      processedAt: fields[8] as Timestamp,
    );
  }

  @override
  void write(BinaryWriter writer, Question obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.courseCode)
      ..writeByte(2)
      ..write(obj.courseName)
      ..writeByte(3)
      ..write(obj.department)
      ..writeByte(4)
      ..write(obj.examType)
      ..writeByte(5)
      ..write(obj.examYear)
      ..writeByte(6)
      ..write(obj.pdfUrl)
      ..writeByte(7)
      ..write(obj.semester)
      ..writeByte(8)
      ..write(obj.processedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuestionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
