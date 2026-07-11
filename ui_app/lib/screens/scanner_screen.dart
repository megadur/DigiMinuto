import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  MobileScannerController? _controller;
  bool _isWindows = false;

  @override
  void initState() {
    super.initState();
    // Prüfe ob wir auf Windows sind, da die Kamera-Treiber dort oft die App blockieren (Not Responding)
    if (!kIsWeb && Platform.isWindows) {
      _isWindows = true;
    } else {
      _controller = MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
      );
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
        title: Text(
          'QR-Code scannen',
          style: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.bold),
        ),
        iconTheme: IconThemeData(color: textColor),
        actions: _isWindows ? [] : [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _controller?.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios),
            onPressed: () => _controller?.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          if (!_isWindows)
            MobileScanner(
              controller: _controller!,
              onDetect: (capture) {
                final List<Barcode> barcodes = capture.barcodes;
                for (final barcode in barcodes) {
                  if (barcode.rawValue != null) {
                    debugPrint('Barcode gefunden! ${barcode.rawValue}');
                    Navigator.of(context).pop(barcode.rawValue);
                    break;
                  }
                }
              },
            ),
          
          if (_isWindows)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.no_photography, color: textColor.withValues(alpha: 0.5), size: 64),
                    const SizedBox(height: 20),
                    Text(
                      'Kamera-Scanner wird auf Windows nicht unterstützt.\n(Bitte nutzen Sie später ein Android/iOS Gerät).',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(color: textColor.withValues(alpha: 0.8), fontSize: 16),
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.qr_code_2, color: Colors.white),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
                      label: Text('Erfolgreiche Schöpfung simulieren', style: GoogleFonts.inter(color: Colors.white)),
                      onPressed: () {
                        // Simuliert den Scan eines Gutscheins (Bürge scannt Schöpfer)
                        Navigator.of(context).pop("digiminuto:guarantee:test1234:simulatedPubKey:100:2026");
                      },
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.verified, color: Colors.white),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF14B8A6)),
                      label: Text('Erfolgreichen Rückkanal simulieren', style: GoogleFonts.inter(color: Colors.white)),
                      onPressed: () {
                        // Simuliert den Scan der Signatur (Schöpfer scannt Bürge)
                        Navigator.of(context).pop("digiminuto:signature:test1234:simulatedGuarantorKey:SimulatedSignatureBase64String==");
                      },
                    )
                  ],
                ),
              ),
            )
          else
            // Zielfenster Overlay (nur wenn Kamera aktiv)
            Center(
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.tealAccent, width: 3),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                _isWindows ? 'Entwicklungs-Modus' : 'Scannen Sie den QR-Code\nfür Bürgschaft oder Zahlung.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: textColor,
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.8),
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
