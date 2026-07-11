import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:barcode_widget/barcode_widget.dart';
import '../services/app_services.dart';

class CreationScreen extends StatefulWidget {
  const CreationScreen({super.key});

  @override
  State<CreationScreen> createState() => _CreationScreenState();
}

class _CreationScreenState extends State<CreationScreen> {
  final TextEditingController _amountController = TextEditingController();
  bool _isProcessing = false;

  void _onCreate() async {
    final amount = int.tryParse(_amountController.text) ?? 0;
    if (amount <= 0 || amount > 1800) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Betrag muss zwischen 1 und 1800 liegen.')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final token = await AppServices.instance.ledgerService.createToken(
        creator: AppServices.instance.currentIdentity,
        amount: amount,
      );

      if (!mounted) return;
      
      // Tastatur/Fokus entfernen, um Deadlocks auf Desktop-Systemen zu vermeiden
      FocusScope.of(context).unfocus();

      // Zeige Erfolg an
      showDialog(
        context: context,
        barrierDismissible: false, // Verhindere Schließen durch Klicken daneben während UI rendert
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: Text('Schöpfung initiiert', style: GoogleFonts.outfit(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Sie haben $amount Minutos geschöpft.\nLassen Sie diesen Code nun von 2 Bürgen scannen.',
                style: GoogleFonts.inter(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: BarcodeWidget(
                  barcode: Barcode.qrCode(),
                  data: 'digiminuto:guarantee:${token.id}:${token.creatorPubKey}:${token.amount}:${token.creationYear}',
                  width: 200.0,
                  height: 200.0,
                  color: Colors.black,
                  backgroundColor: Colors.white,
                  errorBuilder: (context, error) => Center(child: Text(error)),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Token-ID: ${token.id.substring(0,8)}...',
                style: GoogleFonts.inter(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close Dialog
                Navigator.of(context).pop(); // Return to Dashboard
              },
              child: const Text('OK', style: TextStyle(color: Colors.tealAccent)),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler bei der Schöpfung: $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
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
                onPressed: _isProcessing ? null : _onCreate,
                child: _isProcessing 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
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
