import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../models/identity.dart';
import '../models/token.dart';
import '../crypto/crypto_service.dart';
import '../repository/token_repository.dart';

class LedgerException implements Exception {
  final String message;
  LedgerException(this.message);
  @override
  String toString() => 'LedgerException: $message';
}

class LedgerService {
  static const int maxMinutosPerYear = 1800;

  final TokenRepository _tokenRepository;
  final CryptoService _cryptoService;

  LedgerService(this._tokenRepository, this._cryptoService);

  /// Erstellt das Payload-Format, das von Bürgen signiert werden muss.
  String _getTokenPayloadForSignature(Token token) {
    return "${token.id}:${token.creatorPubKey}:${token.amount}:${token.creationYear}";
  }

  /// Initialisiert die Schöpfung eines neuen Tokens (Gutscheins).
  /// Prüft das Hard-Cap Limit (max 1800 Minutos pro Jahr).
  Future<Token> createToken({
    required Identity creator,
    required int amount,
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

    // Erzeuge eine eindeutige ID (Hash aus Creator + Timestamp + Random/Amount)
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final bytes = utf8.encode("${creator.publicKey}:$timestamp:$amount");
    final tokenId = sha256.convert(bytes).toString();

    final token = Token(
      id: tokenId,
      creatorPubKey: creator.publicKey,
      amount: amount,
      creationYear: currentYear,
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
}
