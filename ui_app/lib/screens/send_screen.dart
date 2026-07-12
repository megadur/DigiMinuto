import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:core_engine/core_engine.dart';
import '../services/app_services.dart';
import 'scanner_screen.dart';

class SendScreen extends StatefulWidget {
  const SendScreen({super.key});

  @override
  State<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends State<SendScreen> {
  List<Token> _ownedTokens = [];
  bool _isLoading = true;
  Transaction? _completedTransfer;

  @override
  void initState() {
    super.initState();
    _loadTokens();
  }

  Future<void> _loadTokens() async {
    final identity = AppServices.instance.currentIdentity;
    try {
      final tokens = await AppServices.instance.ledgerService.getOwnedTokens(identity.publicKey);
      setState(() {
        _ownedTokens = tokens;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Fehler beim Laden: $e')));
      }
    }
  }

  Future<void> _sendToken(Token token) async {
    // 1. Scan receiver's public key
    final result = await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ScannerScreen()));
    
    if (result is String) {
      String receiverPubKey = result;
      // Falls der QR-Code z.B. "digiminuto:pubkey:XYZ" ist
      if (result.startsWith('digiminuto:pubkey:')) {
        receiverPubKey = result.split(':')[2];
      }

      setState(() {
        _isLoading = true;
      });

      try {
        final tx = await AppServices.instance.ledgerService.transferToken(
          token: token,
          sender: AppServices.instance.currentIdentity,
          receiverPubKey: receiverPubKey,
        );

        setState(() {
          _completedTransfer = tx;
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Senden fehlgeschlagen: $e'), backgroundColor: Colors.red));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Senden', style: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _completedTransfer != null
              ? _buildTransferQR(textColor, isDark)
              : _buildTokenList(textColor, isDark),
    );
  }

  Widget _buildTokenList(Color textColor, bool isDark) {
    if (_ownedTokens.isEmpty) {
      return Center(
        child: Text(
          'Sie haben aktuell keine aktiven Minutos zum Senden.',
          style: GoogleFonts.inter(color: textColor),
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _ownedTokens.length,
      itemBuilder: (context, index) {
        final token = _ownedTokens[index];
        return Card(
          color: Theme.of(context).colorScheme.surface,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            leading: const Icon(Icons.money, color: Colors.green, size: 40),
            title: Text('${token.amount} Minutos', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
            subtitle: Text('ID: ${token.id.substring(0, 8)}...', style: GoogleFonts.inter(color: textColor.withOpacity(0.6))),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _sendToken(token),
          ),
        );
      },
    );
  }

  Widget _buildTransferQR(Color textColor, bool isDark) {
    final tx = _completedTransfer!;
    final qrData = 'digiminuto:transfer:${tx.tokenId}:${tx.senderPubKey}:${tx.receiverPubKey}:${tx.timestamp.toIso8601String()}:${tx.signature}';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Transfer erfolgreich signiert!',
            style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Text(
              'Lassen Sie den Empfänger diesen QR-Code scannen, um die Übertragung abzuschließen.',
              style: GoogleFonts.inter(fontSize: 16, color: textColor),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 30),
          if (AppServices.instance.nostrService.isConnected) ...[
            ElevatedButton.icon(
              onPressed: () async {
                try {
                  await AppServices.instance.nostrService.sendPayload(
                    tx.receiverPubKey,
                    qrData,
                    AppServices.instance.currentIdentity.privateKey!,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erfolgreich über Nostr gesendet!'), backgroundColor: Colors.green));
                    Navigator.of(context).pop();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Fehler beim Senden über Nostr: $e'), backgroundColor: Colors.red));
                  }
                }
              },
              icon: const Icon(Icons.cloud_upload),
              label: Text('Senden via Nostr', style: GoogleFonts.inter()),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Oder alternativ als QR-Code scannen:',
              style: GoogleFonts.inter(color: textColor.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 10),
          ],
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: QrImageView(
              data: qrData,
              version: QrVersions.auto,
              size: 250,
            ),
          ),
        ],
      ),
    );
  }
}
