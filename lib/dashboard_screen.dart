// ===============================
// dashboard_screen.dart (final)
// ===============================
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'utils/format.dart';
import 'services/hive_service.dart';
import 'models/transaction_item.dart';
import 'add_transaction_screen.dart';
import 'history_screen.dart';
import 'reports_screen.dart';
import 'profile_screen.dart';
import 'cards_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  static const Color kBg = Color(0xFF121212);
  static const Color kText = Colors.white;
  static const Color kHint = Colors.grey;
  static const Color kCyan = Color(0xFF00E5FF);
  static const Color kGreen = Color(0xFF4CAF50);
  static const Color kRed = Color(0xFFE53935);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = GoogleFonts.poppinsTextTheme(theme.textTheme.apply(
      bodyColor: kText,
      displayColor: kText,
    ));

    return Theme(
      data: theme.copyWith(
        scaffoldBackgroundColor: kBg,
        textTheme: textTheme,
        iconTheme: const IconThemeData(color: kText),
        appBarTheme: const AppBarTheme(
          backgroundColor: kBg,
          foregroundColor: kText,
          elevation: 0,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: kCyan,
          foregroundColor: Colors.black,
          elevation: 6,
          shape: CircleBorder(),
        ),
        cardColor: const Color(0xFF1E1E1E),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'SpendWise',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: kText,
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.credit_card), // 👈 card menu icon
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CardsScreen()),
                );
              },
            )
          ],
        ),
        body: ValueListenableBuilder(
          valueListenable: HiveService.box().listenable(),
          builder: (context, Box<TransactionItem> box, _) {
            final items = box.values.toList()..sort((a, b) => b.date.compareTo(a.date));
            final now = DateTime.now();

            // ✅ Get starting balance from settingsBox
            final settings = Hive.box("settingsBox");
            final startBalance = settings.get("startBalance", defaultValue: 0.0) as double;

            final monthIncome = _sumForMonth(items, now, income: true);
            final monthExpense = _sumForMonth(items, now, income: false);

            final prevMonth = DateTime(now.year, now.month - 1, 1);
            final prevIncome = _sumForMonth(items, prevMonth, income: true);
            final prevExpense = _sumForMonth(items, prevMonth, income: false);

            final incomeDelta = _pct(prevIncome, monthIncome);
            final expenseDelta = _pct(prevExpense, monthExpense);

            final weekBars = _weeklyExpenses(items);
            final categoryMap = _categorySumsForMonth(items, now);

            // ✅ Total balance = Start Balance + This Month’s Income − This Month’s Expenses
            final totalBalance = startBalance + monthIncome - monthExpense;

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text('Total Balance', style: textTheme.titleMedium?.copyWith(color: kHint)),
                  const SizedBox(height: 8),
                  Text(
                    kRupees.format(totalBalance),
                    style: GoogleFonts.poppins(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: kText,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Starting Balance: ${kRupees.format(startBalance)}",
                    style: GoogleFonts.poppins(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryCard(
                          title: 'Income',
                          amount: kRupees.format(monthIncome),
                          change: _deltaLabel(incomeDelta),
                          changeColor: incomeDelta >= 0 ? kGreen : kRed,
                          icon: Icons.south_west,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SummaryCard(
                          title: 'Expenses',
                          amount: kRupees.format(monthExpense),
                          change: _deltaLabel(expenseDelta),
                          changeColor: expenseDelta <= 0 ? kGreen : kRed,
                          icon: Icons.north_east,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text('Spending Trends', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  _TrendsBarChart(data: weekBars),
                  const SizedBox(height: 24),
                  _CategorySpendingCard(categories: categoryMap),
                ],
              ),
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
            );
          },
          child: const Icon(Icons.add),
        ),
        bottomNavigationBar: _BottomNavDashboard(),
      ),
    );
  }

  // -------------------- Helpers --------------------
  static double _sumForMonth(List<TransactionItem> items, DateTime month, {required bool income}) {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);
    return items
        .where((t) => t.isIncome == income && t.date.isAfter(start.subtract(const Duration(milliseconds: 1))) && t.date.isBefore(end))
        .fold<double>(0, (a, b) => a + b.amount);
  }

  static double _pct(double prev, double curr) {
    if (prev == 0 && curr == 0) return 0;
    if (prev == 0) return 100;
    return ((curr - prev) / prev) * 100;
  }

  static String _deltaLabel(double v) {
    final sign = v >= 0 ? '+' : '';
    return '$sign${v.toStringAsFixed(0)}%';
  }

  static List<double> _weeklyExpenses(List<TransactionItem> items) {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final days = List<DateTime>.generate(7, (i) => DateTime(monday.year, monday.month, monday.day + i));
    final sums = List<double>.filled(7, 0);
    for (final t in items.where((t) => !t.isIncome)) {
      for (int i = 0; i < days.length; i++) {
        final d = days[i];
        if (t.date.year == d.year && t.date.month == d.month && t.date.day == d.day) {
          sums[i] += t.amount;
        }
      }
    }
    return sums;
  }

  static Map<String, double> _categorySumsForMonth(List<TransactionItem> items, DateTime month) {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);
    final map = <String, double>{};
    for (final t in items.where((t) => !t.isIncome && t.date.isAfter(start.subtract(const Duration(milliseconds: 1))) && t.date.isBefore(end))) {
      map[t.category] = (map[t.category] ?? 0) + t.amount;
    }
    return map;
  }
}

