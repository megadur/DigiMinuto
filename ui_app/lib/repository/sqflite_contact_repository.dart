import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:path/path.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:core_engine/core_engine.dart';

class SqfliteContactRepository implements ContactRepository {
  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'digiminuto_ledger.db');

    return await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(version: 2), // schema is managed in token repo
    );
  }

  @override
  Future<void> saveContact(Contact contact) async {
    final db = await database;
    await db.insert(
      'contacts',
      contact.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<Contact?> getContactByPublicKey(String publicKey) async {
    final db = await database;
    final maps = await db.query(
      'contacts',
      where: 'publicKey = ?',
      whereArgs: [publicKey],
    );

    if (maps.isNotEmpty) {
      return Contact.fromJson(maps.first);
    }
    return null;
  }

  @override
  Future<List<Contact>> getAllContacts() async {
    final db = await database;
    final maps = await db.query('contacts', orderBy: 'name ASC');
    return maps.map((map) => Contact.fromJson(map)).toList();
  }

  @override
  Future<void> deleteContact(String publicKey) async {
    final db = await database;
    await db.delete(
      'contacts',
      where: 'publicKey = ?',
      whereArgs: [publicKey],
    );
  }
}
