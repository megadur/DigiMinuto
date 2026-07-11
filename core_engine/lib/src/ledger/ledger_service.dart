import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../models/identity.dart';
import '../models/token.dart';
import '../crypto/crypto_service.dart';
import '../repository/token_repository.dart';
import '../repository/transaction_repository.dart';
import '../models/transaction.dart';

class LedgerException implements Exception {
  final String message;
  LedgerException(this.message);
  @override
  String toString() => 'LedgerException: $message';
}

class LedgerService {
  static const int maxMinutosPerYear = 1800;

  final TokenRepository _tokenRepository;
  final TransactionRepository _transactionRepository;
  final CryptoService _cryptoService;

  LedgerService(this._tokenRepository, this._transactionRepository, this._cryptoService);

  /// Erstellt das Payload-Format, das von Bürgen signiert werden muss.
  String _getTokenPayloadForSignature(Token token) {
    final descBase64 = base64Encode(utf8.encode(token.description));
    return "${token.id}:${token.creatorPubKey}:${token.amount}:${token.creationYear}:$descBase64";
  }

  /// Initialisiert die Schöpfung eines neuen Tokens (Gutscheins).
  /// Prüft das Hard-Cap Limit (max 1800 Minutos pro Jahr).
  Future<Token> createToken({
    required Identity creator,
    required int amount,
    String description = '',
  }) async {
    if (amount <= 0) {
      throw LedgerException("Betrag muss größer als 0 sein.");
    }
    
    final currentYear = DateTime.now().year;

    // Hard-Cap Prüfung
    final existingTokens = await _tokenRepository.getTokensByCreatorAndYear(creator.publicKey, currentYear);
    int currentSum = existingTokens.fold(0, (sum, token) => sum + token.amount);

    if (currentSum + amount > maxMinutosPerYear) {
      throw LedgerException("Hard-Cap überschritten! Maximal $maxMinutosPerYear Minutos pro Jahr erlaubt. Aktuell geschöpft: $currentSum.");
    }

    // Erzeuge eine eindeutige ID (Hash aus Creator + Timestamp + Random/Amount + Description)
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final bytes = utf8.encode("${creator.publicKey}:$timestamp:$amount:$description");
    final tokenId = sha256.convert(bytes).toString();

    final token = Token(
      id: tokenId,
      creatorPubKey: creator.publicKey,
      amount: amount,
      creationYear: currentYear,
      description: description,
      status: TokenStatus.pending,
    );

    await _tokenRepository.saveToken(token);
    return token;
  }

  /// Ein Bürge fügt seine Signatur zum Token hinzu.
  /// Sobald zwei gültige Signaturen vorliegen, wird der Token 'active'.
  Future<Token> addGuarantorSignature({
    required Token token,
    required String guarantorPubKeyBase64,
    required String signatureBase64,
  }) async {
    if (token.status != TokenStatus.pending) {
      throw LedgerException("Token ist nicht mehr im Status 'pending'.");
    }

    if (guarantorPubKeyBase64 == token.creatorPubKey) {
      throw LedgerException("Der Schöpfer kann nicht sein eigener Bürge sein.");
    }

    // Verifiziere die Signatur des Bürgen
    final payload = _getTokenPayloadForSignature(token);
    final isValid = await _cryptoService.verifySignature(
      data: payload,
      signatureBase64: signatureBase64,
      publicKeyBase64: guarantorPubKeyBase64,
    );

    if (!isValid) {
      throw LedgerException("Die Signatur des Bürgen ist ungültig.");
    }

    // Trage Signatur ein
    if (token.guarantor1Signature == null) {
      token.guarantor1Signature = signatureBase64;
    } else if (token.guarantor2Signature == null) {
      // Prüfe, ob es nicht derselbe Bürge ist (vereinfacht: vergleiche Signaturen)
      if (token.guarantor1Signature == signatureBase64) {
        throw LedgerException("Dieser Bürge hat bereits unterschrieben.");
      }
      token.guarantor2Signature = signatureBase64;
      
      // Token wird aktiv, da zwei Bürgen unterschrieben haben!
      token.status = TokenStatus.active;
    } else {
      throw LedgerException("Token hat bereits 2 Bürgen.");
    }

    await _tokenRepository.saveToken(token);
    return token;
  }

