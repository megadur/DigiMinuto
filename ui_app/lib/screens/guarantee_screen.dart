import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:core_engine/core_engine.dart';
import 'dart:convert';
import '../services/app_services.dart';

class GuaranteeScreen extends StatefulWidget {
  final String tokenId;
  final String creatorPubKey;
  final int amount;
  final int creationYear;
  final String description;

  const GuaranteeScreen({
    super.key,
    required this.tokenId,
    required this.creatorPubKey,
    required this.amount,
    required this.creationYear,
    this.description = '',
  });

  @override
  State<GuaranteeScreen> createState() => _GuaranteeScreenState();
}

class _GuaranteeScreenState extends State<GuaranteeScreen> {
  bool _isProcessing = false;
  String? _signatureQrData;
  String? _error;

  Future<void> _signGuarantee() async {
    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      final appServices = AppServices.instance;
      final identity = appServices.currentIdentity;
      
      if (identity.privateKey == null) {
        throw Exception("Kein lokaler Private Key vorhanden!");
      }
      
      if (identity.publicKey == widget.creatorPubKey) {
        throw Exception("Sie können nicht für sich selbst bürgen!");
      }

      // 1. Token-Payload rekonstruieren
      final descBase64 = base64Encode(utf8.encode(widget.description));
      final payload = "${widget.tokenId}:${widget.creatorPubKey}:${widget.amount}:${widget.creationYear}:$descBase64";
      
      // 2. KeyPair laden und signieren
      final keyPair = await appServices.cryptoService.loadKeyPairFromBase64(
        identity.privateKey!, 
        identity.publicKey
      );
      final signatureBase64 = await appServices.cryptoService.signData(payload, keyPair);

      // 3. Token in lokaler DB speichern als "Schwebend" (damit wir wissen, dass wir gebürgt haben)
      final token = Token(
        id: widget.tokenId,
        creatorPubKey: widget.creatorPubKey,
        amount: widget.amount,
        creationYear: widget.creationYear,
        description: widget.description,
        status: TokenStatus.pending,
      );
      token.guarantor1Signature = signatureBase64;
      await appServices.tokenRepository.saveToken(token);

      // 4. QR-Code Daten generieren für den Rückkanal
      setState(() {
        _signatureQrData = "digiminuto:signature:${widget.tokenId}:${identity.publicKey}:$signatureBase64";
      });

    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Bürgschaft leisten', style: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.bold)),
        iconTheme: IconThemeData(color: textColor),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: _signatureQrData != null ? _buildSuccessView(textColor) : _buildConfirmView(textColor),
        ),
      ),
    );
  }

  Widget _buildConfirmView(Color textColor) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.handshake, size: 64, color: Colors.amber.shade400),
        const SizedBox(height: 24),
        Text(
          'Möchten Sie bürgen?',
          style: GoogleFonts.outfit(color: textColor, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Text(
          'Sie bürgen für ${widget.amount} Minutos.\nSchöpfer-ID: ${widget.creatorPubKey.substring(0,8)}...',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(color: textColor.withValues(alpha: 0.8), fontSize: 16),
        ),
        if (widget.description.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Notiz: "${widget.description}"',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: textColor.withValues(alpha: 0.9),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
        const SizedBox(height: 32),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text(_error!, style: const TextStyle(color: Colors.redAccent)),
          ),
        _isProcessing
            ? const CircularProgressIndicator(color: Colors.amber)
            : ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                onPressed: _signGuarantee,
                child: Text('Ja, ich bürge', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
      ],
    );
  }

  Widget _buildSuccessView(Color textColor) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.check_circle, color: Colors.greenAccent, size: 64),
        const SizedBox(height: 24),
        Text(
          'Bürgschaft erfolgreich!',
          style: GoogleFonts.outfit(color: textColor, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Text(
          'Lassen Sie den Schöpfer diesen QR-Code scannen, um die Bürgschaft offline abzuschließen.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(color: textColor.withValues(alpha: 0.8), fontSize: 16),
        ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: BarcodeWidget(
            barcode: Barcode.qrCode(),
            data: _signatureQrData!,
            width: 200.0,
            height: 200.0,
            color: Colors.black,
            backgroundColor: Colors.white,
            errorBuilder: (context, error) => Center(child: Text(error)),
          ),
        ),
        const SizedBox(height: 32),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Fertig', style: TextStyle(color: Colors.tealAccent, fontSize: 18)),
        ),
      ],
    );
  }
}
