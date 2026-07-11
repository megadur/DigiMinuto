import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:core_engine/core_engine.dart';

class SecureIdentityRepository {
  final _secureStorage = const FlutterSecureStorage();
  static const _privKey = 'private_key';
  static const _pubKey = 'public_key';
  static const _nameKey = 'user_name';

  Future<Identity?> loadIdentity() async {
    final prefs = await SharedPreferences.getInstance();
    
    final publicKeyStr = await _secureStorage.read(key: _pubKey);
    final privateKeyStr = await _secureStorage.read(key: _privKey);
    final name = prefs.getString(_nameKey) ?? 'Unbekannt';

    if (publicKeyStr != null && privateKeyStr != null) {
      return Identity(
        publicKey: publicKeyStr,
        privateKey: privateKeyStr,
        name: name,
      );
    }
    return null;
  }

  Future<void> saveIdentity(Identity identity) async {
    final prefs = await SharedPreferences.getInstance();
    
    await _secureStorage.write(key: _pubKey, value: identity.publicKey);
    if (identity.privateKey != null) {
      await _secureStorage.write(key: _privKey, value: identity.privateKey!);
    }
    await prefs.setString(_nameKey, identity.name ?? 'Unbekannt');
  }

  Future<void> clearIdentity() async {
    final prefs = await SharedPreferences.getInstance();
    await _secureStorage.delete(key: _pubKey);
    await _secureStorage.delete(key: _privKey);
    await prefs.remove(_nameKey);
  }
}