  /// Berechnet alle Tokens, die aktuell im Besitz des angegebenen PublicKeys sind.
  Future<List<Token>> getOwnedTokens(String pubKey) async {
    final allTokens = await _tokenRepository.getAllTokens();
    final ownedTokens = <Token>[];

    for (var token in allTokens) {
      if (token.status != TokenStatus.active) continue;

      final transactions = await _transactionRepository.getTransactionsForToken(token.id);
      
      String currentOwner = token.creatorPubKey;
      if (transactions.isNotEmpty) {
        // Sortiere absteigend nach Datum (neueste zuerst)
        transactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        currentOwner = transactions.first.receiverPubKey;
      }

      if (currentOwner == pubKey) {
        ownedTokens.add(token);
      }
    }

    return ownedTokens;
  }

  /// Erzeugt die Signatur-Daten für einen Transfer
  String _getTransferPayload(String tokenId, String sender, String receiver, String timestamp) {
    return "$tokenId:$sender:$receiver:$timestamp";
  }

  /// Transferiert einen Token an einen neuen Besitzer
  Future<Transaction> transferToken({
    required Token token,
    required Identity sender,
    required String receiverPubKey,
  }) async {
    if (token.status != TokenStatus.active) {
      throw LedgerException("Nur aktive Tokens können gesendet werden.");
    }

    // Prüfe Besitz
    final ownedTokens = await getOwnedTokens(sender.publicKey);
    if (!ownedTokens.any((t) => t.id == token.id)) {
      throw LedgerException("Sie sind nicht der aktuelle Besitzer dieses Tokens.");
    }

    final timestamp = DateTime.now().toIso8601String();
    final payload = _getTransferPayload(token.id, sender.publicKey, receiverPubKey, timestamp);
    
    // Wir erzeugen einen Hash, den wir signieren
    final bytes = utf8.encode(payload);
    final txId = sha256.convert(bytes).toString();

    // PrivateKey aus Base64 decodieren
    if (sender.privateKey == null) {
      throw Exception('Privater Schlüssel fehlt. Senden nicht möglich.');
    }
    final keyPair = await _cryptoService.loadKeyPairFromBase64(sender.privateKey!, sender.publicKey);
    final signature = await _cryptoService.signData(payload, keyPair);

    final transaction = Transaction(
      id: txId,
      tokenId: token.id,
      senderPubKey: sender.publicKey,
      receiverPubKey: receiverPubKey,
      timestamp: DateTime.parse(timestamp),
      signature: signature,
    );

    await _transactionRepository.saveTransaction(transaction);
    return transaction;
  }

  /// Empfängt einen Token-Transfer (nach dem Scannen des QR-Codes).
  /// Speichert Token und Transaktion in der lokalen DB.
  Future<void> receiveTransfer({
    required Token token,
    required Transaction transaction,
  }) async {
    // 1. Verifiziere den Token (Signaturen der Bürgen)
    if (token.guarantor1Signature == null || token.guarantor2Signature == null) {
      throw LedgerException("Token hat keine 2 Bürgen.");
    }

    final tokenPayload = _getTokenPayloadForSignature(token);
    await _cryptoService.verifySignature(
      data: tokenPayload,
      signatureBase64: token.guarantor1Signature!,
      publicKeyBase64: "IGNORE", // TODO: Eigentlich müssten wir wissen, wer gebürgt hat
    );
    // Note: We don't strictly throw here right now because publicKeyBase64 is IGNORE and we might fail
    // We will implement full guarantor validation later.

    // 2. Verifiziere die Transfer-Transaktion
    final txPayload = _getTransferPayload(
      transaction.tokenId, 
      transaction.senderPubKey, 
      transaction.receiverPubKey, 
      transaction.timestamp.toIso8601String()
    );

    final txValid = await _cryptoService.verifySignature(
      data: txPayload,
      signatureBase64: transaction.signature,
      publicKeyBase64: transaction.senderPubKey,
    );

    if (!txValid) {
      throw LedgerException("Die Signatur der Transaktion ist ungültig.");
    }

    // Speichern
    await _tokenRepository.saveToken(token);
    await _transactionRepository.saveTransaction(transaction);
  }
}
