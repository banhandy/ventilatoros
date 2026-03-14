import 'package:sqflite/sqflite.dart';
import 'package:sqflite/sqlite_api.dart';
import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'info.dart';
import '../constants.dart';

class DbHelper {
  static DbHelper _dbHelper;
  static Database _database;
  DbHelper._createObject();
  factory DbHelper() {
    if (_dbHelper == null) {
      _dbHelper = DbHelper._createObject();
    }
    return _dbHelper;
  }

  Future<Database> initgraphDb() async {
    Directory directory = await getApplicationDocumentsDirectory();
    String path = directory.path + 'info.db';

    var todoDatabase = openDatabase(path, version: 1, onCreate: _createGraphDb);

    return todoDatabase;
  }

  void _createGraphDb(Database db, int version) async {
    await db.execute('''
      CREATE TABLE infograph (
        title TEXT,
        paw NUMERIC,
        vt NUMERIC,
        flow NUMERIC,
        guid TEXT,
        created_at TEXT DEFAULT (datetime('now','localtime'))
      )
    ''');

    await db.execute('''
      CREATE TABLE infographtemp (
        title TEXT,
        paw NUMERIC,
        vt NUMERIC,
        flow NUMERIC,
        guid TEXT,
        created_at TEXT DEFAULT (datetime('now','localtime'))
      )
    ''');

    await db.execute('''
      CREATE TABLE tbllog (
        datelog TEXT DEFAULT (datetime('now','localtime')),
        remark TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE tblDuration (
        seconds INTEGER
      )
    ''');
  }

  Future<Database> get databaseGraph async {
    if (_database == null) {
      _database = await initgraphDb();
    }
    return _database;
  }

  /*-------------------------------------*/
  Future<int> insertLog(InfoLog object) async {
    Database db = await this.databaseGraph;
    int count = await db.insert('tbllog', object.toMap());
    return count;
  }

  Future<List<InfoLog>> getViewLog() async {
    var contactMapList = await selectLog();
    int count = contactMapList.length;
    List<InfoLog> infoList = List<InfoLog>();
    for (int i = 0; i < count; i++) {
      infoList.add(InfoLog.fromMap(contactMapList[i]));
    }
    return infoList;
  }

  Future<int> insertLogData(LogData object) async {
    Database db = await this.databaseGraph;
    int count = await db.insert('tbllog', object.toMap());
    return count;
  }

  Future<int> selectLogCount() async {
    var dbClient = await this.databaseGraph;
    return Sqflite.firstIntValue(
        await dbClient.rawQuery('SELECT COUNT(*) FROM tbllog'));
  }

  Future<List<Map<String, dynamic>>> selectLog() async {
    ///created_at asc, guid asc =>benziert
    Database db = await this.databaseGraph;
    var logList;
    try {
      logList = await db.query('tbllog',
          orderBy: 'datelog desc limit ' +
              LogPage.iStart.toString() +
              ',' +
              LogPage.iLength.toString());
    } catch (ex) {
      print("err: $ex");
    }
    return logList;
  }

//  Future<List<Map<String, dynamic>>> selectInfo() async {
//    Database db = await this.databaseGraph;
//    var mapTglList = await db.query('infotgl');
//    return mapTglList;
//  }
//
//  Future<int> insert(InfoProcess object) async {
//    Database db = await this.databaseGraph;
//    int count = await db.insert('infotgl', object.toMap());
//    return count;
//  }
//
//  Future<int> update(InfoProcess object) async {
//    Database db = await this.databaseGraph;
//    int count = await db.update(
//      'infotgl',
//      object.toMap(),
//    );
//    return count;
//  }

  Future<List<Map<String, dynamic>>> selectDuration() async {
    Database db = await this.databaseGraph;
    var mapTglList = await db.query('tblDuration');
    return mapTglList;
  }

  Future<int> insertDuration(SecondsData object) async {
    Database db = await this.databaseGraph;
    int count = await db.insert('tblDuration', object.toMap());
    return count;
  }

  Future<int> updateDuration(SecondsData object) async {
    Database db = await this.databaseGraph;
    int count = await db.update(
      'tblDuration',
      object.toMap(),
    );
    return count;
  }

