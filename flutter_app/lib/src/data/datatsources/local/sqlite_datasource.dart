// lib/src/data/datatsources/local/sqlite_datasource.dart
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite_common_ffi/sqflite_ffi.dart'
    if (dart.library.html) 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart'
    show databaseFactoryFfiWeb;
import '../../../domain/entities/energy_data.dart';

class SqliteDataSource {
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    if (kIsWeb) {
      // Web: Use in-memory database (IndexedDB under the hood)
      _database = await databaseFactoryFfiWeb.openDatabase(
        'energy.db',
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, version) {
            return db.execute(
              'CREATE TABLE usage (id INTEGER PRIMARY KEY AUTOINCREMENT, timestamp TEXT, watts REAL, applianceId INTEGER DEFAULT 1)',
            );
          },
        ),
      );
    } else {
      // Mobile/Desktop: File-based database
      final path = p.join(await getDatabasesPath(), 'energy.db');
      _database = await openDatabase(
        path,
        version: 1,
        onCreate: (db, version) {
          return db.execute(
            'CREATE TABLE usage (id INTEGER PRIMARY KEY AUTOINCREMENT, timestamp TEXT, watts REAL, applianceId INTEGER DEFAULT 1)',
          );
        },
      );
    }
    return _database!;
  }

  Future<EnergyData> getCurrentEnergy({required int applianceId}) async {
    final db = await database;
    final data = await db.query(
      'usage',
      orderBy: 'timestamp DESC',
      limit: 1,
      where: 'applianceId = ?',
      whereArgs: [applianceId],
    );
    if (data.isNotEmpty) {
      final row = data.first;
      return EnergyData(
        timestamp: row['timestamp'] as String,
        watts: row['watts'] as double,
        applianceId: row['applianceId'] as int,
      );
    }
    throw Exception('No data available');
  }

  Future<List<EnergyData>> getEnergyHistory({required int applianceId}) async {
    final db = await database;
    final data = await db.query(
      'usage',
      orderBy: 'timestamp DESC',
      limit: 24,
      where: 'applianceId = ?',
      whereArgs: [applianceId],
    );
    return data
        .map((row) => EnergyData(
              timestamp: row['timestamp'] as String,
              watts: row['watts'] as double,
              applianceId: row['applianceId'] as int,
            ))
        .toList();
  }

  /// Insert data (for testing)
  Future<void> insertData(EnergyData data) async {
    final db = await database;
    await db.insert(
      'usage',
      {
        'timestamp': data.timestamp,
        'watts': data.watts,
        'applianceId': data.applianceId,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
