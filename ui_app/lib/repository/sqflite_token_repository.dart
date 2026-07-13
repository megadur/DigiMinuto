import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:path/path.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:core_engine/core_engine.dart';

class SqfliteTokenRepository implements TokenRepository {
  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    // Windows/Linux/Mac requires ffi init
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
      options: OpenDatabaseOptions(
        version: 4,
        onCreate: (db, version) async {
          // Token Tabelle
          await db.execute('''
            CREATE TABLE tokens (
              id TEXT PRIMARY KEY,
              creatorPubKey TEXT NOT NULL,
              amount INTEGER NOT NULL,
              creationYear INTEGER NOT NULL,
              description TEXT NOT NULL,
              guarantor1Signature TEXT,
              guarantor2Signature TEXT,
              status TEXT NOT NULL
            )
          ''');

          // Transaction Tabelle
          await db.execute('''
            CREATE TABLE transactions (
              id TEXT PRIMARY KEY,
              tokenId TEXT NOT NULL,
              senderPubKey TEXT NOT NULL,
              receiverPubKey TEXT NOT NULL,
              timestamp TEXT NOT NULL,
              signature TEXT NOT NULL
            )
          ''');

          // Contacts Tabelle
          await db.execute('''
            CREATE TABLE contacts (
              publicKey TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              portfolio TEXT
            )
          ''');
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            await db.execute('''
              CREATE TABLE contacts (
                publicKey TEXT PRIMARY KEY,
                name TEXT NOT NULL
              )
            ''');
          }
          if (oldVersion < 3) {
            await db.execute('''
              ALTER TABLE tokens ADD COLUMN description TEXT NOT NULL DEFAULT ''
            ''');
          }
          if (oldVersion < 4) {
            await db.execute('''
              ALTER TABLE contacts ADD COLUMN portfolio TEXT
            ''');
          }
        },
      ),
    );
  }

  @override
  Future<Token?> getTokenById(String id) async {
    final db = await database;
    final maps = await db.query(
      'tokens',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Token.fromJson(maps.first);
    }
    return null;
  }

  @override
  Future<List<Token>> getTokensByCreatorAndYear(String creatorPubKey, int year) async {
    final db = await database;
    final maps = await db.query(
      'tokens',
      where: 'creatorPubKey = ? AND creationYear = ?',
      whereArgs: [creatorPubKey, year],
    );

    return maps.map((map) => Token.fromJson(map)).toList();
  }

  @override
  Future<List<Token>> getAllTokens() async {
    final db = await database;
    final maps = await db.query('tokens');
    return maps.map((map) => Token.fromJson(map)).toList();
  }

  @override
  Future<void> saveToken(Token token) async {
    final db = await database;
    await db.insert(
      'tokens',
      token.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
