// ===============================
// main.dart (final with CardItem support)
// ===============================
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'models/transaction_item.dart';
import 'models/card_item.dart';
import 'services/hive_service.dart';
import 'dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Init Hive
  await Hive.initFlutter();

  // ✅ Register adapters
  Hive.registerAdapter(TransactionItemAdapter());
  Hive.registerAdapter(CardItemAdapter());

  // ✅ Open boxes
  await Hive.openBox<TransactionItem>("transactionsBox");
  await Hive.openBox("settingsBox");
  await Hive.openBox<CardItem>("cardsBox");

  // ✅ Seed demo data if transactions are empty
  await HiveService.seedIfEmpty();

  runApp(const SpendWiseApp());
}

class SpendWiseApp extends StatelessWidget {
  const SpendWiseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SpendWise',
      home: DashboardScreen(),
    );
  }
}
