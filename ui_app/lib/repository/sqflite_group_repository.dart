import 'package:sqflite/sqflite.dart' hide Transaction;
import 'package:sqflite_common_ffi/sqflite_ffi.dart' hide Transaction;
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:path/path.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:core_engine/core_engine.dart';

class SqfliteGroupRepository implements GroupRepository {
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
      // Die eigentliche Struktur wird im SqfliteTokenRepository angelegt (version 5)
    );
  }

  @override
  Future<void> saveGroup(GroupMembership group) async {
    final db = await database;
    await db.insert(
      'groups',
      group.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<GroupMembership>> getAllGroups() async {
    final db = await database;
    // Check if table exists because we share the DB file with TokenRepository
    // TokenRepository might not have upgraded it to v5 yet if it wasn't accessed.
    var result = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='groups'");
    if (result.isEmpty) return [];

    final maps = await db.query(
      'groups',
      orderBy: 'timestamp DESC',
    );

    return maps.map((map) => GroupMembership.fromMap(map)).toList();
  }

  @override
  Future<void> deleteGroup(String groupId) async {
    final db = await database;
    await db.delete(
      'groups',
      where: 'groupId = ?',
      whereArgs: [groupId],
    );
  }
}
