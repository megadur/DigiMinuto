import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../models/transaction.dart';
import '../models/token.dart';

/// Adapter zur Konvertierung unserer lokalen Modelle in Nostr-kompatible Events.
/// Nostr verwendet standardmäßig "Events" als Grundbaustein für jegliche Kommunikation.
class NostrAdapter {
  // Eigene "Kind" (Typ) Identifikatoren im Nostr-Netzwerk für DigiMinuto
  static const int kindTokenCreation = 31000;
  static const int kindTokenTransaction = 31001;

  /// Konvertiert eine DigiMinuto Transaktion in ein Nostr Event.
  Map<String, dynamic> transactionToNostrEvent(Transaction tx) {
    // Nostr Events verlangen einen sha256 Hash über ein serialisiertes JSON-Array
    // [0, pubkey, created_at, kind, tags, content]
    
    final createdAt = tx.timestamp.millisecondsSinceEpoch ~/ 1000; // Unix Timestamp in Sekunden
    final content = jsonEncode({
      'tokenId': tx.tokenId,
      'amount': 1, // Da wir 1 Minuto = 1 Token haben, oder Teilbarkeit ignorieren
    });

    final tags = [
      ['p', tx.receiverPubKey], // 'p' = Public Key Empfänger
      ['e', tx.tokenId] // 'e' = Referenz auf den ursprünglichen Token
    ];

    // Wir erstellen den Hash so, wie Nostr es erwartet
    final serializedForHash = jsonEncode([
      0,
      tx.senderPubKey,
      createdAt,
      kindTokenTransaction,
      tags,
      content
    ]);
    
    final idHash = sha256.convert(utf8.encode(serializedForHash)).toString();

    return {
      'id': idHash,
      'pubkey': tx.senderPubKey,
      'created_at': createdAt,
      'kind': kindTokenTransaction,
      'tags': tags,
      'content': content,
      'sig': tx.signature, // Die Signatur aus unserem CryptoService
    };
  }

  /// Konvertiert einen neu geschöpften und von 2 Bürgen signierten Token in ein Nostr Event.
  Map<String, dynamic> tokenToNostrEvent(Token token) {
    if (token.guarantor1Signature == null || token.guarantor2Signature == null) {
      throw Exception("Token hat noch keine 2 Bürgen und darf nicht gebroadcastet werden.");
    }

    final createdAt = DateTime(token.creationYear).millisecondsSinceEpoch ~/ 1000;
    
    final content = jsonEncode({
      'amount': token.amount,
      'guarantor1': token.guarantor1Signature,
      'guarantor2': token.guarantor2Signature,
    });

    final tags = [
      ['t', 'digiminuto'] // Custom tag für einfache Relay-Suche
    ];

    final serializedForHash = jsonEncode([
      0,
      token.creatorPubKey,
      createdAt,
      kindTokenCreation,
      tags,
      content
    ]);
    
    final idHash = sha256.convert(utf8.encode(serializedForHash)).toString();

    return {
      'id': idHash,
      'pubkey': token.creatorPubKey,
      'created_at': createdAt,
      'kind': kindTokenCreation,
      'tags': tags,
      'content': content,
      // Hinweis: Nostr erfordert hier eine Signatur des Creators über den Event-Hash.
      // Da wir in Phase 1 nur die Bürgen signieren ließen, würde hier das CryptoService
      // noch einmal den Creator signieren lassen.
      'sig': '', 
    };
  }
}
