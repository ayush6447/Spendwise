// ===============================
// add_transaction_screen.dart
// ===============================
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'utils/format.dart';
import 'models/transaction_item.dart';
import 'services/hive_service.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  static const Color kBg = Color(0xFF121212);
  static const Color kText = Colors.white;
  static const Color kHint = Colors.grey;
  static const Color kCyan = Color(0xFF00E5FF);

  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  String _category = 'Food';
  bool _isIncome = false;

  String get _dateLabel => kDate.format(_date);

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: kCyan,
              onPrimary: Colors.black,
              surface: kBg,
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color(0xFF1E1E1E),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount')),
      );
      return;
    }

    // 🔑 Generate a simple unique ID from timestamp
    final id = DateTime.now().millisecondsSinceEpoch.toString();

    final item = TransactionItem(
      id: id,
      amount: amount,
      date: _date,
      category: _isIncome ? 'Income' : _category,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      isIncome: _isIncome,
    );

    await HiveService.box().put(id, item);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transaction added')),
    );
    Navigator.pop(context);
  }

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
        appBarTheme: const AppBarTheme(
          backgroundColor: kBg,
          foregroundColor: kText,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1E1E1E),
          hintStyle: GoogleFonts.poppins(color: kHint),
          labelStyle: GoogleFonts.poppins(color: kText),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.white12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: kCyan, width: 1.6),
          ),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text('Add Transaction',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Income/Expense toggle
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('Expense'),
                    selected: !_isIncome,
                    onSelected: (_) => setState(() => _isIncome = false),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Income'),
                    selected: _isIncome,
                    onSelected: (_) => setState(() => _isIncome = true),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Text('Amount',
                  style: GoogleFonts.poppins(fontSize: 14, color: kHint)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountCtrl,
                keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
                style: GoogleFonts.poppins(
                    fontSize: 28, fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                  prefixText: '₹',
                  prefixStyle: GoogleFonts.poppins(
                      fontSize: 28, fontWeight: FontWeight.w700, color: kText),
                  contentPadding:
                  const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                ),
              ),

              const SizedBox(height: 16),
              Text('Date',
                  style: GoogleFonts.poppins(fontSize: 14, color: kHint)),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    suffixIcon:
                    Icon(Icons.calendar_today, color: Colors.white70),
                    contentPadding:
                    EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  ),
                  child: Text(_dateLabel),
                ),
              ),

              const SizedBox(height: 16),
              Text('Note',
                  style: GoogleFonts.poppins(fontSize: 14, color: kHint)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _noteCtrl,
                decoration: const InputDecoration(
                  hintText: 'Note (optional)',
                ),
                maxLines: 2,
              ),

              const SizedBox(height: 16),
              if (!_isIncome) ...[
                Text('Category',
                    style: GoogleFonts.poppins(fontSize: 14, color: kHint)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _category,
                  items: const [
                    DropdownMenuItem(value: 'Food', child: Text('Food')),
                    DropdownMenuItem(value: 'Travel', child: Text('Travel')),
                    DropdownMenuItem(value: 'Bills', child: Text('Bills')),
                    DropdownMenuItem(value: 'Shopping', child: Text('Shopping')),
                    DropdownMenuItem(value: 'Health', child: Text('Health')),
                    DropdownMenuItem(value: 'Other', child: Text('Other')),
                  ],
                  onChanged: (v) => setState(() => _category = v ?? 'Food'),
                  iconEnabledColor: kText,
                  dropdownColor: const Color(0xFF1E1E1E),
                ),
                const SizedBox(height: 24),
              ],

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kCyan,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _submit,
                  child: Text('Add Transaction',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
