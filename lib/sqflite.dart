import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:async';
import 'package:flutter/material.dart';

class SqlDb {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), 'skill_monitor.db');
    return openDatabase(
      path,
      version: 1,
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
            FOREIGN KEY(skill_id) REFERENCES skills(id) ON DELETE CASCADE
          )
        ''');
      },
    );
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
