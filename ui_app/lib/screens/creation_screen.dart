import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CreationScreen extends StatefulWidget {
  const CreationScreen({super.key});

  @override
  State<CreationScreen> createState() => _CreationScreenState();
}

class _CreationScreenState extends State<CreationScreen> {
  final TextEditingController _amountController = TextEditingController();

  void _onCreate() {
    // TODO: Nutze CoreEngine LedgerService um einen Pending-Token zu erstellen
    final amount = int.tryParse(_amountController.text) ?? 0;
    if (amount <= 0 || amount > 1800) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Betrag muss zwischen 1 und 1800 liegen.')),
      );
      return;
    }

    // Für jetzt zeigen wir nur einen Erfolg an
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text('Schöpfung initiiert', style: GoogleFonts.outfit(color: Colors.white)),
        content: Text(
          'Bitte lassen Sie diesen Vorgang nun von 2 Bürgen bestätigen (QR-Code).',
          style: GoogleFonts.inter(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK', style: TextStyle(color: Colors.tealAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Minutos Schöpfen',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Geben Sie den gewünschten Betrag ein (Maximal 1800 pro Jahr).',
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: GoogleFonts.outfit(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF1E293B),
                hintText: '0',
                hintStyle: GoogleFonts.outfit(color: Colors.white24),
                suffixText: 'Minutos',
                suffixStyle: GoogleFonts.inter(color: Colors.tealAccent, fontSize: 18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1), // Indigo
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _onCreate,
                child: Text(
                  'Jetzt Schöpfen',
                  style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
