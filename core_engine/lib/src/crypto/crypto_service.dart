import 'dart:convert';
import 'package:dart_nostr/dart_nostr.dart';
import 'package:crypto/crypto.dart';

class CryptoService {
  /// Generiert ein neues asymmetrisches Schlüsselpaar (Identity).
  Future<NostrKeyPairs> generateKeyPair() async {
    return Nostr.instance.keys.generateKeyPair();
  }

  /// Extrahiert den Public Key als Hex-String aus einem KeyPair.
  Future<String> getPublicKeyHex(NostrKeyPairs keyPair) async {
    return keyPair.public;
  }

  /// Hasht die Nachricht (SHA256) und signiert sie mit Schnorr (Nostr Standard).
  /// Gibt die Signatur als Hex-String zurück.
  Future<String> signData(String data, NostrKeyPairs keyPair) async {
    final bytes = utf8.encode(data);
    final hash = sha256.convert(bytes).toString(); // Hex of SHA256
    
    return Nostr.instance.keys.sign(
      privateKey: keyPair.private,
      message: hash,
    );
  }

  /// Rekonstruiert ein KeyPair aus Hex-Strings.
  Future<NostrKeyPairs> loadKeyPairFromHex(String privateKeyHex, String publicKeyHex) async {
    return NostrKeyPairs(
      private: privateKeyHex,
    );
  }

  /// Verifiziert eine Schnorr-Signatur.
  Future<bool> verifySignature({
    required String data,
    required String signatureHex,
    required String publicKeyHex,
  }) async {
    try {
      final bytes = utf8.encode(data);
      final hash = sha256.convert(bytes).toString();
      
      return Nostr.instance.keys.verify(
        publicKey: publicKeyHex,
        message: hash,
        signature: signatureHex,
      );
    } catch (e) {
      return false;
    }
  }
}
