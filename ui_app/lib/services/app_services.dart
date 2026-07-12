import 'dart:convert';
import 'package:core_engine/core_engine.dart';
import '../repository/secure_identity_repository.dart';
import '../repository/sqflite_token_repository.dart';
import '../repository/sqflite_transaction_repository.dart';
import '../repository/sqflite_contact_repository.dart';

class AppServices {
  static final AppServices instance = AppServices._internal();
  
  AppServices._internal();

  late final CryptoService cryptoService;
  late final SecureIdentityRepository identityRepository;
  late final SqfliteTokenRepository tokenRepository;
  late final SqfliteTransactionRepository transactionRepository;
  late final SqfliteContactRepository contactRepository;
  late final LedgerService ledgerService;
  late final NostrService nostrService;
  
  late Identity currentIdentity;

  Future<void> init() async {
    cryptoService = CryptoService();
    identityRepository = SecureIdentityRepository();
    tokenRepository = SqfliteTokenRepository();
    transactionRepository = SqfliteTransactionRepository();
    contactRepository = SqfliteContactRepository();
    ledgerService = LedgerService(tokenRepository, transactionRepository, cryptoService);
    nostrService = NostrService();

    // Identität laden oder neu generieren
    var identity = await identityRepository.loadIdentity();
    
    // Migration: Wenn der PublicKey kein Hex-String mit 64 Zeichen ist (altes Ed25519 Base64 Format), 
    // dann löschen wir die alte Identität und generieren eine neue für Nostr (secp256k1).
    if (identity != null && identity.publicKey.length != 64) {
      // In einer echten App müssten wir hier vorsichtiger sein, aber für die Testphase löschen wir einfach.
      // (Besser wäre es, die tokens.db auch zu leeren, wir lassen es hier der Einfachheit halber mal so).
      identity = null; 
    }

    if (identity == null) {
      final keyPair = await cryptoService.generateKeyPair();
      final pubKey = await cryptoService.getPublicKeyHex(keyPair);
      
      identity = Identity(
        publicKey: pubKey,
        privateKey: keyPair.private,
        name: 'Mein DigiMinuto',
      );
      await identityRepository.saveIdentity(identity);
    }
    currentIdentity = identity;

    // Nostr im Hintergrund verbinden
    nostrService.connect();
  }
}
