// lib/models/item.dart
import 'package:hive/hive.dart';

part 'item.g.dart';

@HiveType(typeId: 0)
class Item extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String shopId;

  @HiveField(2)
  String name;

  @HiveField(3)
  double price;

  @HiveField(4)
  DateTime purchaseDate;

  @HiveField(5)
  String note;

  @HiveField(6)
  bool isPaid;

  @HiveField(7)
  DateTime? paidDate;

  Item({
    required this.id,
    required this.shopId,
    required this.name,
    required this.price,
    required this.purchaseDate,
    this.note = '',
    this.isPaid = false,
    this.paidDate,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'shopId': shopId,
        'name': name,
        'price': price,
        'purchaseDate': purchaseDate.toIso8601String(),
        'note': note,
        'isPaid': isPaid,
        'paidDate': paidDate?.toIso8601String(),
      };

  factory Item.fromJson(Map<String, dynamic> json) => Item(
        id: json['id'],
        shopId: json['shopId'],
        name: json['name'],
        price: (json['price'] as num).toDouble(),
        purchaseDate: DateTime.parse(json['purchaseDate']),
        note: json['note'] ?? '',
        isPaid: json['isPaid'] ?? false,
        paidDate: json['paidDate'] != null ? DateTime.parse(json['paidDate']) : null,
      );
}