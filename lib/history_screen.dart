// ===============================
// history_screen.dart (final with Note-aware design)
// ===============================
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'utils/format.dart';
import 'services/hive_service.dart';
import 'models/transaction_item.dart';
import 'dashboard_screen.dart';
import 'reports_screen.dart';
import 'profile_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  static const kBg = Color(0xFF121212);
  static const kText = Colors.white;
  static const kCyan = Color(0xFF00E5FF);

  String? selectedMonth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(
        scaffoldBackgroundColor: kBg,
        appBarTheme: const AppBarTheme(backgroundColor: kBg, foregroundColor: kText, elevation: 0),
        textTheme: GoogleFonts.poppinsTextTheme(theme.textTheme.apply(bodyColor: kText, displayColor: kText)),
        cardColor: const Color(0xFF1E1E1E),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('History'),
          actions: [
            ValueListenableBuilder(
              valueListenable: HiveService.box().listenable(),
              builder: (context, Box<TransactionItem> box, _) {
                final items = box.values.toList();
                if (items.isEmpty) return const SizedBox();

                // Collect unique months
                final months = items
                    .map((tx) => DateFormat('MMMM yyyy').format(tx.date))
                    .toSet()
                    .toList()
                  ..sort((a, b) => DateFormat('MMMM yyyy')
                      .parse(b)
                      .compareTo(DateFormat('MMMM yyyy').parse(a)));

                // Insert "All Months" at the top
                months.insert(0, "All Months");

                selectedMonth ??= DateFormat('MMMM yyyy').format(DateTime.now());
                if (!months.contains(selectedMonth)) {
                  selectedMonth = "All Months";
                }

                return DropdownButton<String>(
                  value: selectedMonth,
                  dropdownColor: const Color(0xFF1E1E1E),
                  style: GoogleFonts.poppins(color: Colors.white),
                  underline: const SizedBox(),
                  items: months
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (val) => setState(() => selectedMonth = val),
                );
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: ValueListenableBuilder(
          valueListenable: HiveService.box().listenable(),
          builder: (context, Box<TransactionItem> box, _) {
            final items = box.values.toList()..sort((a, b) => b.date.compareTo(a.date));

            if (items.isEmpty) {
              return const Center(child: Text('No transactions yet'));
            }

            // Filter based on selectedMonth
            final filtered = selectedMonth == null || selectedMonth == "All Months"
                ? items
                : items
                .where((tx) => DateFormat('MMMM yyyy').format(tx.date) == selectedMonth)
                .toList();

            if (filtered.isEmpty) {
              return Center(
                child: Text("No transactions for $selectedMonth",
                    style: GoogleFonts.poppins(color: Colors.grey)),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final tx = filtered[i];
                final isIncome = tx.isIncome;
                return Dismissible(
                  key: Key(tx.id),
                  background: Container(
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 20),
                    child: const Icon(Icons.delete, color: Colors.redAccent),
                  ),
                  secondaryBackground: Container(
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.redAccent),
                  ),
                  onDismissed: (_) => box.delete(tx.id),
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isIncome ? Colors.greenAccent : Colors.redAccent,
                        child: Icon(
                          isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                          color: Colors.black,
                        ),
                      ),
                      // 👇 Title = Note if exists, else Category
                      title: Text(
                        tx.note?.isNotEmpty == true ? tx.note! : tx.category,
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                      // 👇 Subtitle = Category + Date
                      subtitle: Text(
                        "${tx.category} • ${DateFormat('dd MMM yyyy').format(tx.date)}",
                        style: GoogleFonts.poppins(color: Colors.grey, fontSize: 13),
                      ),
                      trailing: Text(
                        (isIncome ? '+' : '-') + kRupees.format(tx.amount),
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          color: isIncome ? Colors.greenAccent : Colors.redAccent,
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: const Color(0xFF1A1A1A),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: kCyan,
          unselectedItemColor: Colors.grey,
          currentIndex: 1,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
            BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded), label: 'Reports'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
          onTap: (i) {
            if (i == 0) {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardScreen()));
            } else if (i == 2) {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ReportsScreen()));
            } else if (i == 3) {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
            }
          },
        ),
      ),
    );
  }
}
