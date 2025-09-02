// ===================================================================
// cards_screen.dart — full number + brand + bank + CVV toggle + flip
// ===================================================================
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/card_item.dart';

class CardsScreen extends StatelessWidget {
  const CardsScreen({super.key});

  static const kBg = Color(0xFF121212);
  static const kText = Colors.white;
  static const kCyan = Color(0xFF00E5FF);

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        scaffoldBackgroundColor: kBg,
        appBarTheme: const AppBarTheme(backgroundColor: kBg, foregroundColor: kText),
        textTheme: GoogleFonts.poppinsTextTheme(
          Theme.of(context).textTheme.apply(bodyColor: kText, displayColor: kText),
        ),
        cardColor: const Color(0xFF1E1E1E),
      ),
      child: Scaffold(
        appBar: AppBar(title: const Text("My Cards")),
        body: ValueListenableBuilder(
          valueListenable: Hive.box<CardItem>("cardsBox").listenable(),
          builder: (context, Box<CardItem> box, _) {
            if (box.isEmpty) {
              return Center(
                child: Text("No cards saved yet", style: GoogleFonts.poppins(color: Colors.grey)),
              );
            }
            final cards = box.values.toList();

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: cards.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (_, i) {
                final card = cards[i];
                return Dismissible(
                  key: Key(card.id),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (_) => _confirmDelete(context, card),
                  onDismissed: (_) => box.delete(card.id),
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.delete, color: Colors.redAccent),
                  ),
                  child: _FlipCardTile(
                    card: card,
                    onEdit: () => _showAddOrEditDialog(context, existing: card),
                  ),
                );
              },
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: kCyan,
          child: const Icon(Icons.add, color: Colors.black),
          onPressed: () => _showAddOrEditDialog(context),
        ),
      ),
    );
  }

  // ---------- dialogs / validation ----------

  static Future<bool> _confirmDelete(BuildContext context, CardItem card) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kBg,
        title: const Text("Delete card?", style: TextStyle(color: kText)),
        content: Text(
          "This will remove •••• ${card.cardNumber.substring(card.cardNumber.length - 4)}",
          style: GoogleFonts.poppins(color: Colors.grey),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
    return res ?? false;
  }

  static void _showAddOrEditDialog(BuildContext context, {CardItem? existing}) {
    final bankCtrl   = TextEditingController(text: existing?.bankName ?? "");
    final nameCtrl   = TextEditingController(text: existing?.holderName ?? "");
    final numberCtrl = TextEditingController(text: existing?.cardNumber ?? "");
    final expiryCtrl = TextEditingController(text: existing?.expiryDate ?? "");
    final cvvCtrl    = TextEditingController(text: existing?.cvv ?? "");
    bool showCvv     = existing?.showCvv ?? true; // default show

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateDialog) {
            return AlertDialog(
              backgroundColor: kBg,
              title: Text(existing == null ? "Add Card" : "Edit Card", style: const TextStyle(color: kText)),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    children: [
                      _field(
                        label: "Bank Name",
                        controller: bankCtrl,
                        validator: (v) => (v == null || v.trim().isEmpty) ? "Enter bank" : null,
                      ),
                      _field(
                        label: "Holder Name",
                        controller: nameCtrl,
                        validator: (v) => (v == null || v.trim().isEmpty) ? "Enter name" : null,
                      ),
                      _field(
                        label: "Card Number",
                        controller: numberCtrl,
                        keyboardType: TextInputType.number,
                        maxLength: 19,
                        validator: (v) {
                          final digits = (v ?? "").replaceAll(RegExp(r'\D'), "");
                          if (digits.length < 13 || digits.length > 19) return "Invalid number";
                          return null;
                        },
                      ),
                      _field(
                        label: "Expiry Date (MM/YY)",
                        controller: expiryCtrl,
                        keyboardType: TextInputType.datetime,
                        validator: (v) => _validateExpiry(v ?? ""),
                      ),
                      _field(
                        label: "CVV",
                        controller: cvvCtrl,
                        keyboardType: TextInputType.number,
                        obscure: true,
                        maxLength: 4,
                        validator: (v) {
                          final digits = (v ?? "").replaceAll(RegExp(r'\D'), "");
                          if (digits.length < 3 || digits.length > 4) return "Invalid CVV";
                          return null;
                        },
                      ),
                      const SizedBox(height: 6),
                      SwitchListTile(
                        value: showCvv,
                        onChanged: (v) => setStateDialog(() => showCvv = v),
                        title: const Text("Show CVV on card", style: TextStyle(color: kText)),
                        contentPadding: EdgeInsets.zero,
                        activeColor: kCyan,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: kCyan, foregroundColor: Colors.black),
                  onPressed: () {
                    if (!formKey.currentState!.validate()) return;
                    final box = Hive.box<CardItem>("cardsBox");
                    final id = existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString();

                    box.put(
                      id,
                      CardItem(
                        id: id,
                        bankName: bankCtrl.text.trim(),
                        holderName: nameCtrl.text.trim(),
                        cardNumber: numberCtrl.text.replaceAll(" ", "").trim(),
                        expiryDate: expiryCtrl.text.trim(),
                        cvv: cvvCtrl.text.trim(),
                        showCvv: showCvv, // ✅ persisted
                      ),
                    );
                    Navigator.pop(ctx);
                  },
                  child: Text(existing == null ? "Save" : "Update"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  static String? _validateExpiry(String input) {
    final s = input.trim();
    final exp = RegExp(r'^\d{2}/\d{2}$');
    if (!exp.hasMatch(s)) return "Use MM/YY";
    final mm = int.tryParse(s.substring(0, 2)) ?? 0;
    final yy = int.tryParse(s.substring(3)) ?? 0;
    if (mm < 1 || mm > 12) return "Invalid month";
    final year = 2000 + yy;
    final now = DateTime.now();
    final endOfMonth = DateTime(year, mm + 1, 0);
    if (endOfMonth.isBefore(DateTime(now.year, now.month, 1))) return "Card expired";
    return null;
  }

  static Widget _field({
    required String label,
    required TextEditingController controller,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    bool obscure = false,
    int? maxLength,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        obscureText: obscure,
        maxLength: maxLength,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          counterText: "",
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.white24),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kCyan),
          ),
        ),
      ),
    );
  }
}

