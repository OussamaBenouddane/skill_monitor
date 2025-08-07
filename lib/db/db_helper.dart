import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../model/composite_model.dart';
import '../model/habit_model.dart';
import '../model/skill_model.dart';

class SqlDb {
  // Singleton pattern
  static final SqlDb _instance = SqlDb._internal();
  factory SqlDb() => _instance;
  SqlDb._internal();

  static Database? _db;

  Future<Database> get db async {
    _db ??= await _initializeDb();
    return _db!;
  }

  Future<Database> _initializeDb() async {
    String dataBasePath = await getDatabasesPath();
    String path = join(dataBasePath, "skill_monitor.db");

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onOpen: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE skills (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        skill TEXT NOT NULL UNIQUE,
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
  }

  /// Fetch all skills and their habits in one query, sorted by level (masters last)
  Future<List<SkillWithHabits>> getAllSkillsWithHabits() async {
    final db = await this.db;

    final results = await db.rawQuery('''
      SELECT skills.id as skill_id, skills.skill, skills.score, skills.level,
             habits.id as habit_id, habits.name, habits.value, habits.last_updated
      FROM skills
      LEFT JOIN habits ON skills.id = habits.skill_id
      ORDER BY CASE WHEN skills.level = 10 THEN 1 ELSE 0 END, skills.id
    ''');

    final Map<int, SkillWithHabits> skillMap = {};

    for (var row in results) {
      final skillId = row['skill_id'] as int;

      skillMap.putIfAbsent(skillId, () {
        return SkillWithHabits(
          skill: Skill(
            id: skillId,
            skill: row['skill'] as String,
            score: row['score'] as int,
            level: row['level'] as int,
          ),
          habits: [],
        );
      });

      if (row['habit_id'] != null) {
        skillMap[skillId]!.habits.add(
          Habit(
            id: row['habit_id'] as int,
            skillId: skillId,
            name: row['name'] as String,
            value: row['value'] as int,
            lastUpdated: row['last_updated'] as String? ?? '',
          ),
        );
      }
    }

    return skillMap.values.toList();
  }

  /// Fetch only habits for a specific skill
  Future<List<Habit>> getHabitsBySkillId(int skillId) async {
    final db = await this.db;
    final habitMaps = await db.query(
      'habits',
      where: 'skill_id = ?',
      whereArgs: [skillId],
    );
    return habitMaps.map((e) => Habit.fromMap(e)).toList();
  }

  /// Get habits that were completed on a specific date
  Future<List<Habit>> getCompletedHabitsForDate(String date) async {
    final db = await this.db;
    final habitMaps = await db.query(
      'habits',
      where: 'last_updated = ?',
      whereArgs: [date],
    );
    return habitMaps.map((e) => Habit.fromMap(e)).toList();
  }

  /// Reset all habits (clear last_updated)
  Future<int> resetAllHabits() async {
    final db = await this.db;
    return await db.update('habits', {'last_updated': ''});
  }

  /// Reset habits for specific skill
  Future<int> resetHabitsForSkill(int skillId) async {
    final db = await this.db;
    return await db.update(
      'habits',
      {'last_updated': ''},
      where: 'skill_id = ?',
      whereArgs: [skillId],
    );
  }

  /// Batch update multiple habits (more efficient for daily reset operations)
  Future<void> batchUpdateHabits(List<Habit> habits) async {
    final db = await this.db;
    final batch = db.batch();

    for (var habit in habits) {
      batch.update(
        'habits',
        habit.toMap(),
        where: 'id = ?',
        whereArgs: [habit.id],
      );
    }

    await batch.commit(noResult: true);
  }

  /// Batch update multiple skills (more efficient for score/level updates)
  Future<void> batchUpdateSkills(List<Skill> skills) async {
    final db = await this.db;
    final batch = db.batch();

    for (var skill in skills) {
      batch.update(
        'skills',
        skill.toMap(),
        where: 'id = ?',
        whereArgs: [skill.id],
      );
    }

    await batch.commit(noResult: true);
  }

  Future<int> deleteHabit(int habitId) async {
    final db = await this.db;
    return await db.delete('habits', where: 'id = ?', whereArgs: [habitId]);
  }

  Future<int> deleteSkill(int skillId) async {
    final db = await this.db;
    return await db.delete('skills', where: 'id = ?', whereArgs: [skillId]);
  }

  Future<int> addSkill(Skill skill) async {
    final db = await this.db;
    return await db.insert(
      'skills',
      skill.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateSkill(Skill skill) async {
    final db = await this.db;
    return await db.update(
      'skills',
      skill.toMap(),
      where: 'id = ?',
      whereArgs: [skill.id],
    );
  }

  Future<int> addHabit(Habit habit) async {
    final db = await this.db;
    return await db.insert(
      'habits',
      habit.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateHabit(Habit habit) async {
    final db = await this.db;
    return await db.update(
      'habits',
      habit.toMap(),
      where: 'id = ?',
      whereArgs: [habit.id],
    );
  }
}
