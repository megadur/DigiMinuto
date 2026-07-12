import 'package:test/test.dart';
import 'package:core_engine/src/models/identity.dart';
import 'package:core_engine/src/models/token.dart';
import 'package:core_engine/src/crypto/crypto_service.dart';
import 'package:core_engine/src/ledger/ledger_service.dart';
import 'package:core_engine/src/repository/token_repository.dart';
import 'package:core_engine/src/repository/transaction_repository.dart';
import 'package:core_engine/src/models/transaction.dart';
import 'dart:convert';

class InMemoryTokenRepository implements TokenRepository {
  final Map<String, Token> _tokens = {};

  @override
  Future<Token?> getTokenById(String id) async {
    return _tokens[id];
  }

  @override
  Future<List<Token>> getAllTokens() async {
    return _tokens.values.toList();
  }

  @override
  Future<List<Token>> getTokensByCreatorAndYear(String creatorPubKey, int year) async {
    return _tokens.values.where((t) => t.creatorPubKey == creatorPubKey && t.creationYear == year).toList();
  }

  @override
  Future<void> saveToken(Token token) async {
    _tokens[token.id] = token;
  }
}

class InMemoryTransactionRepository implements TransactionRepository {
  final List<Transaction> _transactions = [];

  @override
  Future<void> saveTransaction(Transaction transaction) async {
    _transactions.add(transaction);
  }

  @override
  Future<List<Transaction>> getTransactionsForToken(String tokenId) async {
    return _transactions.where((t) => t.tokenId == tokenId).toList();
  }

  @override
  Future<List<Transaction>> getAllTransactions() async {
    return _transactions;
  }
}

void main() {
  late CryptoService cryptoService;
  late TokenRepository repository;
  late TransactionRepository txRepository;
  late LedgerService ledger;

  setUp(() {
    cryptoService = CryptoService();
    repository = InMemoryTokenRepository();
    txRepository = InMemoryTransactionRepository();
    ledger = LedgerService(repository, txRepository, cryptoService);
  });

  test('Token Schöpfung unter Limit erfolgreich', () async {
    final creator = Identity(publicKey: 'pub1', privateKey: 'priv1');
    final token = await ledger.createToken(creator: creator, amount: 500);

    expect(token.amount, 500);
    expect(token.status, TokenStatus.pending);
    expect(token.creatorPubKey, 'pub1');
  });

  test('Token Schöpfung über 1800 Minutos (Hard Cap) schlägt fehl', () async {
    final creator = Identity(publicKey: 'pub1', privateKey: 'priv1');
    
    // Erste Schöpfung: 1500 (sollte klappen)
    await ledger.createToken(creator: creator, amount: 1500);

    // Zweite Schöpfung: 400 (sollte fehlschlagen, da 1500 + 400 > 1800)
    expect(
      () => ledger.createToken(creator: creator, amount: 400),
      throwsA(isA<LedgerException>()),
    );
  });

  test('2-Bürgen-Regel aktiviert Token', () async {
    final creatorKeyPair = await cryptoService.generateKeyPair();
    final creatorPubHex = await cryptoService.getPublicKeyHex(creatorKeyPair);
    final creator = Identity(publicKey: creatorPubHex, privateKey: 'hidden');

    final token = await ledger.createToken(creator: creator, amount: 100);

    // Bürge 1
    final g1KeyPair = await cryptoService.generateKeyPair();
    final g1PubHex = await cryptoService.getPublicKeyHex(g1KeyPair);
    final descBase64 = base64Encode(utf8.encode(token.description));
    final payload = "${token.id}:${token.creatorPubKey}:${token.amount}:${token.creationYear}:$descBase64";
    final sig1 = await cryptoService.signData(payload, g1KeyPair);

    await ledger.addGuarantorSignature(
      token: token,
      guarantorPubKeyHex: g1PubHex,
      signatureHex: sig1,
    );

    expect(token.status, TokenStatus.pending);

    // Bürge 2
    final g2KeyPair = await cryptoService.generateKeyPair();
    final g2PubHex = await cryptoService.getPublicKeyHex(g2KeyPair);
    final sig2 = await cryptoService.signData(payload, g2KeyPair);

    await ledger.addGuarantorSignature(
      token: token,
      guarantorPubKeyHex: g2PubHex,
      signatureHex: sig2,
    );

    // Nach 2 Bürgen muss der Token aktiv sein
    expect(token.status, TokenStatus.active);
  });
}
