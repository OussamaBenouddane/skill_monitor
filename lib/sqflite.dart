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
    String path = join(await getDatabasesPath(), 'skill_monitor.db');
    return openDatabase(
      path,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE skills (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            skill TEXT,
            score INTEGER DEFAULT 0,
            level INTEGER DEFAULT 1
          )
        ''');

        await db.execute('''
          CREATE TABLE habits (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            skill_id INTEGER,
            name TEXT,
            value INTEGER,
            last_updated TEXT DEFAULT '', -- Store last updated date for each habit
            FOREIGN KEY(skill_id) REFERENCES skills(id)
          )
        ''');
      },
      version: 1,
    );
  }

  // Insert new skill
  Future<int> insertData(String query) async {
    final db = await database;
    return await db.rawInsert(query);
  }

  // Read data
  Future<List<Map<String, dynamic>>> readData(String query) async {
    final db = await database;
    return await db.rawQuery(query);
  }

  // Update data
  Future<int> updateData(String query) async {
    final db = await database;
    return await db.rawUpdate(query);
  }

  // Delete data
  Future<int> deleteData(String query) async {
    final db = await database;
    return await db.rawDelete(query);
  }

  // Update the `last_updated` date for a habit
  Future<int> updateHabitDate(int skillId, String habitName) async {
    final db = await database;
    final date = getCurrentDate();
    debugPrint('Updating habit date for skill $skillId, habit $habitName to $date');
    
    return await db.update(
      'habits',
      {'last_updated': date},
      where: 'skill_id = ? AND name = ?',
      whereArgs: [skillId, habitName],
    );
  }

  // Get the current date as a string (YYYY-MM-DD)
  String getCurrentDate() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}