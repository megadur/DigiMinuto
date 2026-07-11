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
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'QR-Code scannen',
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
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
                    const Icon(Icons.no_photography, color: Colors.white54, size: 64),
                    const SizedBox(height: 20),
                    Text(
                      'Kamera-Scanner wird auf Windows nicht unterstützt.\n(Bitte nutzen Sie später ein Android/iOS Gerät).',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(color: Colors.white70, fontSize: 16),
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      icon: const Icon(Icons.qr_code, color: Colors.white),
                      label: Text('Erfolgreichen Scan simulieren', style: GoogleFonts.inter(color: Colors.white)),
                      onPressed: () {
                        // Wir simulieren hier einfach das Einlesen eines Gutscheins
                        Navigator.of(context).pop("digiminuto:guarantee:test1234:simulatedPubKey:100:2026");
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
                  color: Colors.white,
                  backgroundColor: Colors.black54,
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
