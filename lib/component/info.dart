import 'package:intl/intl.dart';

class LogData {
  String log;

  LogData({this.log});

  LogData.fromMap(Map<String, dynamic> map) {
    this.log = map['remark'];
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = Map<String, dynamic>();
    map['remark'] = log;
    return map;
  }
}

class SecondsData {
  int seconds;

  SecondsData({this.seconds});

  SecondsData.fromMap(Map<String, dynamic> map) {
    this.seconds = map['seconds'];
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = Map<String, dynamic>();
    map['seconds'] = seconds;
    return map;
  }
}

class InfoLog {
  DateTime _datelog;
  String _remark;
  InfoLog(this._datelog, this._remark);

  InfoLog.fromMap(Map<String, dynamic> map) {
    this._datelog = DateTime.parse(map['datelog']);
    this._remark = map['remark'];
  }
  DateTime get datelog => _datelog;
  String get remark => _remark;

  set datelog(DateTime value) {
    _datelog = value;
  }

  set remark(String value) {
    _remark = value;
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = Map<String, dynamic>();
    map['datelog'] = datelog;
    map['remark'] = remark;
    return map;
  }
}

//class InfoProcess {
//  int _iDay;
//  int _iHour;
//  int _iMinute;
//  int _iSecond;
//  InfoProcess(this._iDay, this._iHour, this._iMinute, this._iSecond);
//  InfoProcess.fromMap(Map<String, dynamic> map) {
//    this._iDay = map['hari'];
//    this._iHour = map['jam'];
//    this._iMinute = map['menit'];
//    this._iSecond = map['detik'];
//  }
//  int get hari => _iDay;
//  int get jam => _iHour;
//  int get menit => _iMinute;
//  int get detik => _iSecond;
//
//  set hari(int value) {
//    _iDay = value;
//  }
//
//  set jam(int value) {
//    _iHour = value;
//  }
//
//  set menit(int value) {
//    _iMinute = value;
//  }
//
//  set detik(int value) {
//    _iSecond = value;
//  }
//
//  Map<String, dynamic> toMap() {
//    Map<String, dynamic> map = Map<String, dynamic>();
//    map['hari'] = hari;
//    map['jam'] = jam;
//    map['menit'] = menit;
//    map['detik'] = detik;
//    return map;
//  }
//}

class InfoGrafik {
  String _title;
  double _paw;
  double _vt;
  double _flow;
  String _guid;
  DateTime _created_at;

  InfoGrafik(this._title, this._paw, this._vt, this._flow, this._guid,
      this._created_at);
  InfoGrafik.fromMap(Map<String, dynamic> map) {
    this._title = map['title'];
    var f = new NumberFormat("###.0#", "en_US");
    this._paw = double.parse(f.format(map['paw']));
    this._vt = double.parse(f.format(map['vt']));
    this._flow = double.parse(f.format(map['flow']));
    this._guid = map['guid'];
    this._created_at = DateTime.parse(map['created_at']);
  }

  String get title => _title;
  double get paw => _paw;
  double get vt => _vt;
  double get flow => _flow;
  String get guid => _guid;
  DateTime get created_at => _created_at;

  set title(String value) {
    _title = value;
  }

  set paw(double value) {
    _paw = value;
  }

  set vt(double value) {
    _vt = value;
  }

  set flow(double value) {
    _flow = value;
  }

  set guid(String value) {
    _guid = value;
  }

  set created_at(DateTime value) {
    _created_at = value;
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = Map<String, dynamic>();
    map['title'] = title;
    map['paw'] = paw;
    map['vt'] = vt;
    map['guid'] = guid;
    map['flow'] = flow;
    return map;
  }
}

class InsGrafik {
  double _paw;
  double _vt;
  double _flow;
  String _guid;

  InsGrafik(this._paw, this._vt, this._flow, this._guid);
  InsGrafik.fromMap(Map<String, dynamic> map) {
    var f = new NumberFormat("###.0#", "en_US");
    this._paw = double.parse(f.format(map['paw']));
    this._vt = double.parse(f.format(map['vt']));
    this._flow = double.parse(f.format(map['flow']));
    this._guid = map['guid'];
  }

  double get paw => _paw;
  double get vt => _vt;
  double get flow => _flow;
  String get guid => _guid;

  set paw(double value) {
    _paw = value;
  }

  set vt(double value) {
    _vt = value;
  }

  set flow(double value) {
    _flow = value;
  }

  set guid(String value) {
    _guid = value;
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = Map<String, dynamic>();
    map['paw'] = paw;
    map['vt'] = vt;
    map['flow'] = flow;
    map['guid'] = guid;
    return map;
  }
}

class InfoDS {
  static List<InfoGrafik> linfoDS;
}