// -------------------- Widgets --------------------
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.change,
    required this.changeColor,
    required this.icon,
  });

  final String title;
  final String amount;
  final String change;
  final Color changeColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 6))],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(title, style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey)),
            Icon(icon, size: 18, color: Colors.grey),
          ]),
          const SizedBox(height: 8),
          Text(amount, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(change, style: GoogleFonts.poppins(fontSize: 13, color: changeColor, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _TrendsBarChart extends StatelessWidget {
  const _TrendsBarChart({super.key, required this.data});
  final List<double> data;

  static const Color kCyan = Color(0xFF00E5FF);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 6))],
      ),
      padding: const EdgeInsets.fromLTRB(12, 16, 24, 12),
      child: BarChart(
        BarChartData(
          gridData: FlGridData(show: false),
          borderData: FlBorderData(show: false),
          alignment: BarChartAlignment.spaceAround,
          barTouchData: BarTouchData(enabled: true),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                  final index = value.toInt();
                  if (index < 0 || index >= labels.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(labels[index], style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                  );
                },
              ),
            ),
          ),
          barGroups: List.generate(data.length, (i) {
            return BarChartGroupData(
              x: i,
              barRods: [BarChartRodData(toY: data[i], width: 16, borderRadius: BorderRadius.circular(8), color: kCyan)],
            );
          }),
        ),
      ),
    );
  }
}

class _CategorySpendingCard extends StatelessWidget {
  const _CategorySpendingCard({super.key, required this.categories});
  final Map<String, double> categories;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = categories.values.fold<double>(0, (a, b) => a + b);
    final colors = [const Color(0xFF00E5FF), Colors.purpleAccent, Colors.orangeAccent, Colors.greenAccent, Colors.yellowAccent];
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 6))],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Category Spending', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
          Text(kRupees.format(total), style: GoogleFonts.poppins(color: Colors.grey)),
        ]),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 32,
              sections: List.generate(categories.length, (i) {
                final key = categories.keys.elementAt(i);
                final value = categories[key]!;
                final percent = total == 0 ? '0' : (value / total * 100).toStringAsFixed(0);
                return PieChartSectionData(
                  value: value,
                  title: '$percent%',
                  radius: 70,
                  titleStyle: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black),
                  color: colors[i % colors.length],
                );
              }),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: List.generate(categories.length, (i) {
            final key = categories.keys.elementAt(i);
            final value = categories[key]!;
            return Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 10, height: 10, color: colors[i % colors.length]),
              const SizedBox(width: 6),
              Text('$key — ${kRupees.format(value)}', style: GoogleFonts.poppins(color: Colors.white70)),
            ]);
          }),
        )
      ]),
    );
  }
}

class _BottomNavDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const Color kCyan = Color(0xFF00E5FF);
    return BottomNavigationBar(
      backgroundColor: const Color(0xFF1A1A1A),
      type: BottomNavigationBarType.fixed,
      selectedItemColor: kCyan,
      unselectedItemColor: Colors.grey,
      currentIndex: 0,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
        BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded), label: 'Reports'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
      onTap: (i) {
        if (i == 1) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HistoryScreen()));
        } else if (i == 2) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ReportsScreen()));
        } else if (i == 3) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
        }
      },
    );
  }
}
