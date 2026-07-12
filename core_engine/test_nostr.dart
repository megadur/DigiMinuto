import 'package:dart_nostr/dart_nostr.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

void main() {
  final keys = Nostr.instance.keys.generateKeyPair();
  print('Pub: ${keys.public}');
  print('Priv: ${keys.private}');
  
  final data = "test message";
  final bytes = utf8.encode(data);
  final hash = sha256.convert(bytes).toString();
  
  final sig = Nostr.instance.keys.sign(
    privateKey: keys.private,
    message: hash,
  );
  print('Sig: $sig');
  
  final isValid = Nostr.instance.keys.verify(
    publicKey: keys.public,
    message: hash,
    signature: sig,
  );
  print('IsValid: $isValid');
}
