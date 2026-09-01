
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shop.dart';

// ***************************************************************************
// TypeAdapterGenerator
// ***************************************************************************

class ShopAdapter extends TypeAdapter<Shop> {
  @override
  final int typeId = 1;

  @override
  Shop read(BinaryReader reader) {
    final numOfFields = reader.readByte();

    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++)
        reader.readByte(): reader.read(),
    };

    return Shop(
      id: fields[0] as String,
      name: fields[1] as String,
      ownerName: fields[2] as String? ?? '',
      phone: fields[3] as String? ?? '',
      address: fields[4] as String? ?? '',
      notes: fields[5] as String? ?? '',
      createdAt: fields[6] as DateTime,
      
      // Compatible with old Hive data.
      // Old shops don't have field 7, so use empty string.
      photoPath: fields[7] as String? ?? '',
    );
  }

  @override
  void write(BinaryWriter writer, Shop obj) {
    writer
      ..writeByte(8)

      // Field 0
      ..writeByte(0)
      ..write(obj.id)

      // Field 1
      ..writeByte(1)
      ..write(obj.name)

      // Field 2
      ..writeByte(2)
      ..write(obj.ownerName)

      // Field 3
      ..writeByte(3)
      ..write(obj.phone)

      // Field 4
      ..writeByte(4)
      ..write(obj.address)

      // Field 5
      ..writeByte(5)
      ..write(obj.notes)

      // Field 6
      ..writeByte(6)
      ..write(obj.createdAt)

      // Field 7 - Shop Photo
      ..writeByte(7)
      ..write(obj.photoPath);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShopAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
