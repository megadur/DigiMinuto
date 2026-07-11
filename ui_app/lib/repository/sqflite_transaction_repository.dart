import 'package:sqflite/sqflite.dart' hide Transaction;
import 'package:sqflite_common_ffi/sqflite_ffi.dart' hide Transaction;
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:path/path.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:core_engine/core_engine.dart';

class SqfliteTransactionRepository implements TransactionRepository {
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
      options: OpenDatabaseOptions(version: 1),
    );
  }

  @override
  Future<void> saveTransaction(Transaction transaction) async {
    final db = await database;
    await db.insert(
      'transactions',
      transaction.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<Transaction>> getTransactionsForToken(String tokenId) async {
    final db = await database;
    final maps = await db.query(
      'transactions',
      where: 'tokenId = ?',
      whereArgs: [tokenId],
      orderBy: 'timestamp ASC',
    );

    return maps.map((map) => Transaction.fromJson(map)).toList();
  }

  @override
  Future<List<Transaction>> getAllTransactions() async {
    final db = await database;
    final maps = await db.query(
      'transactions',
      orderBy: 'timestamp DESC',
    );

    return maps.map((map) => Transaction.fromJson(map)).toList();
  }
}
