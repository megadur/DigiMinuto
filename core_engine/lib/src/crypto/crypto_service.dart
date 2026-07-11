import 'dart:convert';
import 'package:cryptography/cryptography.dart';

class CryptoService {
  // Wir verwenden Ed25519, da es der Standard für schnelle und sichere digitale Signaturen ist (wird auch von Nostr verwendet).
  final Ed25519 _algorithm = Ed25519();

  /// Generiert ein neues asymmetrisches Schlüsselpaar (Identity).
  Future<SimpleKeyPair> generateKeyPair() async {
    return await _algorithm.newKeyPair();
  }

  /// Extrahiert den Public Key als Base64-String aus einem KeyPair.
  Future<String> getPublicKeyBase64(SimpleKeyPair keyPair) async {
    final publicKey = await keyPair.extractPublicKey();
    return base64Encode(publicKey.bytes);
  }

  /// Signiert beliebige Text-Daten mit einem privaten Schlüssel.
  /// Gibt die Signatur als Base64-kodierten String zurück.
  Future<String> signData(String data, SimpleKeyPair keyPair) async {
    final message = utf8.encode(data);
    final signature = await _algorithm.sign(
      message,
      keyPair: keyPair,
    );
    return base64Encode(signature.bytes);
  }

  /// Rekonstruiert ein SimpleKeyPair aus Base64-Strings.
  Future<SimpleKeyPair> loadKeyPairFromBase64(String privateKeyBase64, String publicKeyBase64) async {
    final privBytes = base64Decode(privateKeyBase64);
    final pubBytes = base64Decode(publicKeyBase64);
    return SimpleKeyPairData(
      privBytes,
      publicKey: SimplePublicKey(pubBytes, type: KeyPairType.ed25519),
      type: KeyPairType.ed25519,
    );
  }

  /// Verifiziert eine Signatur anhand der Originaldaten und des Public Keys.
  Future<bool> verifySignature({
    required String data,
    required String signatureBase64,
    required String publicKeyBase64,
  }) async {
    try {
      final message = utf8.encode(data);
      final signatureBytes = base64Decode(signatureBase64);
      final publicKeyBytes = base64Decode(publicKeyBase64);

      final publicKey = SimplePublicKey(
        publicKeyBytes,
        type: KeyPairType.ed25519,
      );

      final signature = Signature(
        signatureBytes,
        publicKey: publicKey,
      );

      return await _algorithm.verify(
        message,
        signature: signature,
      );
    } catch (e) {
      // Wenn die Dekodierung fehlschlägt (z.B. ungültiges Base64), ist die Signatur definitiv ungültig.
      return false;
    }
  }
}