// ---------- Flip card with bank/brand + FIXED back rotation ----------

class _FlipCardTile extends StatefulWidget {
  const _FlipCardTile({required this.card, required this.onEdit});
  final CardItem card;
  final VoidCallback onEdit;

  @override
  State<_FlipCardTile> createState() => _FlipCardTileState();
}

class _FlipCardTileState extends State<_FlipCardTile> {
  bool showBack = false;

  @override
  Widget build(BuildContext context) {
    final brand = _detectBrand(widget.card.cardNumber);

    return GestureDetector(
      onTap: () => setState(() => showBack = !showBack),
      onLongPress: widget.onEdit,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: showBack ? 1 : 0),
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
        builder: (context, t, child) {
          final isBack = t > 0.5;
          final angle = t * math.pi;
          final transform = Matrix4.identity()
            ..setEntry(3, 2, 0.0015)
            ..rotateY(angle);

          return Transform(
            alignment: Alignment.center,
            transform: transform,
            child: Container(
              height: 190,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isBack
                      ? [const Color(0xFF0F0F0F), const Color(0xFF232323)]
                      : [const Color(0xFF1E1E1E), const Color(0xFF2B2B2B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 6))],
              ),
              padding: const EdgeInsets.all(18),
              child: isBack
                  ? Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()..rotateY(math.pi), // un-mirror back
                child: _BackFace(card: widget.card),
              )
                  : _FrontFace(card: widget.card, brand: brand),
            ),
          );
        },
      ),
    );
  }
}

class _FrontFace extends StatelessWidget {
  const _FrontFace({required this.card, required this.brand});
  final CardItem card;
  final _BrandInfo brand;

  @override
  Widget build(BuildContext context) {
    // format as XXXX XXXX XXXX XXXX
    final formatted = card.cardNumber.replaceAllMapped(RegExp(r".{1,4}"), (m) => "${m.group(0)} ").trim();
    final bankName = (card.bankName ?? "").trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(brand.icon, color: brand.color),
            const SizedBox(width: 8),
            Text(brand.name, style: GoogleFonts.poppins(color: Colors.white70)),
            const Spacer(),
            if (bankName.isNotEmpty)
              Text(bankName, style: GoogleFonts.poppins(color: Colors.white70, fontWeight: FontWeight.w600)),
          ],
        ),
        const Spacer(),
        Text(
          formatted,
          style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(card.holderName,
                  style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13)),
            ),
            Text("Exp: ${card.expiryDate}", style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13)),
          ],
        ),
      ],
    );
  }
}

class _BackFace extends StatelessWidget {
  const _BackFace({required this.card});
  final CardItem card;

  @override
  Widget build(BuildContext context) {
    final showCvv = card.showCvv; // persisted
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(height: 36, decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(6))),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 34,
                color: Colors.white,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(" ", style: GoogleFonts.poppins(color: Colors.black)),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                showCvv ? card.cvv : card.cvv.replaceAll(RegExp(r'.'), '•'),
                style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const Spacer(),
        Align(
          alignment: Alignment.bottomRight,
          child: Text("Tap to flip", style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12)),
        ),
      ],
    );
  }
}

// ---------- simple brand detection ----------

class _BrandInfo {
  final String name;
  final IconData icon;
  final Color color;
  const _BrandInfo(this.name, this.icon, this.color);
}

_BrandInfo _detectBrand(String number) {
  final n = number.replaceAll(RegExp(r'\D'), "");
  if (RegExp(r'^4').hasMatch(n)) {
    return const _BrandInfo("Visa", Icons.check_circle, Color(0xFF1A73E8));
  } else if (RegExp(r'^(5[1-5]|2[2-7])').hasMatch(n)) {
    return const _BrandInfo("Mastercard", Icons.circle, Color(0xFFE53935));
  } else if (RegExp(r'^3[47]').hasMatch(n)) {
    return const _BrandInfo("AmEx", Icons.change_circle, Color(0xFF00BCD4));
  } else if (RegExp(r'^(6011|65|64[4-9])').hasMatch(n)) {
    return const _BrandInfo("Discover", Icons.waves, Color(0xFFFFA000));
  } else if (RegExp(r'^(352[89]|35[3-8])').hasMatch(n)) {
    return const _BrandInfo("JCB", Icons.blur_circular, Color(0xFF9C27B0));
  } else if (RegExp(r'^(36|30[0-5]|38|39)').hasMatch(n)) {
    return const _BrandInfo("Diners", Icons.donut_large, Color(0xFF4CAF50));
  } else if (RegExp(r'^(508|606985|6521|6522)').hasMatch(n)) {
    return const _BrandInfo("RuPay", Icons.blur_on, Color(0xFF00E5FF));
  } else {
    return const _BrandInfo("Card", Icons.credit_card, Colors.white70);
  }
}
