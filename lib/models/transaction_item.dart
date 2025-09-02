import 'package:hive/hive.dart';

@HiveType(typeId: 1)
class TransactionItem {
  @HiveField(0)
  String id;
  @HiveField(1)
  double amount;
  @HiveField(2)
  DateTime date;
  @HiveField(3)
  String category;
  @HiveField(4)
  String? note;
  @HiveField(5)
  bool isIncome;

  TransactionItem({
    required this.id,
    required this.amount,
    required this.date,
    required this.category,
    this.note,
    required this.isIncome,
  });
}

// Manual adapter, no code-gen needed
class TransactionItemAdapter extends TypeAdapter<TransactionItem> {
  @override
  final int typeId = 1;

  @override
  TransactionItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return TransactionItem(
      id: fields[0] as String,
      amount: fields[1] as double,
      date: fields[2] as DateTime,
      category: fields[3] as String,
      note: fields[4] as String?,
      isIncome: fields[5] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, TransactionItem obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.amount)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.category)
      ..writeByte(4)
      ..write(obj.note)
      ..writeByte(5)
      ..write(obj.isIncome);
  }
}
