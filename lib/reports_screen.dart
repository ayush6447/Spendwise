// ===============================
// reports_screen.dart
// ===============================
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'utils/format.dart';
import 'services/hive_service.dart';
import 'models/transaction_item.dart';
import 'dashboard_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  static const kBg = Color(0xFF121212);
  static const kText = Colors.white;
  static const kCyan = Color(0xFF00E5FF);

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
        appBar: AppBar(title: const Text('Reports')),
        body: ValueListenableBuilder(
          valueListenable: HiveService.box().listenable(),
          builder: (context, box, _) {
            final items = (box as Box<TransactionItem>).values.toList();
            final now = DateTime.now();
            final income = items.where((t) => t.isIncome && t.date.month == now.month && t.date.year == now.year).fold<double>(0, (a, b) => a + b.amount);
            final expense = items.where((t) => !t.isIncome && t.date.month == now.month && t.date.year == now.year).fold<double>(0, (a, b) => a + b.amount);

            final categoryMap = <String, double>{};
            for (final t in items.where((t) => !t.isIncome && t.date.month == now.month && t.date.year == now.year)) {
              categoryMap[t.category] = (categoryMap[t.category] ?? 0) + t.amount;
            }

            final monday = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
            final days = List<DateTime>.generate(7, (i) => DateTime(monday.year, monday.month, monday.day + i));
            final weekSums = List<double>.filled(7, 0);
            for (final t in items.where((t) => !t.isIncome)) {
              for (int i = 0; i < days.length; i++) {
                final d = days[i];
                if (t.date.year == d.year && t.date.month == d.month && t.date.day == d.day) {
                  weekSums[i] += t.amount;
                }
              }
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StatRow(income: kRupees.format(income), expense: kRupees.format(expense)),
                  const SizedBox(height: 20),
                  _PieSection(categories: categoryMap),
                  const SizedBox(height: 20),
                  _WeeklyBar(weekSpends: weekSums),
                ],
              ),
            );
          },
        ),
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: const Color(0xFF1A1A1A),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: kCyan,
          unselectedItemColor: Colors.grey,
          currentIndex: 2,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
            BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded), label: 'Reports'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
          onTap: (i) {
            if (i == 0) {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardScreen()));
            } else if (i == 1) {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HistoryScreen()));
            } else if (i == 3) {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
            }
          },
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.income, required this.expense});
  final String income;
  final String expense;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _miniCard('Income', income, Colors.greenAccent)),
        const SizedBox(width: 12),
        Expanded(child: _miniCard('Expenses', expense, Colors.redAccent)),
      ],
    );
  }

  Widget _miniCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.poppins(color: Colors.grey)),
          const SizedBox(height: 8),
          Text(value, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

class _PieSection extends StatelessWidget {
  const _PieSection({required this.categories});
  final Map<String, double> categories;

  @override
  Widget build(BuildContext context) {
    final total = categories.values.fold<double>(0, (a, b) => a + b);
    final List<Color> colors = [
      const Color(0xFF00E5FF),
      Colors.purpleAccent,
      Colors.orangeAccent,
      Colors.greenAccent,
      Colors.yellowAccent,
    ];

    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Category Breakdown', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Expanded(
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
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 10, height: 10, color: colors[i % colors.length]),
                  const SizedBox(width: 6),
                  Text('$key — ${kRupees.format(value)}'),
                ],
              );
            }),
          )
        ],
      ),
    );
  }
}

class _WeeklyBar extends StatelessWidget {
  const _WeeklyBar({required this.weekSpends});
  final List<double> weekSpends;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 240,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.fromLTRB(12, 16, 24, 12),
      child: BarChart(
        BarChartData(
          gridData: FlGridData(show: false),
          borderData: FlBorderData(show: false),
          alignment: BarChartAlignment.spaceAround,
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) {
                  const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                  final idx = v.toInt();
                  if (idx < 0 || idx >= labels.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(labels[idx], style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                  );
                },
              ),
            ),
          ),
          barGroups: List.generate(weekSpends.length, (i) {
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: weekSpends[i],
                  width: 16,
                  borderRadius: BorderRadius.circular(8),
                  color: const Color(0xFF00E5FF),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
