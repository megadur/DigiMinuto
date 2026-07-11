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
  
  late Identity currentIdentity;

  Future<void> init() async {
    cryptoService = CryptoService();
    identityRepository = SecureIdentityRepository();
    tokenRepository = SqfliteTokenRepository();
    transactionRepository = SqfliteTransactionRepository();
    contactRepository = SqfliteContactRepository();
    ledgerService = LedgerService(tokenRepository, transactionRepository, cryptoService);

    // Identität laden oder neu generieren
    var identity = await identityRepository.loadIdentity();
    if (identity == null) {
      final keyPair = await cryptoService.generateKeyPair();
      final pubKey = await cryptoService.getPublicKeyBase64(keyPair);
      final privBytes = await keyPair.extractPrivateKeyBytes();
      
      identity = Identity(
        publicKey: pubKey,
        privateKey: base64Encode(privBytes),
        name: 'Mein DigiMinuto',
      );
      await identityRepository.saveIdentity(identity);
    }
    currentIdentity = identity;
  }
}
