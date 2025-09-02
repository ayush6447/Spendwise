// ===============================
// profile_screen.dart (with PFP, name, age, country)
// ===============================
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dashboard_screen.dart';
import 'history_screen.dart';
import 'reports_screen.dart';
import 'services/hive_service.dart';
import 'models/transaction_item.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const kBg = Color(0xFF121212);
  static const kText = Colors.white;
  static const kCyan = Color(0xFF00E5FF);

  double? startBalance;
  late Box profileBox;

  @override
  void initState() {
    super.initState();
    _loadBalance();
    _initProfile();
  }

  Future<void> _initProfile() async {
    profileBox = await Hive.openBox("profileBox");
    setState(() {});
  }

  Future<void> _loadBalance() async {
    final settings = await Hive.openBox("settingsBox");
    setState(() => startBalance = settings.get("startBalance", defaultValue: 0.0));
  }

  Future<void> _setBalance() async {
    final controller = TextEditingController(
      text: startBalance?.toStringAsFixed(2) ?? "",
    );
    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: kBg,
          title: const Text("Set Starting Balance", style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: "Enter amount",
              hintStyle: TextStyle(color: Colors.grey),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: kCyan, foregroundColor: Colors.black),
              onPressed: () async {
                final value = double.tryParse(controller.text.trim());
                if (value != null) {
                  final settings = await Hive.openBox("settingsBox");
                  await settings.put("startBalance", value);
                  setState(() => startBalance = value);
                }
                if (mounted) Navigator.pop(ctx);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _resetCurrentMonth() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 1);

    final box = HiveService.box();
    final toDelete = box.values
        .where((tx) => tx.date.isAfter(start.subtract(const Duration(milliseconds: 1))) && tx.date.isBefore(end))
        .map((tx) => tx.id)
        .toList();

    for (final id in toDelete) {
      await box.delete(id);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Current month reset")));
    }
  }

  Future<void> _editProfile() async {
    final nameCtrl = TextEditingController(text: profileBox.get("name", defaultValue: "SpendWise User"));
    final ageCtrl = TextEditingController(text: profileBox.get("age", defaultValue: ""));
    final countryCtrl = TextEditingController(text: profileBox.get("country", defaultValue: "India"));
    String? pfpPath = profileBox.get("pfp");

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: kBg,
              title: const Text("Edit Profile", style: TextStyle(color: Colors.white)),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
                        if (picked != null) {
                          pfpPath = picked.path;
                          setStateDialog(() {});
                        }
                      },
                      child: CircleAvatar(
                        radius: 40,
                        backgroundImage: pfpPath != null ? FileImage(File(pfpPath!)) : null,
                        backgroundColor: kCyan,
                        child: pfpPath == null ? const Icon(Icons.person, color: Colors.black, size: 40) : null,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: "Name", labelStyle: TextStyle(color: Colors.grey)),
                    ),
                    TextField(
                      controller: ageCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: "Age", labelStyle: TextStyle(color: Colors.grey)),
                      keyboardType: TextInputType.number,
                    ),
                    TextField(
                      controller: countryCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: "Country", labelStyle: TextStyle(color: Colors.grey)),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: kCyan, foregroundColor: Colors.black),
                  onPressed: () async {
                    await profileBox.put("name", nameCtrl.text.trim());
                    await profileBox.put("age", ageCtrl.text.trim());
                    await profileBox.put("country", countryCtrl.text.trim());
                    if (pfpPath != null) await profileBox.put("pfp", pfpPath);
                    if (mounted) setState(() {});
                    if (mounted) Navigator.pop(ctx);
                  },
                  child: const Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = profileBox.get("name", defaultValue: "SpendWise User");
    final age = profileBox.get("age", defaultValue: "");
    final country = profileBox.get("country", defaultValue: "India");
    final pfpPath = profileBox.get("pfp");

    return Theme(
      data: theme.copyWith(
        scaffoldBackgroundColor: kBg,
        appBarTheme: const AppBarTheme(backgroundColor: kBg, foregroundColor: kText, elevation: 0),
        textTheme: GoogleFonts.poppinsTextTheme(theme.textTheme.apply(bodyColor: kText, displayColor: kText)),
        cardColor: const Color(0xFF1E1E1E),
      ),
      child: Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Profile Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundImage: pfpPath != null ? FileImage(File(pfpPath)) : null,
                    backgroundColor: kCyan,
                    child: pfpPath == null ? const Icon(Icons.person, color: Colors.black, size: 32) : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                        if (age.isNotEmpty)
                          Text("Age: $age", style: GoogleFonts.poppins(color: Colors.grey, fontSize: 13)),
                        Text(country, style: GoogleFonts.poppins(color: Colors.grey, fontSize: 13)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _editProfile,
                    icon: const Icon(Icons.edit, color: Colors.white70),
                  )
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Starting Balance Row
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Starting Balance", style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey)),
                      const SizedBox(height: 6),
                      Text("₹${(startBalance ?? 0).toStringAsFixed(2)}",
                          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                    ],
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kCyan,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _setBalance,
                    child: const Text("Set"),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Reset Button
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _resetCurrentMonth,
              icon: const Icon(Icons.refresh),
              label: const Text("Reset Current Month"),
            ),
            const SizedBox(height: 16),

            _tile(Icons.notifications_active, 'Notifications', 'On'),
            _tile(Icons.lock, 'Privacy', 'Standard'),
            _tile(Icons.info_outline, 'About', 'v1.0.0'),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: const Color(0xFF1A1A1A),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: kCyan,
          unselectedItemColor: Colors.grey,
          currentIndex: 3,
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
            } else if (i == 2) {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ReportsScreen()));
            }
          },
        ),
      ),
    );
  }

  Widget _tile(IconData icon, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white),
        title: Text(title),
        subtitle: Text(subtitle, style: GoogleFonts.poppins(color: Colors.grey)),
        trailing: const Icon(Icons.chevron_right, color: Colors.white70),
        onTap: () {},
      ),
    );
  }
}
