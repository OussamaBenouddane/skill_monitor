import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class SqlDb {
  static Database? _db;

  Future<Database?> get db async {
    _db ??= await initialDb();
    return _db;
  }

  initialDb() async {
    String dataBasePath = await getDatabasesPath();
    String path = join(dataBasePath, "skills.db");
    Database myDb = await openDatabase(path, onCreate: _onCreate);
    return myDb;
  }

  _onCreate(Database db, int version) async {
    await db.execute('''
    CREATE TABLE "skills"(
      "id" PRIMARY KEY AUTOINCREMENT,
      "skill" TEXT NOT NULL,
      "score" INTEGER NOT NULL
    ),
    CREATE TABLE "habits"(
      "id" PRIMARY KEY AUTOINCREMENT,
      "habit" TEXT NOT NULL,
      "value" INTEGER NOT NULL
    ),
    CREATE TABLE "condition"(
      "skill_id" INTEGER NOT NULL,
      "habit_id" INTEGER NOT NULL
    )
    ''');
  }

  readData(String sql) async {
    Database? myDb = await db;
    List<Map> response = await myDb!.rawQuery(sql); //SELECT
    return response;
  }

  insertData(String sql) async {
    Database? myDb = await db;
    int response = await myDb!.rawInsert(sql); //INSERT
    return response;
  }

  updateData(String sql) async {
    Database? myDb = await db;
    int response = await myDb!.rawUpdate(sql); // Update
    return response;
  }

  deleteData(String sql) async {
    Database? myDb = await db;
    int response = await myDb!.rawDelete(sql); // Delete
    return response;
  }


}
