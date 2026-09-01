// lib/models/shop.dart

import 'package:hive/hive.dart';

part 'shop.g.dart';

@HiveType(typeId: 1)
class Shop extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String ownerName;

  @HiveField(3)
  String phone;

  @HiveField(4)
  String address;

  @HiveField(5)
  String notes;

  @HiveField(6)
  DateTime createdAt;

  // NEW: Local path of the shop photo
  @HiveField(7)
  String photoPath;

  Shop({
    required this.id,
    required this.name,
    this.ownerName = '',
    this.phone = '',
    this.address = '',
    this.notes = '',
    required this.createdAt,
    this.photoPath = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'ownerName': ownerName,
        'phone': phone,
        'address': address,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
        'photoPath': photoPath,
      };

  factory Shop.fromJson(Map<String, dynamic> json) => Shop(
        id: json['id'],
        name: json['name'],
        ownerName: json['ownerName'] ?? '',
        phone: json['phone'] ?? '',
        address: json['address'] ?? '',
        notes: json['notes'] ?? '',
        createdAt: DateTime.parse(json['createdAt']),
        photoPath: json['photoPath'] ?? '',
      );
}