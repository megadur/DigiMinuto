import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:core_engine/core_engine.dart';
import '../services/app_services.dart';
import 'package:flutter/services.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameController;
  late Identity _identity;
  bool _isEditingName = false;

  @override
  void initState() {
    super.initState();
    _identity = AppServices.instance.currentIdentity;
    _nameController = TextEditingController(text: _identity.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    final newName = _nameController.text.trim();
    if (newName.isNotEmpty && newName != _identity.name) {
      final updatedIdentity = Identity(
        publicKey: _identity.publicKey,
        privateKey: _identity.privateKey,
        name: newName,
      );
      await AppServices.instance.identityRepository.saveIdentity(updatedIdentity);
      AppServices.instance.currentIdentity = updatedIdentity;
      setState(() {
        _identity = updatedIdentity;
        _isEditingName = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Name erfolgreich geändert!'), backgroundColor: Colors.green),
        );
      }
    } else {
      setState(() {
        _isEditingName = false;
      });
    }
  }

  void _showBackupDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Sicherheits-Backup', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dies ist Ihr privater Schlüssel. Geben Sie ihn niemals an andere weiter! Wenn Sie diesen Schlüssel verlieren, sind all Ihre geschöpften Minutos und Guthaben unwiederbringlich verloren.',
                style: GoogleFonts.inter(color: Colors.redAccent),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.grey.withValues(alpha: 0.1),
                child: SelectableText(
                  _identity.privateKey ?? 'Kein Private Key gefunden.',
                  style: GoogleFonts.robotoMono(fontSize: 12),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _identity.privateKey ?? ''));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('In die Zwischenablage kopiert!')));
                Navigator.of(context).pop();
              },
              child: const Text('Kopieren'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Schließen'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Mein Profil', style: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                child: Icon(Icons.person, size: 50, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(height: 20),
              
              // Name Section
              if (_isEditingName)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Ihr Name',
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (_) => _saveName(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      onPressed: _saveName,
                    ),
                  ],
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _identity.name ?? 'Unbekannt',
                      style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: textColor),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: () {
                        setState(() {
                          _isEditingName = true;
                        });
                      },
                    ),
                  ],
                ),

              const SizedBox(height: 40),

              // QR Code Section
              Text(
                'Lassen Sie diesen Code scannen, um Zahlungen zu empfangen.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: textColor.withValues(alpha: 0.7)),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                child: QrImageView(
                  data: 'digiminuto:pubkey:${_identity.publicKey}',
                  version: QrVersions.auto,
                  size: 200,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Mein Public Key:',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: textColor),
              ),
              const SizedBox(height: 8),
              SelectableText(
                _identity.publicKey,
                style: GoogleFonts.robotoMono(fontSize: 12, color: textColor.withValues(alpha: 0.6)),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 50),

              // Backup Section
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _showBackupDialog,
                  icon: const Icon(Icons.security),
                  label: const Text('Privaten Schlüssel sichern'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Bitte sichern Sie Ihren privaten Schlüssel sicher. Bei Datenverlust im Browser ist dies Ihre einzige Wiederherstellungsmöglichkeit.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 12, color: textColor.withValues(alpha: 0.5)),
              )
            ],
          ),
        ),
      ),
    );
  }
}
