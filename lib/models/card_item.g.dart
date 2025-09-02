// GENERATED CODE - DO NOT MODIFY BY HAND
part of 'card_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CardItemAdapter extends TypeAdapter<CardItem> {
  @override
  final int typeId = 2;

  @override
  CardItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CardItem(
      id: fields[0] as String,
      holderName: fields[1] as String,
      cardNumber: fields[2] as String,
      expiryDate: fields[3] as String,
      cvv: fields[4] as String,
      bankName: fields[5] as String?,
      showCvv: fields[6] as bool? ?? true, // ✅ default true if missing
    );
  }

  @override
  void write(BinaryWriter writer, CardItem obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.holderName)
      ..writeByte(2)
      ..write(obj.cardNumber)
      ..writeByte(3)
      ..write(obj.expiryDate)
      ..writeByte(4)
      ..write(obj.cvv)
      ..writeByte(5)
      ..write(obj.bankName)
      ..writeByte(6)
      ..write(obj.showCvv);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is CardItemAdapter &&
              runtimeType == other.runtimeType &&
              typeId == other.typeId;
}
