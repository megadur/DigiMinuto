import '../models/token.dart';

abstract class TokenRepository {
  /// Holt alle Tokens, die ein spezifischer Nutzer in einem bestimmten Jahr geschöpft hat.
  Future<List<Token>> getTokensByCreatorAndYear(String creatorPubKey, int year);

  /// Findet einen Token anhand seiner ID.
  Future<Token?> getTokenById(String id);

  /// Speichert oder aktualisiert einen Token in der Datenbank.
  Future<void> saveToken(Token token);
}
