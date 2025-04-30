import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:async';
import 'package:flutter/material.dart';

class SqlDb {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    
    // Ensure we have the contribution column
    await _ensureContributionColumn();
    
    return _database!;
  }

  Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), 'skill_monitor.db');
    return openDatabase(
      path,
      version: 2, // Increment version number for the schema change
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE skills (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            skill TEXT NOT NULL,
            score INTEGER DEFAULT 0,
            level INTEGER DEFAULT 1
          )
        ''');

        await db.execute('''
          CREATE TABLE habits (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            skill_id INTEGER NOT NULL,
            name TEXT NOT NULL,
            value INTEGER NOT NULL,
            last_updated TEXT DEFAULT '',
            contribution INTEGER DEFAULT 0,
            FOREIGN KEY(skill_id) REFERENCES skills(id) ON DELETE CASCADE
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Add contribution column if upgrading from version 1
          await db.execute(
            'ALTER TABLE habits ADD COLUMN contribution INTEGER DEFAULT 0'
          );
        }
      },
    );
  }

  /// Ensure the contribution column exists
  Future<void> _ensureContributionColumn() async {
    try {
      // Check if the column exists
      final result = await readData(
        "PRAGMA table_info(habits);",
      );
      
      bool hasContributionColumn = result.any((column) => column['name'] == 'contribution');
      
      if (!hasContributionColumn) {
        // Add the column if it doesn't exist
        await updateData(
          "ALTER TABLE habits ADD COLUMN contribution INTEGER DEFAULT 0",
          [],
        );
        debugPrint('Added contribution column to habits table');
      }
    } catch (e) {
      debugPrint('Error ensuring contribution column: $e');
    }
  }

  /// Raw Insert (unsafe if used directly with user input)
  Future<int> insertRaw(String query) async {
    final db = await database;
    return await db.rawInsert(query);
  }

  /// Safe insert with parameters
  Future<int> insertData(String query, List<dynamic> args) async {
    final db = await database;
    return await db.rawInsert(query, args);
  }

  /// Safe read
  Future<List<Map<String, dynamic>>> readData(String query,
      [List<dynamic>? args]) async {
    final db = await database;
    return await db.rawQuery(query, args);
  }

  /// Safe update
  Future<int> updateData(String query, List<dynamic> args) async {
    final db = await database;
    return await db.rawUpdate(query, args);
  }

  /// Safe delete
  Future<int> deleteData(String query, List<dynamic> args) async {
    final db = await database;
    return await db.rawDelete(query, args);
  }

  /// Update the `last_updated` date for a habit
  Future<int> updateHabitDate(int skillId, String habitName) async {
    final db = await database;
    final date = getCurrentDate();
    debugPrint(
        'Updating habit date for skill $skillId, habit $habitName to $date');

    return await db.update(
      'habits',
      {'last_updated': date},
      where: 'skill_id = ? AND name = ?',
      whereArgs: [skillId, habitName],
    );
  }

  /// Reset habit date
  Future<int> resetHabitDate(int skillId, String habitName) async {
    final db = await database;
    debugPrint('Resetting habit date for skill $skillId, habit $habitName');

    return await db.update(
      'habits',
      {'last_updated': ''},
      where: 'skill_id = ? AND name = ?',
      whereArgs: [skillId, habitName],
    );
  }
  
  /// Update habit contribution value
  Future<int> updateHabitContribution(int skillId, String habitName, int contributionValue) async {
    final db = await database;
    debugPrint('Setting habit contribution for skill $skillId, habit $habitName to $contributionValue');

    return await db.update(
      'habits',
      {'contribution': contributionValue},
      where: 'skill_id = ? AND name = ?',
      whereArgs: [skillId, habitName],
    );
  }

  /// Reset all habit contributions (useful for daily reset)
  Future<void> resetAllContributions() async {
    final db = await database;
    await db.update('habits', {'contribution': 0});
    debugPrint('Reset all habit contributions to 0');
  }

  /// Get current date in YYYY-MM-DD format
  String getCurrentDate() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Optional utility for debugging/testing (clear tables)
  Future<void> resetTables() async {
    final db = await database;
    await db.delete('habits');
    await db.delete('skills');
  }
}