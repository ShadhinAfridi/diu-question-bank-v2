// slider_model.dart
import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'slider_model.g.dart';

@HiveType(typeId: 5)
class SliderItem {
  @HiveField(0)
  String id;

  @HiveField(1)
  final String imageUrl;

  @HiveField(2)
  final int? order;

  SliderItem({
    required this.id,
    required this.imageUrl,
    this.order,
  });

  factory SliderItem.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return SliderItem(
      id: doc.id,
      imageUrl: data['imageUrl'] ?? '',
      order: data['order']?.toInt(),
    );
  }

  factory SliderItem.fromJson(Map<String, dynamic> json) => SliderItem(
    id: json['id'],
    imageUrl: json['imageUrl'],
    order: json['order'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'imageUrl': imageUrl,
    'order': order,
  };
}
