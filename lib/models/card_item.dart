import 'package:hive/hive.dart';
part 'card_item.g.dart';

@HiveType(typeId: 2)
class CardItem {
  @HiveField(0) String id;
  @HiveField(1) String holderName;
  @HiveField(2) String cardNumber;
  @HiveField(3) String expiryDate;
  @HiveField(4) String cvv;
  @HiveField(5) String? bankName;     // added earlier
  @HiveField(6) bool showCvv;         // NEW

  CardItem({
    required this.id,
    required this.holderName,
    required this.cardNumber,
    required this.expiryDate,
    required this.cvv,
    this.bankName,
    this.showCvv = true,
  });
}