  Future<int> getDuration() async {
    var dbClient = await this.databaseGraph;
    return Sqflite.firstIntValue(
        await dbClient.rawQuery('SELECT seconds FROM tblDuration'));
  }

//  Future<int> getTgl() async {
//    var dbClient = await this.databaseGraph;
//    return Sqflite.firstIntValue(
//        await dbClient.rawQuery('SELECT COUNT(*) FROM infotgl'));
//  }

//  Future<List<InfoProcess>> getViewList() async {
//    var contactMapList = await selectInfo();
//    int count = contactMapList.length;
//    List<InfoProcess> infoList = List<InfoProcess>();
//    for (int i = 0; i < count; i++) {
//      infoList.add(InfoProcess.fromMap(contactMapList[i]));
//    }
//    return infoList;
//  }

  /*-----------------------------------------*/
//  Future<List<Map<String, dynamic>>> selectGraph() async {
//    ///created_at asc, guid asc =>benziert
//    Database db = await this.databaseGraph;
//    var mapTglList;
//    try {
//      mapTglList = await db.query('infographtemp',
//          orderBy: 'created_at desc, guid desc limit 1296000');
//    } catch (ex) {
//      print("err: $ex");
//    }
//    return mapTglList;
//  }

  Future<List<Map<String, dynamic>>> selectDBGraph() async {
    ///created_at asc, guid asc =>benziert
    Database db = await this.databaseGraph;
    var mapTglList;
    try {
      mapTglList = await db.query('infograph',
          where: 'created_at < \'' + InfoPage.startDate + '\'',
          orderBy: 'created_at desc, guid desc limit ' +
              InfoPage.iStartDB.toString() +
              ',300');
      print('suskes tahap 3 ' +
          mapTglList.length.toString() +
          ' ' +
          InfoPage.startDate);
    } catch (ex) {
      print("err: $ex");
    }
    return mapTglList;
  }

  Future<int> insertGraph(InsGrafik object) async {
    Database db = await this.databaseGraph;
    int count = await db.insert('infograph', object.toMap());

    return count;
  }

//  Future<int> insertTemp() async {
//    Database db = await this.databaseGraph;
//    int count = 0;
//    await db.transaction((txn) async {
//      count = await txn.rawInsert(
//          'INSERT INTO infographtemp SELECT * FROM infograph  order by created_at desc, guid desc limit 1296000');
//    });
//    return count;
//  }

  Future<int> getCount() async {
    var dbClient = await this.databaseGraph;
    return Sqflite.firstIntValue(
        await dbClient.rawQuery('SELECT COUNT(*) FROM infograph'));
  }

  Future<int> deleteFilter(int diffRec) async {
    Database db = await this.databaseGraph;
    int count = await db.delete('infograph',
        where:
            'guid IN  (select guid from infograph order by created_at asc, guid asc limit $diffRec)');
    return count;
  }

//  Future<void> deleteTempGraph() async {
//    Database db = await this.databaseGraph;
//    await db.delete('infographtemp');
//  }

  Future<List<InfoGrafik>> getDBGraph() async {
    var mapList = await selectDBGraph();
    int count = mapList.length;
    print('log sukses tahap 2 ' + mapList.length.toString());
    List<InfoGrafik> infoListGraph = List<InfoGrafik>();
    for (int i = 0; i < count; i++) {
      infoListGraph.add(InfoGrafik.fromMap(mapList[i]));
    }
    return infoListGraph;
  }

//  Future<List<InfoGrafik>> getViewGraph() async {
//    deleteTempGraph();
//    if (InfoIdle.bdelay) {
//      Database db = await this.databaseGraph;
//      await db.transaction((txn) async {
//        await txn.rawInsert(
//            'INSERT INTO infographtemp SELECT * FROM infograph  order by created_at desc, guid desc limit 1296000');
//      });
//    }
//
//    var mapList = await selectGraph();
//    int count = mapList.length;
//    List<InfoGrafik> infoListGraph = List<InfoGrafik>();
//    for (int i = 0; i < count; i++) {
//      infoListGraph.add(InfoGrafik.fromMap(mapList[i]));
//    }
//    return infoListGraph;
//  }

  Future closeDB() async {
    var dbClient = await this.databaseGraph;
    return dbClient.close();
  }
}
