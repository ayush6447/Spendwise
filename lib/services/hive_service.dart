import 'package:hive_flutter/hive_flutter.dart';
import '../models/transaction_item.dart';

class HiveService {
  static const String transactionsBox = 'transactionsBox';

  static Future<void> init() async {
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(TransactionItemAdapter());
    }
    await Hive.openBox<TransactionItem>(transactionsBox);
  }

  static Box<TransactionItem> box() => Hive.box<TransactionItem>(transactionsBox);

  static Future<void> seedIfEmpty() async {
    final b = box();
    if (b.isEmpty) {
      final now = DateTime.now();
      await b.putAll({
        'tx1': TransactionItem(id: 'tx1', amount: 50000, date: now.subtract(const Duration(days: 3)), category: 'Income', note: 'Salary', isIncome: true),
        'tx2': TransactionItem(id: 'tx2', amount: 1200.5, date: now.subtract(const Duration(days: 2)), category: 'Food', note: 'Groceries', isIncome: false),
        'tx3': TransactionItem(id: 'tx3', amount: 220, date: now.subtract(const Duration(days: 1)), category: 'Travel', note: 'Cab', isIncome: false),
        'tx4': TransactionItem(id: 'tx4', amount: 1450, date: now.subtract(const Duration(days: 5)), category: 'Bills', note: 'Electricity', isIncome: false),
        'tx5': TransactionItem(id: 'tx5', amount: 799, date: now.subtract(const Duration(days: 6)), category: 'Health', note: 'Gym', isIncome: false),
      });
    }
  }
}
