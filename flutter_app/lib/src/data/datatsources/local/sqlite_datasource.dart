import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // Added
import '../../../domain/entities/energy_data.dart';

class SqliteDataSource {
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    if (kIsWeb) {
      _database = await openDatabase(inMemoryDatabasePath, version: 1,
          onCreate: (db, version) {
        db.execute(
            'CREATE TABLE usage (timestamp TEXT, watts REAL, applianceId INTEGER)');
      });
    } else {
      final path = p.join(await getDatabasesPath(), 'energy.db');
      _database = await openDatabase(path, version: 1, onCreate: (db, version) {
        db.execute(
            'CREATE TABLE usage (timestamp TEXT, watts REAL, applianceId INTEGER)');
      });
    }
    return _database!;
  }

  Future<EnergyData> getCurrentEnergy({required int applianceId}) async {
    final db = await database;
    final data = await db.query('usage',
        orderBy: 'timestamp DESC',
        limit: 1,
        where: 'applianceId = ?',
        whereArgs: [applianceId]);
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
    final data = await db.query('usage', orderBy: 'timestamp DESC', limit: 24);
    return data
        .map((row) => EnergyData(
              timestamp: row['timestamp'] as String,
              watts: row['watts'] as double,
              applianceId: row['applianceId'] as int,
            ))
        .toList();
  }
}
