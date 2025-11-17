// timestamp_adapter.dart - Unchanged
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
// --- FIX: Standardized import path ---
import 'package:diuquestionbank/constants/hive_type_ids.dart';

class TimestampAdapter extends TypeAdapter<Timestamp> {
  @override
  final int typeId = kTimestampAdapterId; // Use constant

  @override
  Timestamp read(BinaryReader reader) {
    final int seconds = reader.readInt();
    final int nanoseconds = reader.readInt();
    return Timestamp(seconds, nanoseconds);
  }

  @override
  void write(BinaryWriter writer, Timestamp obj) {
    writer.writeInt(obj.seconds);
    writer.writeInt(obj.nanoseconds);
  }
}