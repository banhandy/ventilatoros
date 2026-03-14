import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutterappventilator/component/alarmbox.dart';
import 'package:flutterappventilator/component/logcard.dart';
import 'package:flutterappventilator/dtmodel.dart';
import 'dart:async';
import 'package:soundpool/soundpool.dart';
import 'package:flutterappventilator/component/grafikwithpointer.dart';
import 'package:flutterappventilator/component/informationdialogbox.dart';
import 'package:flutterappventilator/component/reusablecard.dart';
import 'package:flutterappventilator/component/settingbutton.dart';
import 'package:flutterappventilator/component/simplegraph.dart';
import 'package:flutterappventilator/constants.dart';
import 'package:flutterappventilator/component/confirmdialog.dart';
import 'package:flutterappventilator/component/valuepickerdialog.dart';
import 'package:flutterappventilator/ventilator.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock/wakelock.dart';
import 'package:flutterappventilator/component/graphdbwithpointer.dart';
import 'package:flutterappventilator/component/rangevaluepickerdialog.dart';
import 'package:flutterappventilator/component/database_helper.dart';
import 'package:flutterappventilator/component/info.dart';
import 'package:flutterappventilator/component/infobox.dart';
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:flutter_beep/flutter_beep.dart';

class MonitorPage extends StatefulWidget {
  static String id = "monitor_screen";
  @override
  _MonitorPageState createState() => _MonitorPageState();
}

class _MonitorPageState extends State<MonitorPage> {
  final assetsAudioPlayer = AssetsAudioPlayer();

  bool soundAlarm = true;
  int index = 0;
  int calibIndex = 0;
  Ventilator ventilator;
  String ventType;
  String patientType;
  String patientName;
  String patientGender;
  DateTime patientBirthDate;
  int patientAge;
  int patientHeight;
  Timer _timer;
  bool _start = false;
  bool _calibStart = false;
  int _refreshSpeed = 100;

  ///for DB
  String data;
  DbHelper dbHelper = DbHelper();
  List<InfoLog> _lInfo;
  String prevAlarmText = '';
  bool _infGrph = true;
  int dbIndex = kDataWidth - 1;
  int lengthDB = 150;

  /// for blinking alarm for each seconds
  String alarmText = '';
  bool alarmTextBlink = false;
  bool airAlarm = false;
  bool o2Alarm = false;
  bool fiO2Alarm = false;
  bool mVeAlarm = false;
  bool pAlarm = false;
  bool vtEAlarm = false;
  bool hUAlarm = false;
  bool tAlarm = false;
  bool uvAlarm = false;
  bool acAlarm = false;
  bool batAlarm = false;

  int _flagSpeed = 0;
  int _flagAlarmSound = 0;
  Soundpool _soundpool = Soundpool();
  Future<int> _soundId;
  int _alarmSoundStreamId;
  bool _showSPO2Graph = false;
  bool _showETCO2Graph = false;

  String _selectedGraph = '';
  bool _graphPressed = false;
  String _selectedLoop = 'none';
  bool _showLog = false;
  bool _showInfo = false;

  /// for lung movement
  double prevVT = 0.0;
  int indexImage = 11;

  ///for state
  bool flagStatus = false;
  String stringStatus = '';
  String status = 'Idle';

  initVentilator() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      ventType = prefs.getString('ventType');
      patientType = prefs.getString('patientType');
      patientName = prefs.getString('patientName');
      patientHeight = prefs.getInt('patientHeight');
      patientGender = prefs.getString('patientGender');
      if (patientName == null) patientName = 'John Doe';
      patientBirthDate = DateTime.parse(prefs.getString('birthdate'));
      patientAge =
          (DateTime.now().difference(patientBirthDate).inDays / 365).truncate();

      ventilator = Ventilator(
          ventType: ventType,
          patientType: patientType,
          patientHeight: patientHeight,
          patientGender: patientGender);
      _timer = Timer.periodic(
          Duration(milliseconds: _refreshSpeed), _loopVentilator);
      dbHelper.insertLogData(LogData(
          log:
              'Ventilator Setup For New Patient : $patientName, Age : $patientAge, Height : $patientHeight'));
      setState(() {});
    } catch (e) {
      print(e);
    }
  }

  Future<int> _loadSound() async {
    var asset = await rootBundle.load("media/beep-09.wav");
    return await _soundpool.load(asset);
  }

  Future<void> _playSound() async {
    var _alarmSound = await _soundId;
    _alarmSoundStreamId = await _soundpool.play(_alarmSound);
  }

  ///for DB

  void getLogGraph() {
    Future<List<InfoGrafik>> logList = dbHelper.getDBGraph();
    logList.then((tableList) {
      print('log sukses tahap 1 ' + tableList.length.toString());
      InfoDS.linfoDS = tableList;
      ventilator.setUPDBData();
    });
  }

  void getLog() {
    Future<List<InfoLog>> logList = dbHelper.getViewLog();
    logList.then((tableList) {
      _lInfo = tableList;
    });
  }

  void getLogCount() {
    Future<int> logCount = dbHelper.selectLogCount();
    logCount.then((value) => LogPage.iTotalData = value);
  }

  ///end for DB

  @override
  void initState() {
    super.initState();

    Wakelock.enable();
    initVentilator();
    _soundId = _loadSound();

    ///for DB
    dbHelper.initgraphDb();

    InfoIdle.bdelay = false;
    InfoPage.iStart = 0;
    InfoPage.iLength = kDataWidth;
    InfoPage.bInfo = false;
    getLogCount();
    LogPage.iStart = 0;
    LogPage.iLength = 50;
    getLog();
  }

  @override
  void dispose() {
    dbHelper.closeDB();
    super.dispose();
  }

  _loopVentilator(Timer t) {
    setState(() {
      if (ventilator.getConnection()) {
        if (stringStatus == '' || status == 'Connecting') {
          status = 'Machine Connected';
        }
        _flagSpeed++;
        _flagAlarmSound++;
        if (_flagAlarmSound > 2000 / _refreshSpeed) {
          _flagAlarmSound = 1;
        }

        if (_flagSpeed > 1000 / _refreshSpeed) {
          _flagSpeed = 1;
          if (_start) _checkAlarm();
        }

        if (_calibStart) {
          ventilator.startCalib();
          index = ventilator.getIndex();
        }
        if (_start) {
          ventilator.startVenting(index);
          index = ventilator.getIndex();
          //if (index == kDataWidth) {
          //  index = 0;
          //}
        } else {
          if (flagStatus) {
            switch (stringStatus) {
              case 'Air':
                if (ventilator.getAirLeakCheckStatus()) {
                  status = 'Success';
                  flagStatus = false;
                } else
                  status += '.';
                break;
              case 'Flow':
                if (ventilator.getSensorFlowCheckStatus()) {
                  index = 0;
                  _calibStart = false;
                  status = 'Success';
                  flagStatus = false;
                } else {
                  status += '.';
                }
                break;
              case 'Pressure':
                if (ventilator.getSensorPressureCheckStatus()) {
                  index = 0;
                  _calibStart = false;
                  status = 'Success';
                  flagStatus = false;
                } else {
                  status += '.';
                }
                break;
              case 'O2 Cell':
                if (ventilator.getSensorO2CheckStatus()) {
                  status = 'Success';
                  flagStatus = false;
                } else
                  status += '.';
                break;
              case 'Init':
                if (ventilator.getInitMachineStatus()) {
                  status = 'Success';

                  flagStatus = false;
                } else
                  status += '.';
                break;
            }
          }
        }
      } else {
        ventilator.resetCheckList();
        status = 'Connecting';
        stringStatus = '';
        flagStatus = false;
        _calibStart = false;
      }
    });

    //setState(() {});
  }

  void _checkAlarm() {
    ventilator.getOtherMachineStatus();
    if (ventilator.getBatteryStatus() == 5) {
      acAlarm = false;
      batAlarm = false;
    } else if (ventilator.getBatteryStatus() == 1) {
      batAlarm = true;
      acAlarm = true;
    } else {
      batAlarm = false;
      acAlarm = true;
    }
    if (ventilator.getO2Flag() == 1)
      o2Alarm = true;
    else
      o2Alarm = false;
    if (ventilator.getAirFlag() == 1)
      airAlarm = true;
    else
      airAlarm = false;
    if (ventilator.getUvFlag() == 1)
      uvAlarm = true;
    else
      uvAlarm = false;

    if (ventilator.getCurrentHuValue() <
        ventilator.getMinAlarmValue(Ventilator.stringHumidifier)) {
      hUAlarm = true;
      alarmText = ' |HU LOW| ';
    } else if (ventilator.getCurrentHuValue() >
        ventilator.getMaxAlarmValue(Ventilator.stringHumidifier)) {
      hUAlarm = true;
      alarmText = ' |HU HIGH| ';
    } else {
      hUAlarm = false;
      alarmText = '';
    }

    if (ventilator.getTemperatureValue() <
        ventilator.getMinAlarmValue(Ventilator.stringTemp)) {
      tAlarm = true;
      alarmText += ' |TEMP LOW| ';
    } else if (ventilator.getTemperatureValue() >
        ventilator.getMaxAlarmValue(Ventilator.stringTemp)) {
      tAlarm = true;
      alarmText += ' |TEMP HIGH| ';
    } else {
      tAlarm = false;
    }

    if (ventilator.getCurrentFiO2Value() <
        ventilator.getMinAlarmValue(Ventilator.stringFiO2)) {
      fiO2Alarm = true;
      alarmText += ' |FIO2 LOW| ';
    } else if (ventilator.getCurrentFiO2Value() >
        ventilator.getMaxAlarmValue(Ventilator.stringFiO2)) {
      fiO2Alarm = true;
      alarmText += ' |FIO2 HIGH| ';
    } else {
      fiO2Alarm = false;
    }

    if (ventilator.getPPeakValue() <
        ventilator.getMinAlarmValue(Ventilator.stringPressure)) {
      pAlarm = true;
      alarmText += ' |PRESSURE LOW| ';
    } else if (ventilator.getPPeakValue() >
        ventilator.getMaxAlarmValue(Ventilator.stringPressure)) {
      pAlarm = true;
      alarmText += ' |PRESSURE HIGH| ';
    } else {
      pAlarm = false;
    }

    if (ventilator.getCurrentMve() <
        ventilator.getMinAlarmValue(Ventilator.stringMinuteVentilation)) {
      mVeAlarm = true;
      alarmText += ' |MVe LOW| ';
    } else if (ventilator.getCurrentMve() >
        ventilator.getMaxAlarmValue(Ventilator.stringMinuteVentilation)) {
      mVeAlarm = true;
      alarmText += ' |MVe HIGH| ';
    } else {
      mVeAlarm = false;
    }

    if (ventilator.getCurrentVTi() <
        ventilator.getMinAlarmValue(Ventilator.stringVTidal)) {
      vtEAlarm = true;
      alarmText += ' |VT LOW| ';
    } else if (ventilator.getCurrentVTi() >
        ventilator.getMaxAlarmValue(Ventilator.stringVTidal)) {
      vtEAlarm = true;
      alarmText += ' |VT HIGH| ';
    } else {
      vtEAlarm = false;
    }
    if (alarmText != '') {
      alarmTextBlink = true;
      if (prevAlarmText.compareTo(alarmText) != 0) {
        prevAlarmText = alarmText;
        dbHelper.insertLogData(LogData(log: 'Alarm :  ' + alarmText));
      }
    } else
      alarmTextBlink = false;
  }

  bool _blinkAlarm(bool alarm) {
    if (alarm) {
      if (_flagSpeed == 1000 / _refreshSpeed) {
        if (_start) if (soundAlarm && _flagAlarmSound == 2000 / _refreshSpeed)

          //AssetsAudioPlayer.playAndForget(Audio("media/beep-09.wav"));
          //_playSound();
          FlutterBeep.playSysSound(AndroidSoundIDs.TONE_CDMA_ABBR_ALERT);
        return true;
      }
    }
    return false;
  }

  AppBar _generateHeader() {
    return ventilator.getCalibrationStatus() && ventilator.getConnection()
        ? AppBar(
            title: Visibility(
              visible: alarmTextBlink && _start ? false : true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Container(
                    child: Hero(
                        tag: 'logo', child: Image.asset('images/logo.png')),
                    width: 180.0,
                  ),
                  Text(
                    "Ventilator",
                    textAlign: TextAlign.right,
                  ),
                ],
              ),
            ),
            flexibleSpace: Container(
              color: _blinkAlarm(alarmTextBlink) && _start
                  ? kAccentColor
                  : kPrimaryColor,
              child: Center(
                child: GestureDetector(
                  onDoubleTap: () {
                    soundAlarm = !soundAlarm;
                  },
                  child: Text(
                    _start ? alarmText : '',
                    style: TextStyle(fontSize: 30.0),
                  ),
                ),
              ),
            ),
            actions: <Widget>[
              Visibility(
                visible: alarmTextBlink && _start ? false : true,
                child: Padding(
                  padding: EdgeInsets.only(right: 10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      Text(
                        kVentSeries,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 28.0,
                        ),
                      ),
                      Text(
                        kSerialNumber,
                        textAlign: TextAlign.right,
                        style: TextStyle(fontSize: 15.0),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          )
        : null;
  }

  Future<bool> _showInformationDialog(
      String title, Widget child, Color bgColor, Color btnOkColor) async {
    final selectedValue = await showDialog<bool>(
        context: context,
        builder: (context) => InfoDialog(
              childWidget: child,
              title: title,
              bgColor: bgColor,
              btnOkColor: btnOkColor,
            ));
    return selectedValue;
  }

  Future<bool> _showConfirmationDialog(String title, Widget child) async {
    // <-- note the async keyword here

    final selectedValue = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmDialog(
        childWidget: child,
        title: title,
        bgColor: kSecondaryColor,
        btnNoColor: kAccentColor,
        btnYesColor: kSecondaryColor,
      ),
    );

    return selectedValue;
  }

  Future<double> _showValuePickerDialogDecimal(
      String title,
      double value,
      String unit,
      Color bgColor,
      Color btnColor,
      bool unitFront,
      double division) async {
    // <-- note the async keyword here

    final selectedValue = await showDialog<double>(
      context: context,
      builder: (context) => ValuePickerDialog(
        initialValue: value,
        minValue: ventilator.getMinSettingValue(title),
        maxValue: ventilator.getMaxSettingValue(title),
        title: title,
        unit: unit,
        bgColor: bgColor,
        btnColor: btnColor,
        unitFront: unitFront,
        isDecimal: true,
        division: division,
      ),
    );

    return selectedValue.toDouble();
  }

  Future<MinMaxData> _showRangeValuePickerDialogInt(
      String title,
      MinMaxData minMaxData,
      String unit,
      Color bgColor,
      Color btnColor,
      bool unitFront,
      double division) async {
    // <-- note the async keyword here

    final selectedValue = await showDialog<MinMaxData>(
      context: context,
      builder: (context) => RangeValuePickerDialog(
        minMaxData: minMaxData,
        minValue: ventilator.getMinSettingValue(title),
        maxValue: ventilator.getMaxSettingValue(title),
        title: title,
        unit: unit,
        bgColor: bgColor,
        btnColor: btnColor,
        unitFront: unitFront,
        division: division,
      ),
    );

    return selectedValue;
  }

  Future<int> _showValuePickerDialogInt(String title, int value, String unit,
      Color bgColor, Color btnColor, bool unitFront, double division) async {
    // <-- note the async keyword here

    final selectedValue = await showDialog<double>(
      context: context,
      builder: (context) => ValuePickerDialog(
        initialValue: value.toDouble(),
        minValue: ventilator.getMinSettingValue(title),
        maxValue: ventilator.getMaxSettingValue(title),
        title: title,
        unit: unit,
        bgColor: bgColor,
        btnColor: btnColor,
        unitFront: unitFront,
        division: division,
      ),
    );

    return selectedValue.toInt();
  }

  List<Widget> _generateStatusText() {
    return <Widget>[
      Expanded(
        child: !ventilator.isBluetoothError()
            ? Center(
                child: Text(
                  'Status : ' + status,
                  style: TextStyle(fontSize: 30.0),
                ),
              )
            : MaterialButton(
                color: kAccentColor,
                child: Text(
                  'Connect To Machine',
                  style: TextStyle(fontSize: 30.0),
                ),
                onPressed: () {
                  ventilator.reconnectToMachine();
                },
              ),
      ),
    ];
  }

  List<Widget> _generateEmptyBlock() {
    return <Widget>[
      Container(),
    ];
  }

  List<Widget> _generateSettingButtons() {
    return <Widget>[
      SettingButton(
        btnColor: kSecondaryColor,
        title: Ventilator.stringFiO2,
        unit: '%',
        value: ventilator == null ? 0 : ventilator.getFiO2Value(),
        onPress: () async {
          int selectedValue = await _showValuePickerDialogInt(
              Ventilator.stringFiO2,
              ventilator.getFiO2Value(),
              '%',
              kSecondaryColor,
              kAccentColor,
              false,
              10);
          ventilator.setFiO2Value(selectedValue);
          dbHelper.insertLogData(LogData(
              log: 'Set :  ' +
                  Ventilator.stringFiO2 +
                  ' to ' +
                  selectedValue.toString()));
        },
      ),
      Visibility(
        visible: ventilator == null ? true : ventilator.isVisibleVolume(),
        child: SettingButton(
          btnColor: kSecondaryColor,
          title: Ventilator.stringVTidal,
          unit: 'ml',
          value: ventilator == null ? 0 : ventilator.getVTidalValue(),
          onPress: () async {
            int selectedValue = await _showValuePickerDialogInt(
                Ventilator.stringVTidal,
                ventilator.getVTidalValue(),
                'ml',
                kSecondaryColor,
                kAccentColor,
                false,
                50);
            ventilator.setVTidalValue(selectedValue);
            dbHelper.insertLogData(LogData(
                log: 'Set :  ' +
                    Ventilator.stringVTidal +
                    ' to ' +
                    selectedValue.toString()));
          },
        ),
      ),
      SettingButton(
        btnColor: kSecondaryColor,
        title: Ventilator.stringPeep,
        unit: 'cmH2O',
        value: ventilator == null ? 0 : ventilator.getPeepValue(),
        onPress: () async {
          int selectedValue = await _showValuePickerDialogInt(
              Ventilator.stringPeep,
              ventilator.getPeepValue(),
              'cmH2O',
              kSecondaryColor,
              kAccentColor,
              false,
              1);
          ventilator.setPeepValue(selectedValue);
          dbHelper.insertLogData(LogData(
              log: 'Set :  ' +
                  Ventilator.stringPeep +
                  ' to ' +
                  selectedValue.toString()));
        },
      ),
      Visibility(
        visible: ventilator == null ? true : ventilator.isVisiblePressure(),
        child: SettingButton(
          btnColor: kSecondaryColor,
          title: Ventilator.stringPressure,
          unit: 'cmH2O',
          value: ventilator == null ? 0 : ventilator.getPressureValue(),
          onPress: () async {
            int selectedValue = await _showValuePickerDialogInt(
                Ventilator.stringPressure,
                ventilator.getPressureValue(),
                'cmH2O',
                kSecondaryColor,
                kAccentColor,
                false,
                10);
            ventilator.setPressureValue(selectedValue);
            dbHelper.insertLogData(LogData(
                log: 'Set :  ' +
                    Ventilator.stringPressure +
                    ' to ' +
                    selectedValue.toString()));
          },
        ),
      ),
      Visibility(
        visible: ventilator == null ? true : ventilator.isVisibleFlow(),
        child: SettingButton(
          btnColor: kSecondaryColor,
          title: Ventilator.stringFlow,
          unit: 'lpm',
          decimalValue: ventilator == null ? 0 : ventilator.getFlowValue(),
          isDecimal: true,
          onPress: () async {
            double selectedValue = await _showValuePickerDialogDecimal(
                Ventilator.stringFlow,
                ventilator == null ? 0 : ventilator.getFlowValue(),
                'lpm',
                kSecondaryColor,
                kAccentColor,
                false,
                0.5);
            ventilator
                .setFlowValue(num.parse(selectedValue.toStringAsFixed(1)));
            dbHelper.insertLogData(LogData(
                log: 'Set :  ' +
                    Ventilator.stringFlow +
                    ' to ' +
                    selectedValue.toStringAsFixed(1)));
          },
        ),
      ),
      SettingButton(
        btnColor: kSecondaryColor,
        title: Ventilator.stringOverPressure,
        unit: 'cmH2O',
        value: ventilator == null ? 0 : ventilator.getOverPressureValue(),
        onPress: () async {
          int selectedValue = await _showValuePickerDialogInt(
              Ventilator.stringOverPressure,
              ventilator.getOverPressureValue(),
              'cmH2O',
              kSecondaryColor,
              kAccentColor,
              false,
              10);
          ventilator.setOverPressureValue(selectedValue);
          dbHelper.insertLogData(LogData(
              log: 'Set :  ' +
                  Ventilator.stringPressure +
                  ' to ' +
                  selectedValue.toString()));
        },
      ),
      Visibility(
        visible: false,
        child: SettingButton(
          btnColor: kSecondaryColor,
          title: Ventilator.stringHumidifier,
          unit: '%',
          value: ventilator == null ? 0 : ventilator.getHumidifierValue(),
          onPress: () async {
            int selectedValue = await _showValuePickerDialogInt(
                Ventilator.stringHumidifier,
                ventilator.getHumidifierValue(),
                '%',
                kSecondaryColor,
                kAccentColor,
                false,
                5);
            ventilator.setHumidifierValue(selectedValue);
            dbHelper.insertLogData(LogData(
                log: 'Set :  ' +
                    Ventilator.stringHumidifier +
                    ' to ' +
                    selectedValue.toString()));
          },
        ),
      ),
      Visibility(
        visible: ventType == Ventilator.modePSV,
        child: SettingButton(
          onLongPress: () async {
            bool _reverseIE = await _showConfirmationDialog(
                'Switch Trigger',
                Text(
                  ventilator.getSelectedTrigger() == Ventilator.stringPTrigger
                      ? 'Switch To ' + Ventilator.stringFTrigger + ' ?'
                      : 'Switch To ' + Ventilator.stringPTrigger + '?',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20.0),
                ));
            if (_reverseIE) ventilator.switchTrigger();
          },
          btnColor: kSecondaryColor,
          title: ventilator == null ? '' : ventilator.getSelectedTrigger(),
          unit: ventilator.getSelectedTrigger() == Ventilator.stringPTrigger
              ? 'cmH2O'
              : 'lpm',
          value: ventilator == null
              ? 0
              : ventilator.getSelectedTrigger() == Ventilator.stringPTrigger
                  ? ventilator.getPTrigger()
                  : ventilator.getFTrigger(),
          onPress: () async {
            int selectedValue = await _showValuePickerDialogInt(
                ventilator.getSelectedTrigger(),
                ventilator.getSelectedTrigger() == Ventilator.stringPTrigger
                    ? ventilator.getPTrigger()
                    : ventilator.getFTrigger(),
                ventilator.getSelectedTrigger() == Ventilator.stringPTrigger
                    ? 'cmH2O'
                    : 'lpm',
                kSecondaryColor,
                kAccentColor,
                false,
                1);
            ventilator.getSelectedTrigger() == Ventilator.stringPTrigger
                ? ventilator.setPTrigger(selectedValue)
                : ventilator.setFTrigger(selectedValue);
            dbHelper.insertLogData(LogData(
                log: 'Set :  ' +
                    ventilator.getSelectedTrigger() +
                    ' to ' +
                    selectedValue.toString()));
          },
        ),
      ),
      Visibility(
        visible:
            ventType == Ventilator.modeSIMV || ventType == Ventilator.modePSIMV,
        child: SettingButton(
          btnColor: kSecondaryColor,
          title: Ventilator.stringSpontaneousBreath,
          unit: 'cycle',
          value: ventilator == null ? 0 : ventilator.getSpontanBreath(),
          onPress: () async {
            int selectedValue = await _showValuePickerDialogInt(
                Ventilator.stringSpontaneousBreath,
                ventilator.getSpontanBreath(),
                'cycle',
                kSecondaryColor,
                kAccentColor,
                false,
                1);
            ventilator.setSpontanBreath(selectedValue);
            dbHelper.insertLogData(LogData(
                log: 'Set :  ' +
                    Ventilator.stringSpontaneousBreath +
                    ' to ' +
                    selectedValue.toString()));
          },
        ),
      ),
      Visibility(
        visible: ventilator == null ? true : ventilator.isVisibleIERatio(),
        child: SettingButton(
          onLongPress: () async {
            bool _reverseIE = await _showConfirmationDialog(
                'Reverse IE Ratio',
                Text(
                  'Do You Want to Reverse I/E Ratio?',
                  style: TextStyle(fontSize: 20.0),
                ));
            if (_reverseIE) ventilator.setReverseIE();
          },
          btnColor: kSecondaryColor,
          title: Ventilator.stringIERatio,
          unit: ventilator == null
              ? ''
              : ventilator.isReverseIE()
                  ? '/ 1'
                  : '1 /',
          decimalValue: ventilator == null ? 0 : ventilator.getIERatioValue(),
          //value: ventilator.getIERatioValue(),
          unitFront: ventilator == null
              ? false
              : ventilator.isReverseIE()
                  ? false
                  : true,
          isDecimal: true,
          onPress: () async {
            double selectedValue = await _showValuePickerDialogDecimal(
                Ventilator.stringIERatio,
                ventilator.getIERatioValue(),
                ventilator.isReverseIE() ? '/ 1' : '1 /',
                kSecondaryColor,
                kAccentColor,
                ventilator.isReverseIE() ? false : true,
                0.1);
            ventilator
                .setIERatioValue(num.parse(selectedValue.toStringAsFixed(1)));
            dbHelper.insertLogData(LogData(
                log: 'Set :  ' +
                    Ventilator.stringIERatio +
                    ' to ' +
                    selectedValue.toStringAsFixed(1)));
          },
        ),
      ),
      Visibility(
        visible: ventilator == null ? true : ventilator.isVisibleRespiration(),
        child: SettingButton(
          btnColor: kSecondaryColor,
          title: Ventilator.stringResRate,
          unit: 'bpm',
          value: ventilator == null ? 0 : ventilator.getRestRateValue(),
          onPress: () async {
            int selectedValue = await _showValuePickerDialogInt(
                Ventilator.stringResRate,
                ventilator.getRestRateValue(),
                'bpm',
                kSecondaryColor,
                kAccentColor,
                false,
                1);
            ventilator.setRestRateValue(selectedValue);
            dbHelper.insertLogData(LogData(
                log: 'Set :  ' +
                    Ventilator.stringResRate +
                    ' to ' +
                    selectedValue.toString()));
          },
        ),
      ),
    ];
  }

  List<Widget> _generateStatusRow() {
    return <Widget>[
      Expanded(
        child: ReusableCard(
          onPress: () async {
            _showInformationDialog(
                'Patient Information',
                Column(
                  children: <Widget>[
                    Center(
                      child: FaIcon(
                        FontAwesomeIcons.userInjured,
                        size: 50.0,
                      ),
                    ),
                    SizedBox(
                      height: 20.0,
                    ),
                    Text(
                      'Name : ' + patientName,
                      style: TextStyle(fontSize: 30.0),
                    ),
                    SizedBox(
                      height: 20.0,
                    ),
                    Text(
                      'Age : ' + patientAge.toString(),
                      style: TextStyle(fontSize: 30.0),
                    ),
                    SizedBox(
                      height: 20.0,
                    ),
                    Text(
                      'Height : ' + patientHeight.toString() + ' cm',
                      style: TextStyle(fontSize: 30.0),
                    ),
                    SizedBox(
                      height: 20.0,
                    ),
                    Text(
                      'Gender : ' + patientGender,
                      style: TextStyle(fontSize: 30.0),
                    ),
                    SizedBox(
                      height: 20.0,
                    ),
                    Text(
                      'IBW : ' +
                          ventilator.getWeight().toStringAsFixed(1) +
                          ' kg',
                      style: TextStyle(fontSize: 30.0),
                    ),
                    SizedBox(
                      height: 20.0,
                    ),
                    Text(
                      'Ideal TV (' +
                          kVtIBW.toString() +
                          ' ml/kg) :' +
                          ventilator.getIdealVT().toString() +
                          ' ml',
                      style: TextStyle(fontSize: 30.0),
                    ),
                  ],
                ),
                kSecondaryColor,
                kAccentColor);
          },
          colour: kSecondaryColor,
          cardChild: Center(
            child: FaIcon(
              FontAwesomeIcons.userInjured,
              size: 50.0,
            ),
          ),
        ),
      ),
      Expanded(
        flex: 3,
        child: ReusableCard(
          colour: kSecondaryColor,
          onPress: () async {
            if (!_start) {
              bool selectedValue = await showDialog<bool>(
                  context: context,
                  builder: (context) {
                    StreamController<String> controller =
                        StreamController<String>.broadcast();
                    return _generateVentSelection(controller);
                  });
              if (selectedValue) {
                ///setventilator mode
                print(ventType);
              }
            }
          },
          cardChild: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: Center(
                  child: Text(
                    'Mode',
                    style: TextStyle(fontSize: 18.0),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    ventilator == null ? '' : ventilator.getMode(),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18.0),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      Expanded(
        child: ReusableCard(
          colour: kSecondaryColor,
          onPress: () async {
            if (!_start) {
              bool selectedValue = await showDialog<bool>(
                  context: context,
                  builder: (context) {
                    StreamController<String> controller =
                        StreamController<String>.broadcast();
                    return _generateOptionSelection(controller);
                  });
              if (selectedValue) {
                ///setventilator mode
                print(patientType);
              }
            }
          },
          cardChild: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Text(
                'Option',
                style: TextStyle(fontSize: 18.0),
              ),
              Text(
                ventilator == null ? '' : ventilator.getOption(),
                style: TextStyle(fontSize: 18.0),
              ),
            ],
          ),
        ),
      ),
      Expanded(
        child: ReusableCard(
          colour: ventilator == null
              ? kSecondaryColor
              : ventilator.isInspHold()
                  ? Colors.green
                  : kSecondaryColor,
          cardChild: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Text(
                'INSP',
                style: TextStyle(fontSize: 18.0),
              ),
              Text(
                'HOLD',
                style: TextStyle(fontSize: 18.0),
              ),
            ],
          ),
          onPress: () async {
            if (_start) {
              bool _inshold = await _showConfirmationDialog(
                  'Inspiration Hold',
                  Text(
                    ventilator.isInspHold()
                        ? 'Do You Want to Stop Inspiration Hold?'
                        : 'Do You Want to Start Inspiration Hold?',
                    style: TextStyle(fontSize: 20.0),
                  ));
              if (_inshold) ventilator.switchInspHold();
            }
          },
        ),
      ),
      Expanded(
        flex: 1,
        child: ReusableCard(
          colour: ventilator == null
              ? kSecondaryColor
              : ventilator.getConnection()
                  ? Colors.green
                  : kSecondaryColor,
          onPress: () {
            if (!ventilator.getConnection()) ventilator.reconnectToMachine();
          },
          cardChild: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: Center(
                  child: Text(
                    'Duration',
                    style: TextStyle(fontSize: 18.0),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    ventilator == null ? '' : ventilator.getDuration(),
                    style: TextStyle(fontSize: 18.0),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      Expanded(
        flex: 1,
        child: ReusableCard(
          colour: kSecondaryColor,
          cardChild: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Text(
                'Status',
                style: TextStyle(fontSize: 18.0),
              ),
              FaIcon(
                ventilator == null
                    ? FontAwesomeIcons.plug
                    : ventilator.getBatteryStatus() == 5
                        ? FontAwesomeIcons.plug
                        : ventilator.getBatteryStatus() == 4
                            ? FontAwesomeIcons.batteryFull
                            : ventilator.getBatteryStatus() == 3
                                ? FontAwesomeIcons.batteryThreeQuarters
                                : ventilator.getBatteryStatus() == 2
                                    ? FontAwesomeIcons.batteryHalf
                                    : FontAwesomeIcons.batteryQuarter,
                size: 30.0,
              ),
            ],
          ),
        ),
      ),
      Expanded(
        child: ReusableCard(
          colour: _start ? kSecondaryColor : kAccentColor,
          cardChild: Center(
            child: FaIcon(
              _start
                  ? FontAwesomeIcons.pauseCircle
                  : FontAwesomeIcons.playCircle,
              size: 50.0,
            ),
          ),
          onPress: () async {
            if (ventilator.getCalibrationStatus()) {
              if (ventilator.getConnection()) {
                bool flagAnswer = await _showConfirmationDialog(
                    _start ? 'Pause Ventilation' : 'Start Ventilation',
                    Text(
                      _start
                          ? 'Do You Want to Pause Ventilation?'
                          : 'Do You Want to Start Ventilation?',
                      style: TextStyle(fontSize: 20.0),
                    ));
                if (flagAnswer)
                  setState(() {
                    if (_start) {
                      ventilator.pauseVenting();
                      dbHelper
                          .insertLogData(LogData(log: 'Ventilation :  Paused'));
                    } else {
                      ventilator.continueVenting();
                      dbHelper
                          .insertLogData(LogData(log: 'Ventilation :  Start'));
                    }
                    _start = !_start;
                  });
              }
            }
          },
        ),
      ),
      Expanded(
        child: ReusableCard(
          colour: kSecondaryColor,
          cardChild: Center(
            child: FaIcon(
              FontAwesomeIcons.powerOff,
              size: 50.0,
            ),
          ),
          onPress: () async {
            if (!_start) {
              bool _exit = await _showConfirmationDialog(
                  'Stop Monitoring?',
                  Text(
                    'Do You Want to Stop Monitoring Machine?',
                    style: TextStyle(fontSize: 20.0),
                  ));
              if (_exit) {
                await ventilator.connectionStop();
                SystemNavigator.pop();
              }
            }
          },
        ),
      ),
    ];
  }

  List<Widget> _generateAlarmButtonSideWay() {
    return <Widget>[
      Expanded(
        child: Row(
          children: [
            AlarmBox(
              upperText: 'O2',
              lowerText: 'Supply Down',
              bgColor: _blinkAlarm(o2Alarm) ? kAccentColor : kSecondaryColor,
            ),
            AlarmBox(
              upperText: 'Air',
              lowerText: 'Supply Down',
              bgColor: _blinkAlarm(airAlarm) ? kAccentColor : kSecondaryColor,
            ),
          ],
        ),
      ),
      Expanded(
        child: Row(
          children: [
            AlarmBox(
              upperText: 'FiO2',
              lowerText: 'High/Low',
              bgColor: _blinkAlarm(fiO2Alarm) ? kAccentColor : kSecondaryColor,
              onPress: () async {
                MinMaxData selectedValue = await _showRangeValuePickerDialogInt(
                    Ventilator.stringFiO2,
                    MinMaxData(
                        min: ventilator.getMinAlarmValue(Ventilator.stringFiO2),
                        max:
                            ventilator.getMaxAlarmValue(Ventilator.stringFiO2)),
                    '%',
                    kSecondaryColor,
                    kAccentColor,
                    false,
                    1);
                ventilator.setMinAlarmValue(
                    Ventilator.stringFiO2, selectedValue.min);
                ventilator.setMaxAlarmValue(
                    Ventilator.stringFiO2, selectedValue.max);
                dbHelper.insertLogData(LogData(
                    log: 'Set Alarm Limit : ' +
                        Ventilator.stringFiO2 +
                        ' between ' +
                        selectedValue.min.toStringAsFixed(0) +
                        ' to ' +
                        selectedValue.max.toStringAsFixed(0)));
              },
            ),
            AlarmBox(
              upperText: 'MVe',
              lowerText: 'High/Low',
              bgColor: _blinkAlarm(mVeAlarm) ? kAccentColor : kSecondaryColor,
              onPress: () async {
                MinMaxData selectedValue = await _showRangeValuePickerDialogInt(
                    Ventilator.stringMinuteVentilation,
                    MinMaxData(
                        min: ventilator.getMinAlarmValue(
                            Ventilator.stringMinuteVentilation),
                        max: ventilator.getMaxAlarmValue(
                            Ventilator.stringMinuteVentilation)),
                    'lpm',
                    kSecondaryColor,
                    kAccentColor,
                    false,
                    1);
                ventilator.setMinAlarmValue(
                    Ventilator.stringMinuteVentilation, selectedValue.min);
                ventilator.setMaxAlarmValue(
                    Ventilator.stringMinuteVentilation, selectedValue.max);
                dbHelper.insertLogData(LogData(
                    log: 'Set Alarm Limit : ' +
                        Ventilator.stringMinuteVentilation +
                        ' between ' +
                        selectedValue.min.toStringAsFixed(0) +
                        ' to ' +
                        selectedValue.max.toStringAsFixed(0)));
              },
            ),
          ],
        ),
      ),
      Expanded(
        child: Row(
          children: [
            AlarmBox(
              upperText: 'P',
              lowerText: 'High/Low',
              bgColor: _blinkAlarm(pAlarm) ? kAccentColor : kSecondaryColor,
              onPress: () async {
                MinMaxData selectedValue = await _showRangeValuePickerDialogInt(
                    Ventilator.stringPressure,
                    MinMaxData(
                        min: ventilator
                            .getMinAlarmValue(Ventilator.stringPressure),
                        max: ventilator
                            .getMaxAlarmValue(Ventilator.stringPressure)),
                    'cmH2O',
                    kSecondaryColor,
                    kAccentColor,
                    false,
                    1);
                ventilator.setMinAlarmValue(
                    Ventilator.stringPressure, selectedValue.min);
                ventilator.setMaxAlarmValue(
                    Ventilator.stringPressure, selectedValue.max);
                dbHelper.insertLogData(LogData(
                    log: 'Set Alarm Limit : ' +
                        Ventilator.stringPressure +
                        ' between ' +
                        selectedValue.min.toStringAsFixed(0) +
                        ' to ' +
                        selectedValue.max.toStringAsFixed(0)));
              },
            ),
            AlarmBox(
              upperText: 'VT',
              lowerText: 'High/Low',
              bgColor: _blinkAlarm(vtEAlarm) ? kAccentColor : kSecondaryColor,
              onPress: () async {
                MinMaxData selectedValue = await _showRangeValuePickerDialogInt(
                    Ventilator.stringVTidal,
                    MinMaxData(
                        min: ventilator
                            .getMinAlarmValue(Ventilator.stringVTidal),
                        max: ventilator
                            .getMaxAlarmValue(Ventilator.stringVTidal)),
                    'ml',
                    kSecondaryColor,
                    kAccentColor,
                    false,
                    1);
                ventilator.setMinAlarmValue(
                    Ventilator.stringVTidal, selectedValue.min);
                ventilator.setMaxAlarmValue(
                    Ventilator.stringVTidal, selectedValue.max);
                dbHelper.insertLogData(LogData(
                    log: 'Set Alarm Limit : ' +
                        Ventilator.stringVTidal +
                        ' between ' +
                        selectedValue.min.toStringAsFixed(0) +
                        ' to ' +
                        selectedValue.max.toStringAsFixed(0)));
              },
            ),
          ],
        ),
      ),
      Expanded(
        child: Row(
          children: [
            AlarmBox(
              upperText: 'HU',
              lowerText: 'High/Low',
              bgColor: _blinkAlarm(hUAlarm) ? kAccentColor : kSecondaryColor,
              onPress: () async {
                MinMaxData selectedValue = await _showRangeValuePickerDialogInt(
                    Ventilator.stringHumidifier,
                    MinMaxData(
                        min: ventilator
                            .getMinAlarmValue(Ventilator.stringHumidifier),
                        max: ventilator
                            .getMaxAlarmValue(Ventilator.stringHumidifier)),
                    '%',
                    kSecondaryColor,
                    kAccentColor,
                    false,
                    1);
                ventilator.setMinAlarmValue(
                    Ventilator.stringHumidifier, selectedValue.min);
                ventilator.setMaxAlarmValue(
                    Ventilator.stringHumidifier, selectedValue.max);
                dbHelper.insertLogData(LogData(
                    log: 'Set Alarm Limit : ' +
                        Ventilator.stringHumidifier +
                        ' between ' +
                        selectedValue.min.toStringAsFixed(0) +
                        ' to ' +
                        selectedValue.max.toStringAsFixed(0)));
              },
            ),
            AlarmBox(
              upperText: 'T',
              lowerText: 'High/Low',
              bgColor: _blinkAlarm(tAlarm) ? kAccentColor : kSecondaryColor,
              onPress: () async {
                MinMaxData selectedValue = await _showRangeValuePickerDialogInt(
                    Ventilator.stringTemp,
                    MinMaxData(
                        min: ventilator.getMinAlarmValue(Ventilator.stringTemp),
                        max:
                            ventilator.getMaxAlarmValue(Ventilator.stringTemp)),
                    '°C',
                    kSecondaryColor,
                    kAccentColor,
                    false,
                    1);
                ventilator.setMinAlarmValue(
                    Ventilator.stringTemp, selectedValue.min);
                ventilator.setMaxAlarmValue(
                    Ventilator.stringTemp, selectedValue.max);
                dbHelper.insertLogData(LogData(
                    log: 'Set Alarm Limit : ' +
                        Ventilator.stringTemp +
                        ' between ' +
                        selectedValue.min.toStringAsFixed(0) +
                        ' to ' +
                        selectedValue.max.toStringAsFixed(0)));
              },
            ),
          ],
        ),
      ),
      Expanded(
        child: Row(
          children: [
            AlarmBox(
              upperText: 'UV',
              lowerText: 'Off',
              bgColor: _blinkAlarm(uvAlarm) ? kAccentColor : kSecondaryColor,
            ),
            AlarmBox(
              upperText: 'AC',
              lowerText: 'Off',
              bgColor: _blinkAlarm(acAlarm) ? kAccentColor : kSecondaryColor,
            ),
          ],
        ),
      ),
      Expanded(
        child: Row(
          children: [
            AlarmBox(
              upperText: 'BAT',
              lowerText: 'Low',
              bgColor: _blinkAlarm(batAlarm) ? kAccentColor : kSecondaryColor,
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _generateAlarmButton() {
    return <Widget>[
      AlarmBox(
        upperText: 'O2',
        lowerText: 'Supply Down',
        bgColor: _blinkAlarm(o2Alarm) ? kAccentColor : kSecondaryColor,
      ),
      AlarmBox(
        upperText: 'Air',
        lowerText: 'Supply Down',
        bgColor: _blinkAlarm(airAlarm) ? kAccentColor : kSecondaryColor,
      ),
      AlarmBox(
        upperText: 'FiO2',
        lowerText: 'High/Low',
        bgColor: _blinkAlarm(fiO2Alarm) ? kAccentColor : kSecondaryColor,
        onPress: () async {
          MinMaxData selectedValue = await _showRangeValuePickerDialogInt(
              Ventilator.stringFiO2,
              MinMaxData(
                  min: ventilator.getMinAlarmValue(Ventilator.stringFiO2),
                  max: ventilator.getMaxAlarmValue(Ventilator.stringFiO2)),
              '%',
              kSecondaryColor,
              kAccentColor,
              false,
              1);
          ventilator.setMinAlarmValue(Ventilator.stringFiO2, selectedValue.min);
          ventilator.setMaxAlarmValue(Ventilator.stringFiO2, selectedValue.max);
          dbHelper.insertLogData(LogData(
              log: 'Set Alarm Limit : ' +
                  Ventilator.stringFiO2 +
                  ' between ' +
                  selectedValue.min.toStringAsFixed(0) +
                  ' to ' +
                  selectedValue.max.toStringAsFixed(0)));
        },
      ),
      AlarmBox(
        upperText: 'MVe',
        lowerText: 'High/Low',
        bgColor: _blinkAlarm(mVeAlarm) ? kAccentColor : kSecondaryColor,
        onPress: () async {
          MinMaxData selectedValue = await _showRangeValuePickerDialogInt(
              Ventilator.stringMinuteVentilation,
              MinMaxData(
                  min: ventilator
                      .getMinAlarmValue(Ventilator.stringMinuteVentilation),
                  max: ventilator
                      .getMaxAlarmValue(Ventilator.stringMinuteVentilation)),
              'lpm',
              kSecondaryColor,
              kAccentColor,
              false,
              1);
          ventilator.setMinAlarmValue(
              Ventilator.stringMinuteVentilation, selectedValue.min);
          ventilator.setMaxAlarmValue(
              Ventilator.stringMinuteVentilation, selectedValue.max);
          dbHelper.insertLogData(LogData(
              log: 'Set Alarm Limit : ' +
                  Ventilator.stringMinuteVentilation +
                  ' between ' +
                  selectedValue.min.toStringAsFixed(0) +
                  ' to ' +
                  selectedValue.max.toStringAsFixed(0)));
        },
      ),
      AlarmBox(
        upperText: 'P',
        lowerText: 'High/Low',
        bgColor: _blinkAlarm(pAlarm) ? kAccentColor : kSecondaryColor,
        onPress: () async {
          MinMaxData selectedValue = await _showRangeValuePickerDialogInt(
              Ventilator.stringPressure,
              MinMaxData(
                  min: ventilator.getMinAlarmValue(Ventilator.stringPressure),
                  max: ventilator.getMaxAlarmValue(Ventilator.stringPressure)),
              'cmH2O',
              kSecondaryColor,
              kAccentColor,
              false,
              1);
          ventilator.setMinAlarmValue(
              Ventilator.stringPressure, selectedValue.min);
          ventilator.setMaxAlarmValue(
              Ventilator.stringPressure, selectedValue.max);
          dbHelper.insertLogData(LogData(
              log: 'Set Alarm Limit : ' +
                  Ventilator.stringPressure +
                  ' between ' +
                  selectedValue.min.toStringAsFixed(0) +
                  ' to ' +
                  selectedValue.max.toStringAsFixed(0)));
        },
      ),
      AlarmBox(
        upperText: 'VT',
        lowerText: 'High/Low',
        bgColor: _blinkAlarm(vtEAlarm) ? kAccentColor : kSecondaryColor,
        onPress: () async {
          MinMaxData selectedValue = await _showRangeValuePickerDialogInt(
              Ventilator.stringVTidal,
              MinMaxData(
                  min: ventilator.getMinAlarmValue(Ventilator.stringVTidal),
                  max: ventilator.getMaxAlarmValue(Ventilator.stringVTidal)),
              'ml',
              kSecondaryColor,
              kAccentColor,
              false,
              1);
          ventilator.setMinAlarmValue(
              Ventilator.stringVTidal, selectedValue.min);
          ventilator.setMaxAlarmValue(
              Ventilator.stringVTidal, selectedValue.max);
          dbHelper.insertLogData(LogData(
              log: 'Set Alarm Limit : ' +
                  Ventilator.stringVTidal +
                  ' between ' +
                  selectedValue.min.toStringAsFixed(0) +
                  ' to ' +
                  selectedValue.max.toStringAsFixed(0)));
        },
      ),
      AlarmBox(
        upperText: 'HU',
        lowerText: 'High/Low',
        bgColor: _blinkAlarm(hUAlarm) ? kAccentColor : kSecondaryColor,
        onPress: () async {
          MinMaxData selectedValue = await _showRangeValuePickerDialogInt(
              Ventilator.stringHumidifier,
              MinMaxData(
                  min: ventilator.getMinAlarmValue(Ventilator.stringHumidifier),
                  max:
                      ventilator.getMaxAlarmValue(Ventilator.stringHumidifier)),
              '%',
              kSecondaryColor,
              kAccentColor,
              false,
              1);
          ventilator.setMinAlarmValue(
              Ventilator.stringHumidifier, selectedValue.min);
          ventilator.setMaxAlarmValue(
              Ventilator.stringHumidifier, selectedValue.max);
          dbHelper.insertLogData(LogData(
              log: 'Set Alarm Limit : ' +
                  Ventilator.stringHumidifier +
                  ' between ' +
                  selectedValue.min.toStringAsFixed(0) +
                  ' to ' +
                  selectedValue.max.toStringAsFixed(0)));
        },
      ),
      AlarmBox(
        upperText: 'T',
        lowerText: 'High/Low',
        bgColor: _blinkAlarm(tAlarm) ? kAccentColor : kSecondaryColor,
        onPress: () async {
          MinMaxData selectedValue = await _showRangeValuePickerDialogInt(
              Ventilator.stringTemp,
              MinMaxData(
                  min: ventilator.getMinAlarmValue(Ventilator.stringTemp),
                  max: ventilator.getMaxAlarmValue(Ventilator.stringTemp)),
              '°C',
              kSecondaryColor,
              kAccentColor,
              false,
              1);
          ventilator.setMinAlarmValue(Ventilator.stringTemp, selectedValue.min);
          ventilator.setMaxAlarmValue(Ventilator.stringTemp, selectedValue.max);
          dbHelper.insertLogData(LogData(
              log: 'Set Alarm Limit : ' +
                  Ventilator.stringTemp +
                  ' between ' +
                  selectedValue.min.toStringAsFixed(0) +
                  ' to ' +
                  selectedValue.max.toStringAsFixed(0)));
        },
      ),
      AlarmBox(
        upperText: 'UV',
        lowerText: 'Off',
        bgColor: _blinkAlarm(uvAlarm) ? kAccentColor : kSecondaryColor,
      ),
      AlarmBox(
        upperText: 'AC',
        lowerText: 'Off',
        bgColor: _blinkAlarm(acAlarm) ? kAccentColor : kSecondaryColor,
      ),
      AlarmBox(
        upperText: 'BAT',
        lowerText: 'Low',
        bgColor: _blinkAlarm(batAlarm) ? kAccentColor : kSecondaryColor,
      ),
    ];
  }

  String _generateLungMovement(double value) {
    int vt = ventilator == null ? 100 : ventilator.getIdealVT();
    double rangeVT = vt / 8;
    double currentVT = value;
    double indexImageValue = currentVT / rangeVT;
    String path = '';

    indexImage = 10 + indexImageValue.toInt();

    if (indexImage > 19) {
      indexImage = 19;
    }
    if (indexImage < 13) {
      indexImage = 13;
    }

    path = 'images/' + indexImage.toString() + '.png';
    return path;
  }

  List<Widget> _generateControlDB() {
    return <Widget>[
      Expanded(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              child: ReusableCard(
                colour: kSecondaryColor,
                cardChild: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    FaIcon(
                      FontAwesomeIcons.searchPlus,
                      size: 40.0,
                    ),
                    Text(
                      InfoPage.iLength * 2 == 600 || InfoPage.iLength == 600
                          ? '1 Minute'
                          : ((InfoPage.iLength * 2) / 5).toStringAsFixed(0) +
                              ' seconds',
                      style: TextStyle(fontSize: 20.0),
                    ),
                  ],
                ),
                onPress: () {
                  if (InfoPage.iLength >= 300)
                    InfoPage.iLength = 600;
                  else
                    InfoPage.iLength = InfoPage.iLength * 2;

                  ventilator.setUPDBData();
                },
              ),
            ),
            Expanded(
              child: ReusableCard(
                colour: kSecondaryColor,
                cardChild: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    FaIcon(
                      FontAwesomeIcons.searchMinus,
                      size: 40.0,
                    ),
                    Text(
                      InfoPage.iLength == 75 || InfoPage.iLength / 2 == 75
                          ? '15 seconds'
                          : (InfoPage.iLength / 2 / 5).toStringAsFixed(0) +
                              ' seconds',
                      style: TextStyle(fontSize: 20.0),
                    ),
                  ],
                ),
                onPress: () {
                  InfoPage.iLength = (InfoPage.iLength ~/ 2);

                  if (InfoPage.iLength <= kDataWidth)
                    InfoPage.iLength = kDataWidth;
                  dbIndex = 0;
                  ventilator.setUPDBData();
                },
              ),
            ),
          ],
        ),
      ),
      Expanded(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              child: ReusableCard(
                colour: kSecondaryColor,
                cardChild: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    FaIcon(
                      FontAwesomeIcons.fastBackward,
                      size: 40.0,
                    ),
                    Text(
                      'Previous',
                      style: TextStyle(fontSize: 20.0),
                    ),
                  ],
                ),
                onPress: () {
                  if (InfoPage.iStart + InfoPage.iLength == 600) {
                    if (InfoDS.linfoDS.length == 600) {
                      InfoPage.iStartDB += 600;
                      getLogGraph();
                      InfoPage.iStart = 0;
                      dbIndex = InfoPage.iLength - 1;
                    }
                  } else {
                    if (InfoPage.iStart + InfoPage.iLength <
                        InfoDS.linfoDS.length)
                      InfoPage.iStart += InfoPage.iLength;
                  }

                  ventilator.setUPDBData();
                },
              ),
            ),
            Expanded(
              child: ReusableCard(
                colour: kSecondaryColor,
                cardChild: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    FaIcon(
                      FontAwesomeIcons.fastForward,
                      size: 40.0,
                    ),
                    Text(
                      'Next',
                      style: TextStyle(fontSize: 20.0),
                    ),
                  ],
                ),
                onPress: () {
                  if (InfoPage.iStart == 0) {
                    if (InfoPage.iStartDB != 0) {
                      InfoPage.iStartDB -= 600;
                      getLogGraph();
                      InfoPage.iStart = 600 - InfoPage.iLength;
                    }
                  } else {
                    InfoPage.iStart -= InfoPage.iLength;
                    dbIndex = 0;
                  }
                  ventilator.setUPDBData();
                },
              ),
            ),
          ],
        ),
      ),
      Expanded(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              child: ReusableCard(
                colour: kSecondaryColor,
                cardChild: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    FaIcon(
                      FontAwesomeIcons.clock,
                      size: 40.0,
                    ),
                    Text(
                      ventilator.getCreatedDS(dbIndex),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 20.0),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ReusableCard(
                colour: kAccentColor,
                cardChild: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    FaIcon(
                      FontAwesomeIcons.undoAlt,
                      size: 40.0,
                    ),
                    Text(
                      'Return',
                      style: TextStyle(fontSize: 20.0),
                    ),
                  ],
                ),
                onPress: () {
                  setState(() {
                    _infGrph = !_infGrph;
                  });
                },
              ),
            ),
          ],
        ),
      )
    ];
  }

  List<Widget> _generateLung() {
    return <Widget>[
      Visibility(
        visible: _selectedLoop == 'none' ? true : false,
        child: Expanded(
          flex: 5,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedLoop = 'vf';
              });
            },
            child: Column(
              children: <Widget>[
                Expanded(
                  flex: 3,
                  child: Container(
                    child: Image.asset(_generateLungMovement(ventilator == null
                        ? 0
                        : ventilator.getCurrentVolume())),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      Text(
                        'VT/ml',
                        style: TextStyle(fontSize: 50.0),
                      ),
                      Text(
                        ventilator == null
                            ? ''
                            : ventilator.getCurrentVTi().toInt().toString(),
                        style: TextStyle(fontSize: 80.0),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      Visibility(
        visible: _selectedLoop == 'vf' ? true : false,
        child: Expanded(
          flex: 5,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedLoop = 'pf';
              });
            },
            child: Column(
              children: <Widget>[
                Expanded(
                    flex: 3,
                    child: SimpleGraph(
                      minY: ventilator == null ? 0 : ventilator.getMinVTidal(),
                      maxY:
                          ventilator == null ? 100 : ventilator.getMaxVTidal(),
                      minX: ventilator == null ? 0 : ventilator.getMinFlow(),
                      maxX: ventilator == null ? 100 : ventilator.getMaxFlow(),
                      totalSegmentY: kLineSegment,
                      dataSet: ventilator == null
                          ? List()
                          : ventilator.getVolumeFlowDataSet(),
                      backgroundColor: kPrimaryColor,
                      lineColor: Colors.orangeAccent,
                      segmentYColor: Colors.white,
                    )),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      Text(
                        'Volume VS Flow',
                        style: TextStyle(fontSize: 30.0),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      Visibility(
        visible: _selectedLoop == 'pf' ? true : false,
        child: Expanded(
          flex: 5,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedLoop = 'pv';
              });
            },
            child: Column(
              children: <Widget>[
                Expanded(
                    flex: 3,
                    child: SimpleGraph(
                      minY: ventilator == null ? 0 : ventilator.getMinPaw(),
                      maxY: ventilator == null ? 100 : ventilator.getMaxPaw(),
                      minX: ventilator == null ? 0 : ventilator.getMinFlow(),
                      maxX: ventilator == null ? 100 : ventilator.getMaxFlow(),
                      totalSegmentY: kLineSegment,
                      dataSet: ventilator == null
                          ? List()
                          : ventilator.getPressureFlowDataSet(),
                      backgroundColor: kPrimaryColor,
                      lineColor: Colors.greenAccent,
                      segmentYColor: Colors.white,
                    )),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      Text(
                        'Pressure VS Flow',
                        style: TextStyle(fontSize: 30.0),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      Visibility(
        visible: _selectedLoop == 'pv' ? true : false,
        child: Expanded(
          flex: 5,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedLoop = 'none';
              });
            },
            child: Column(
              children: <Widget>[
                Expanded(
                    flex: 3,
                    child: SimpleGraph(
                      minY: ventilator == null ? 0 : ventilator.getMinPaw(),
                      maxY: ventilator == null ? 100 : ventilator.getMaxPaw(),
                      minX: ventilator == null ? 0 : ventilator.getMinVTidal(),
                      maxX:
                          ventilator == null ? 100 : ventilator.getMaxVTidal(),
                      totalSegmentY: kLineSegment,
                      dataSet: ventilator == null
                          ? List()
                          : ventilator.getPressureVolumeDataSet(),
                      backgroundColor: kPrimaryColor,
                      lineColor: Colors.yellowAccent,
                      segmentYColor: Colors.white,
                    )),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      Text(
                        'Pressure VS Volume',
                        style: TextStyle(fontSize: 30.0),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      Expanded(
        flex: 2,
        child: Row(
          children: [
            InfoBox(
              value: ventilator.getSPO2Value().toDouble(),
              upperText: 'SPO2',
              lowerText: '%',
              bgColor: kSecondaryColor,
              isInteger: true,
              onPress: () {
                if (_showETCO2Graph) _showETCO2Graph = false;
                _showSPO2Graph = !_showSPO2Graph;
              },
            ),
            InfoBox(
              value: ventilator.getETCO2Value().toDouble(),
              upperText: 'ETCO2',
              lowerText: 'mmHg',
              bgColor: kSecondaryColor,
              isInteger: true,
              onPress: () {
                if (_showSPO2Graph) _showSPO2Graph = false;
                _showETCO2Graph = !_showETCO2Graph;
              },
            ),
          ],
        ),
      ),
      Expanded(
        flex: 2,
        child: Row(
          children: <Widget>[
            Expanded(
              flex: 1,
              child: ReusableCard(
                onPress: () async {
                  if (_showETCO2Graph) _showETCO2Graph = false;
                  if (_showSPO2Graph) _showSPO2Graph = false;
                  InfoPage.iLength = kDataWidth;
                  InfoPage.iStartDB = 0;
                  InfoPage.iStart = 0;
                  InfoPage.startDate = DateTime.now().toString();
                  dbIndex = InfoPage.iLength - 1;
                  getLogGraph();
                  _infGrph = !_infGrph;
                },
                colour: kSecondaryColor,
                cardChild: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    FaIcon(
                      FontAwesomeIcons.chartLine,
                      size: 30.0,
                    ),
                    Text(
                      'Trend',
                      style: TextStyle(fontSize: 20.0),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ReusableCard(
                colour: kSecondaryColor,
                onPress: () {
                  _showInfo = true;
                },
                cardChild: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Expanded(
                      child: Center(
                        child: Text(
                          ventilator == null
                              ? ''
                              : 'Cycle : ' +
                                  ventilator.getCycleTime().toStringAsFixed(2),
                          style: TextStyle(fontSize: 20.0),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        ventilator == null
                            ? ''
                            : 'I : ' +
                                ventilator.getResInTime().toStringAsFixed(2) +
                                '\nE : ' +
                                ventilator.getResOutTime().toStringAsFixed(2),
                        style: TextStyle(fontSize: 18.0),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: ReusableCard(
                onPress: () async {
                  getLogCount();
                  LogPage.iStart = 0;
                  LogPage.iLength = 50;
                  getLog();
                  _showLog = true;
                },
                colour: kSecondaryColor,
                cardChild: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    FaIcon(
                      FontAwesomeIcons.list,
                      size: 30.0,
                    ),
                    Text(
                      'Log',
                      style: TextStyle(fontSize: 20.0),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _generateInformationBlock() {
    return <Widget>[
      Expanded(
        flex: 3,
        child: Column(
          children: [
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  InfoBox(
                    value: ventilator.getPPeakValue().toDouble(),
                    upperText: 'PPEAK',
                    lowerText: 'cmH2O',
                    bgColor: kSecondaryColor,
                    isInteger: true,
                  ),
                  InfoBox(
                    value: ventilator.getCurrentVTe().toDouble(),
                    upperText: 'VTe',
                    lowerText: 'ml',
                    bgColor: kSecondaryColor,
                    isInteger: true,
                  ),
                  InfoBox(
                    value: ventilator.getCurrentVTi().toDouble(),
                    upperText: 'VTi',
                    lowerText: 'ml',
                    bgColor: kSecondaryColor,
                    isInteger: true,
                  ),
                  InfoBox(
                    value: ventilator.getCurrentMve().toDouble(),
                    upperText: 'MVe',
                    lowerText: 'l/m',
                    bgColor: kSecondaryColor,
                    isInteger: false,
                  )
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  InfoBox(
                    value: ventilator.getPeepValue().toDouble(),
                    upperText: 'PEEP',
                    lowerText: 'cmH2O',
                    bgColor: kSecondaryColor,
                    isInteger: true,
                  ),
                  InfoBox(
                    value: ventilator.getFlowInsp().toDouble(),
                    upperText: 'Flow Insp',
                    lowerText: 'lpm',
                    bgColor: kSecondaryColor,
                    isInteger: false,
                  ),
                  InfoBox(
                    value: ventilator.getFlowExp().toDouble(),
                    upperText: 'Flow Resp',
                    lowerText: 'lpm',
                    bgColor: kSecondaryColor,
                    isInteger: false,
                  ),
                  InfoBox(
                    value: ventType != Ventilator.modeCMV &&
                            ventType != Ventilator.modePCMV
                        ? ventilator.getResOutTime() > ventilator.getResInTime()
                            ? double.parse((ventilator.getResOutTime() /
                                    ventilator.getResInTime())
                                .toStringAsFixed(1))
                            : double.parse((ventilator.getResInTime() /
                                    ventilator.getResOutTime())
                                .toStringAsFixed(1))
                        : ventilator.getIERatioValue(),
                    upperText: 'I/E Ratio',
                    lowerText: ventType != Ventilator.modeCMV &&
                            ventType != Ventilator.modePCMV
                        ? ventilator.getResOutTime() > ventilator.getResInTime()
                            ? '1 / '
                            : ' / 1'
                        : ventilator.isReverseIE()
                            ? ' / 1'
                            : '1 / ',
                    bgColor: kSecondaryColor,
                    isInteger: false,
                    frontUnit: ventType != Ventilator.modeCMV &&
                            ventType != Ventilator.modePCMV
                        ? ventilator.getResOutTime() > ventilator.getResInTime()
                            ? true
                            : false
                        : ventilator.isReverseIE()
                            ? false
                            : true,
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  InfoBox(
                    value: ventilator.getFlowTotal(),
                    upperText: 'Flow Total',
                    lowerText: 'lpm',
                    bgColor: kSecondaryColor,
                    isInteger: false,
                  ),
                  InfoBox(
                    value: ventilator.getAutoPeep().toDouble(),
                    upperText: 'Auto Peep',
                    lowerText: 'cmH2O',
                    bgColor: kSecondaryColor,
                    isInteger: true,
                  ),
                  InfoBox(
                    value: ventilator.getvtIBW(),
                    upperText: 'VT/IBW',
                    lowerText: 'ml/kg',
                    bgColor: kSecondaryColor,
                    isInteger: false,
                  ),
                  Expanded(
                    child: ReusableCard(
                      colour: kAccentColor,
                      cardChild: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          FaIcon(
                            FontAwesomeIcons.undoAlt,
                            size: 40.0,
                          ),
                          SizedBox(
                            width: 10.0,
                          ),
                          Text(
                            'Return',
                            style: TextStyle(fontSize: 20.0),
                          ),
                        ],
                      ),
                      onPress: () {
                        _showInfo = false;
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      Expanded(
        child: Column(
          children: _generateAlarmButtonSideWay(),
        ),
      ),
    ];
  }

  List<Widget> _generateLogInfo() {
    if (_lInfo.length != 0) {
      return <Widget>[
        Expanded(
          flex: 5,
          child: Column(
            children: <Widget>[
              Expanded(
                flex: 1,
                child: Row(
                  children: [
                    Expanded(
                      child: Padding(
                        child: Text(
                          'Machine Log',
                          style: TextStyle(fontSize: 30.0),
                          textAlign: TextAlign.left,
                        ),
                        padding: EdgeInsets.only(left: 10.0),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          'Usage Time : ' + ventilator.getDBDurationString(),
                          style: TextStyle(fontSize: 30.0),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(),
              Expanded(flex: 7, child: LogList(_lInfo)),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                child: ReusableCard(
                  colour: kSecondaryColor,
                  cardChild: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      FaIcon(
                        FontAwesomeIcons.fastForward,
                        size: 40.0,
                      ),
                      Text(
                        'Next',
                        style: TextStyle(fontSize: 20.0),
                      ),
                    ],
                  ),
                  onPress: () {
                    if (LogPage.iStart != 0)
                      LogPage.iStart = LogPage.iStart - LogPage.iLength;
                    getLog();
                  },
                ),
              ),
              Expanded(
                child: ReusableCard(
                  colour: kSecondaryColor,
                  cardChild: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      FaIcon(
                        FontAwesomeIcons.fastBackward,
                        size: 40.0,
                      ),
                      Text(
                        'Previous',
                        style: TextStyle(fontSize: 20.0),
                      ),
                    ],
                  ),
                  onPress: () {
                    getLogCount();
                    if (LogPage.iStart + LogPage.iLength <=
                        LogPage.iTotalData) {
                      LogPage.iLength = 50;
                      LogPage.iStart = LogPage.iStart + LogPage.iLength;

                      getLog();
                    }
                  },
                ),
              ),
              Expanded(
                child: ReusableCard(
                  colour: kAccentColor,
                  cardChild: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      FaIcon(
                        FontAwesomeIcons.undoAlt,
                        size: 40.0,
                      ),
                      Text(
                        'Return',
                        style: TextStyle(fontSize: 20.0),
                      ),
                    ],
                  ),
                  onPress: () {
                    _showLog = false;
                  },
                ),
              ),
            ],
          ),
        )
      ];
    }
    return <Widget>[
      Expanded(
        flex: 5,
        child: Column(
          children: <Widget>[
            Expanded(
              flex: 1,
              child: Center(
                child: Text(
                  'Machine Log',
                  style: TextStyle(fontSize: 30.0),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Divider(),
            Expanded(
              flex: 7,
              child: Center(child: CircularProgressIndicator()),
            ),
          ],
        ),
      ),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              child: ReusableCard(
                colour: kSecondaryColor,
                cardChild: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    FaIcon(
                      FontAwesomeIcons.fastForward,
                      size: 40.0,
                    ),
                    Text(
                      'Next',
                      style: TextStyle(fontSize: 20.0),
                    ),
                  ],
                ),
                onPress: () {
                  if (LogPage.iStart != 0)
                    LogPage.iStart = LogPage.iStart - LogPage.iLength;
                  getLog();
                },
              ),
            ),
            Expanded(
              child: ReusableCard(
                colour: kSecondaryColor,
                cardChild: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    FaIcon(
                      FontAwesomeIcons.fastBackward,
                      size: 40.0,
                    ),
                    Text(
                      'Previous',
                      style: TextStyle(fontSize: 20.0),
                    ),
                  ],
                ),
                onPress: () {
                  getLogCount();
                  if (LogPage.iStart + LogPage.iLength <= LogPage.iTotalData) {
                    LogPage.iLength = 50;
                    LogPage.iStart = LogPage.iStart + LogPage.iLength;

                    getLog();
                  }
                },
              ),
            ),
            Expanded(
              child: ReusableCard(
                colour: kAccentColor,
                cardChild: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    FaIcon(
                      FontAwesomeIcons.undoAlt,
                      size: 40.0,
                    ),
                    Text(
                      'Return',
                      style: TextStyle(fontSize: 20.0),
                    ),
                  ],
                ),
                onPress: () {
                  _showLog = false;
                },
              ),
            ),
          ],
        ),
      )
    ];
  }

  List<Widget> _generateGraphETCO2() {
    return <Widget>[
      Expanded(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: ReusableCard(
                colour: kSecondaryColor,
                cardChild: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      'ETCO2',
                      style: TextStyle(fontSize: 30.0),
                    ),
                    Text(
                      'mmHg',
                      style: TextStyle(fontSize: 20.0),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: GraphWithPointer(
                index: index,
                maxY: ventilator == null ? 100 : ventilator.getMaxETCO2(),
                minY: ventilator == null ? 0 : ventilator.getMinETCO2(),
                totalSegmentY: kLineSegment,
                dataSet: !_infGrph
                    ? ventilator == null
                        ? List()
                        : ventilator.getETCO2DataSet()
                    : ventilator == null
                        ? List()
                        : ventilator.getETCO2DataSet(),
                backgroundColor: kPrimaryColor,
                lineColor: Colors.red,
                segmentYColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _generateGraphSPO2() {
    return <Widget>[
      Expanded(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: ReusableCard(
                colour: kSecondaryColor,
                cardChild: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      'SPO2',
                      style: TextStyle(fontSize: 30.0),
                    ),
                    Text(
                      '%',
                      style: TextStyle(fontSize: 20.0),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: GraphWithPointer(
                index: index,
                maxY: ventilator == null ? 100 : ventilator.getMaxSPO2(),
                minY: ventilator == null ? 0 : ventilator.getMinSPO2(),
                totalSegmentY: kLineSegment,
                dataSet: !_infGrph
                    ? ventilator == null
                        ? List()
                        : ventilator.getSPO2DataSet()
                    : ventilator == null
                        ? List()
                        : ventilator.getSPO2DataSet(),
                backgroundColor: kPrimaryColor,
                lineColor: Colors.blue,
                segmentYColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _generateGraph() {
    return <Widget>[
      Visibility(
        visible: _graphPressed
            ? _selectedGraph == 'paw'
                ? true
                : false
            : true,
        child: Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _graphPressed = !_graphPressed;
                _selectedGraph = 'paw';
              });
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: ReusableCard(
                    colour: kSecondaryColor,
                    cardChild: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          'Paw',
                          style: TextStyle(fontSize: 30.0),
                        ),
                        Text(
                          'cmH2O',
                          style: TextStyle(fontSize: 20.0),
                        ),
                      ],
                    ),
                  ),
                ),
                Visibility(
                  visible: _infGrph,
                  child: Expanded(
                    flex: 4,
                    child: GraphWithPointer(
                      index: index,
                      maxY: ventilator == null ? 100 : ventilator.getMaxPaw(),
                      minY: ventilator == null ? 0 : ventilator.getMinPaw(),
                      totalSegmentY: kLineSegment,
                      dataSet: !_infGrph
                          ? ventilator == null
                              ? List()
                              : ventilator.getPawDataSet()
                          : ventilator == null
                              ? List()
                              : ventilator.getPawDataSet(),
                      backgroundColor: kPrimaryColor,
                      lineColor: Colors.orangeAccent,
                      segmentYColor: Colors.white,
                    ),
                  ),
                  replacement: Expanded(
                    flex: 4,
                    child: GestureDetector(
                      onPanUpdate: (details) {
                        if (details.delta.dx > 0) {
                          dbIndex++;
                          if (dbIndex > InfoPage.iLength - 1)
                            dbIndex = InfoPage.iLength - 1;
                        } else {
                          dbIndex--;
                          if (dbIndex < 0) dbIndex = 0;
                        }
                      },
                      child: GraphDBWithPointer(
                        index: dbIndex,
                        maxY: ventilator == null ? 100 : ventilator.getMaxPaw(),
                        minY: ventilator == null ? 0 : ventilator.getMinPaw(),
                        totalSegmentY: kLineSegment,
                        dataSet:
                            ventilator == null ? List() : ventilator.getPawDS(),
                        backgroundColor: kPrimaryColor,
                        lineColor: Colors.orangeAccent,
                        segmentYColor: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      Visibility(
        visible: _graphPressed
            ? _selectedGraph == 'vol'
                ? true
                : false
            : true,
        child: Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _graphPressed = !_graphPressed;
                _selectedGraph = 'vol';
              });
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: ReusableCard(
                    colour: kSecondaryColor,
                    cardChild: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          'VT',
                          style: TextStyle(fontSize: 30.0),
                        ),
                        Text(
                          'ml',
                          style: TextStyle(fontSize: 20.0),
                        ),
                      ],
                    ),
                  ),
                ),
                Visibility(
                  visible: _infGrph,
                  child: Expanded(
                    flex: 4,
                    child: GraphWithPointer(
                      index: index,
                      maxY:
                          ventilator == null ? 100 : ventilator.getMaxVTidal(),
                      minY: ventilator == null ? 0 : ventilator.getMinVTidal(),
                      totalSegmentY: kLineSegment,
                      dataSet: ventilator == null
                          ? List()
                          : ventilator.getVTidalDataSet(),
                      backgroundColor: kPrimaryColor,
                      lineColor: Colors.yellowAccent,
                      segmentYColor: Colors.white,
                    ),
                  ),
                  replacement: Expanded(
                    flex: 4,
                    child: GestureDetector(
                      onPanUpdate: (details) {
                        if (details.delta.dx > 0) {
                          dbIndex++;
                          if (dbIndex > InfoPage.iLength - 1)
                            dbIndex = InfoPage.iLength - 1;
                        } else {
                          dbIndex--;
                          if (dbIndex < 0) dbIndex = 0;
                        }
                      },
                      child: GraphDBWithPointer(
                        index: dbIndex,
                        maxY: ventilator == null
                            ? 100
                            : ventilator.getMaxVTidal(),
                        minY:
                            ventilator == null ? 0 : ventilator.getMinVTidal(),
                        totalSegmentY: kLineSegment,
                        dataSet: !_infGrph
                            ? ventilator == null
                                ? List()
                                : ventilator.getVTidalDS()
                            : ventilator == null
                                ? List()
                                : ventilator.getVTidalDataSet(),
                        backgroundColor: kPrimaryColor,
                        lineColor: Colors.yellowAccent,
                        segmentYColor: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      Visibility(
        visible: _graphPressed
            ? _selectedGraph == 'flow'
                ? true
                : false
            : true,
        child: Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _graphPressed = !_graphPressed;
                _selectedGraph = 'flow';
              });
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: ReusableCard(
                    colour: kSecondaryColor,
                    cardChild: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          'Flow',
                          style: TextStyle(fontSize: 30.0),
                        ),
                        Text(
                          'lpm',
                          style: TextStyle(fontSize: 20.0),
                        ),
                      ],
                    ),
                  ),
                ),
                Visibility(
                  visible: _infGrph,
                  child: Expanded(
                    flex: 4,
                    child: GraphWithPointer(
                      index: index,
                      maxY: ventilator == null ? 100 : ventilator.getMaxFlow(),
                      minY:
                          ventilator == null ? 0 : ventilator.getMaxFlow() * -1,
                      totalSegmentY: kLineSegment,
                      dataSet: ventilator == null
                          ? List()
                          : ventilator.getFlowDataSet(),
                      backgroundColor: kPrimaryColor,
                      lineColor: Colors.greenAccent,
                      segmentYColor: Colors.white,
                    ),
                  ),
                  replacement: Expanded(
                    flex: 4,
                    child: GestureDetector(
                      onPanUpdate: (details) {
                        if (details.delta.dx > 0) {
                          dbIndex++;
                          if (dbIndex > InfoPage.iLength - 1)
                            dbIndex = InfoPage.iLength - 1;
                        } else {
                          dbIndex--;
                          if (dbIndex < 0) dbIndex = 0;
                        }
                      },
                      child: GraphDBWithPointer(
                        index: dbIndex,
                        maxY:
                            ventilator == null ? 100 : ventilator.getMaxFlow(),
                        minY: ventilator == null
                            ? 0
                            : ventilator.getMaxFlow() * -1,
                        totalSegmentY: kLineSegment,
                        dataSet: !_infGrph
                            ? ventilator == null
                                ? List()
                                : ventilator.getFlowDS()
                            : ventilator == null
                                ? List()
                                : ventilator.getFlowDS(),
                        backgroundColor: kPrimaryColor,
                        lineColor: Colors.greenAccent,
                        segmentYColor: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ];
  }

  Widget _generateCalibrationScreen() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              child: ReusableCard(
                colour: ventilator == null
                    ? kSecondaryColor
                    : !ventilator.getConnection()
                        ? kSecondaryColor
                        : ventilator.getAirLeakCheckStatus()
                            ? Colors.green
                            : kAccentColor,
                cardChild: Center(
                  child: Text(
                    'Air Leakage',
                    style: TextStyle(fontSize: 30.0),
                  ),
                ),
                onPress: () {
                  if (ventilator.getConnection() &&
                      !flagStatus &&
                      !ventilator.getAirLeakCheckStatus()) {
                    ventilator.checkAirLeak();
                    stringStatus = 'Air';
                    status = 'Checking';
                    flagStatus = true;
                    dbHelper.insertLogData(
                        LogData(log: 'Pre Use Check :  ' + stringStatus));
                  }
                },
              ),
            ),
            SizedBox(
              height: 10.0,
            ),
            Expanded(
              child: ReusableCard(
                colour: ventilator == null
                    ? kSecondaryColor
                    : !ventilator.getConnection()
                        ? kSecondaryColor
                        : ventilator.getSensorFlowCheckStatus()
                            ? Colors.green
                            : kAccentColor,
                cardChild: Center(
                  child: Text(
                    'Sensor (Flow)',
                    style: TextStyle(fontSize: 30.0),
                  ),
                ),
                onPress: () {
                  if (ventilator.getConnection() &&
                      !flagStatus &&
                      !ventilator.getSensorFlowCheckStatus()) {
                    ventilator.clearDataSet();
                    _calibStart = true;
                    ventilator.checkFlow();
                    stringStatus = 'Flow';
                    status = 'Checking';
                    flagStatus = true;
                    dbHelper.insertLogData(
                        LogData(log: 'Pre Use Check :  ' + stringStatus));
                  }
                },
              ),
            ),
            SizedBox(
              height: 10.0,
            ),
            Expanded(
              child: ReusableCard(
                colour: ventilator == null
                    ? kSecondaryColor
                    : !ventilator.getConnection()
                        ? kSecondaryColor
                        : ventilator.getSensorPressureCheckStatus()
                            ? Colors.green
                            : kAccentColor,
                cardChild: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Sensor (Pressure)',
                      style: TextStyle(fontSize: 30.0),
                    ),
                  ),
                ),
                onPress: () {
                  if (ventilator.getConnection() &&
                      !flagStatus &&
                      !ventilator.getSensorPressureCheckStatus()) {
                    ventilator.clearDataSet();
                    _calibStart = true;
                    ventilator.checkPressure();
                    stringStatus = 'Pressure';
                    status = 'Checking';
                    flagStatus = true;
                    dbHelper.insertLogData(
                        LogData(log: 'Pre Use Check :  ' + stringStatus));
                  }
                },
              ),
            ),
            SizedBox(
              height: 10.0,
            ),
            Expanded(
              child: ReusableCard(
                colour: ventilator == null
                    ? kSecondaryColor
                    : !ventilator.getConnection()
                        ? kSecondaryColor
                        : ventilator.getSensorO2CheckStatus()
                            ? Colors.green
                            : kAccentColor,
                cardChild: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Sensor (O2)',
                      style: TextStyle(fontSize: 30.0),
                    ),
                  ),
                ),
                onPress: () {
                  if (ventilator.getConnection() &&
                      !flagStatus &&
                      !ventilator.getSensorO2CheckStatus()) {
                    ventilator.checkO2();
                    stringStatus = 'O2 Cell';
                    status = 'Checking';
                    flagStatus = true;
                    dbHelper.insertLogData(
                        LogData(log: 'Pre Use Check :  ' + stringStatus));
                  }
                },
              ),
            ),
            SizedBox(
              height: 10.0,
            ),
            Expanded(
              child: ReusableCard(
                colour: ventilator == null
                    ? kSecondaryColor
                    : !ventilator.getConnection()
                        ? kSecondaryColor
                        : ventilator.getInitMachineStatus()
                            ? Colors.green
                            : kAccentColor,
                cardChild: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Initialize Machine',
                      style: TextStyle(fontSize: 30.0),
                    ),
                  ),
                ),
                onPress: () {
                  if (ventilator.getConnection() &&
                      !flagStatus &&
                      !ventilator.getInitMachineStatus()) {
                    ventilator.initMachine();
                    ventilator.clearDataSet();
                    stringStatus = 'Init';
                    status = 'Checking';
                    flagStatus = true;
                    dbHelper.insertLogData(
                        LogData(log: 'Pre Use Check :  ' + stringStatus));
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _generateOptionSelection(StreamController<String> controller) {
    return AlertDialog(
      title: Text(
        'Patient Option',
        style: TextStyle(fontSize: 30.0),
        textAlign: TextAlign.center,
      ),
      backgroundColor: kSecondaryColor,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10.0))),
      content: StreamBuilder(
        stream: controller.stream,
        builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
          return SizedBox(
            height: 200.0,
            width: 500.0,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Center(
                          child: Text(
                            'Option',
                            style: TextStyle(fontSize: 20.0),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 50.0,
                      ),
                      Expanded(
                        child: ReusableCard(
                          colour: snapshot.hasData
                              ? snapshot.data == Ventilator.optionAdult
                                  ? kAccentColor
                                  : kSecondaryColor
                              : patientType == Ventilator.optionAdult
                                  ? kAccentColor
                                  : kSecondaryColor,
                          cardChild: Center(
                            child: Text(
                              Ventilator.optionAdult,
                              style: TextStyle(fontSize: 20.0),
                            ),
                          ),
                          onPress: () {
                            controller.add(Ventilator.optionAdult);
                          },
                        ),
                      ),
                      SizedBox(
                        width: 10.0,
                      ),
                      Expanded(
                        child: ReusableCard(
                          colour: snapshot.hasData
                              ? snapshot.data == Ventilator.optionPediatric
                                  ? kAccentColor
                                  : kSecondaryColor
                              : patientType == Ventilator.optionPediatric
                                  ? kAccentColor
                                  : kSecondaryColor,
                          cardChild: Center(
                            child: Text(
                              Ventilator.optionPediatric,
                              style: TextStyle(fontSize: 20.0),
                            ),
                          ),
                          onPress: () {
                            controller.add(Ventilator.optionPediatric);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 20.0,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    Expanded(
                      child: MaterialButton(
                        height: 50.0,
                        elevation: 2.0,
                        color: kSecondaryColor,
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(10.0))),
                        onPressed: () {
                          patientType = snapshot.data;
                          ventilator.setPatientType(patientType);

                          // Use the second argument of Navigator.pop(...) to pass
                          // back a result to the page that opened the dialog
                          Navigator.pop(context, true);
                        },
                        child: Text(
                          'YES',
                          style: TextStyle(fontSize: 20.0),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 30.0,
                    ),
                    Expanded(
                      child: MaterialButton(
                        height: 50.0,
                        elevation: 2.0,
                        color: kAccentColor,
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(10.0))),
                        onPressed: () {
                          // Use the second argument of Navigator.pop(...) to pass
                          // back a result to the page that opened the dialog
                          Navigator.pop(context, false);
                        },
                        child: Text(
                          'NO',
                          style: TextStyle(fontSize: 20.0),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _generateVentSelection(StreamController<String> controller) {
    return AlertDialog(
      title: Text(
        'Ventilation Mode',
        style: TextStyle(fontSize: 30.0),
        textAlign: TextAlign.center,
      ),
      backgroundColor: kSecondaryColor,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10.0))),
      content: StreamBuilder(
        stream: controller.stream,
        builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
          return SizedBox(
            height: 400.0,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Center(
                          child: Text(
                            'Volume Cycle',
                            style: TextStyle(fontSize: 20.0),
                          ),
                        ),
                      ),
                      Expanded(
                        child: SizedBox(
                          width: 1.0,
                        ),
                      ),
                      Expanded(
                        child: ReusableCard(
                          colour: snapshot.hasData
                              ? snapshot.data == Ventilator.modeCMV
                                  ? kAccentColor
                                  : kSecondaryColor
                              : ventType == Ventilator.modeCMV
                                  ? kAccentColor
                                  : kSecondaryColor,
                          cardChild: Center(
                            child: Text(
                              Ventilator.modeCMV,
                              style: TextStyle(fontSize: 20.0),
                            ),
                          ),
                          onPress: () {
                            controller.add(Ventilator.modeCMV);
                          },
                        ),
                      ),
                      Expanded(
                        child: ReusableCard(
                          colour: snapshot.hasData
                              ? snapshot.data == Ventilator.modeSIMV
                                  ? kAccentColor
                                  : kSecondaryColor
                              : ventType == Ventilator.modeSIMV
                                  ? kAccentColor
                                  : kSecondaryColor,
                          cardChild: Center(
                            child: Text(
                              Ventilator.modeSIMV,
                              style: TextStyle(fontSize: 20.0),
                            ),
                          ),
                          onPress: () {
                            controller.add(Ventilator.modeSIMV);
                          },
                        ),
                      ),
                      Expanded(
                        child: ReusableCard(
                          colour: snapshot.hasData
                              ? snapshot.data == Ventilator.modeSCMV
                                  ? kAccentColor
                                  : kSecondaryColor
                              : ventType == Ventilator.modeSCMV
                                  ? kAccentColor
                                  : kSecondaryColor,
                          cardChild: Center(
                            child: Text(
                              Ventilator.modeSCMV,
                              style: TextStyle(fontSize: 20.0),
                            ),
                          ),
                          onPress: () {
                            controller.add(Ventilator.modeSCMV);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Expanded(
                        child: Center(
                          child: Text(
                            'Pressure Cycle',
                            style: TextStyle(fontSize: 20.0),
                          ),
                        ),
                      ),
                      Expanded(
                        child: ReusableCard(
                          colour: snapshot.hasData
                              ? snapshot.data == Ventilator.modePSV
                                  ? kAccentColor
                                  : kSecondaryColor
                              : ventType == Ventilator.modePSV
                                  ? kAccentColor
                                  : kSecondaryColor,
                          cardChild: Center(
                            child: Text(
                              Ventilator.modePSV,
                              style: TextStyle(fontSize: 20.0),
                            ),
                          ),
                          onPress: () {
                            controller.add(Ventilator.modePSV);
                          },
                        ),
                      ),
                      Expanded(
                        child: ReusableCard(
                          colour: snapshot.hasData
                              ? snapshot.data == Ventilator.modePCMV
                                  ? kAccentColor
                                  : kSecondaryColor
                              : ventType == Ventilator.modePCMV
                                  ? kAccentColor
                                  : kSecondaryColor,
                          cardChild: Center(
                            child: Text(
                              Ventilator.modePCMV,
                              style: TextStyle(fontSize: 20.0),
                            ),
                          ),
                          onPress: () {
                            controller.add(Ventilator.modePCMV);
                          },
                        ),
                      ),
                      Expanded(
                        child: ReusableCard(
                          colour: snapshot.hasData
                              ? snapshot.data == Ventilator.modePSIMV
                                  ? kAccentColor
                                  : kSecondaryColor
                              : ventType == Ventilator.modePSIMV
                                  ? kAccentColor
                                  : kSecondaryColor,
                          cardChild: Center(
                            child: Text(
                              Ventilator.modePSIMV,
                              style: TextStyle(fontSize: 20.0),
                            ),
                          ),
                          onPress: () {
                            controller.add(Ventilator.modePSIMV);
                          },
                        ),
                      ),
                      Expanded(
                        child: ReusableCard(
                          colour: snapshot.hasData
                              ? snapshot.data == Ventilator.modeCPAP
                                  ? kAccentColor
                                  : kSecondaryColor
                              : ventType == Ventilator.modeCPAP
                                  ? kAccentColor
                                  : kSecondaryColor,
                          cardChild: Center(
                            child: Text(
                              Ventilator.modeCPAP,
                              style: TextStyle(fontSize: 20.0),
                            ),
                          ),
                          onPress: () {
                            controller.add(Ventilator.modeCPAP);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 20.0,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    Expanded(
                      child: MaterialButton(
                        height: 50.0,
                        elevation: 2.0,
                        color: kSecondaryColor,
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(10.0))),
                        onPressed: () {
                          ventType = snapshot.data;
                          ventilator.setVentMode(ventType);

                          // Use the second argument of Navigator.pop(...) to pass
                          // back a result to the page that opened the dialog
                          Navigator.pop(context, true);
                        },
                        child: Text(
                          'YES',
                          style: TextStyle(fontSize: 20.0),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 30.0,
                    ),
                    Expanded(
                      child: MaterialButton(
                        height: 50.0,
                        elevation: 2.0,
                        color: kAccentColor,
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(10.0))),
                        onPressed: () {
                          // Use the second argument of Navigator.pop(...) to pass
                          // back a result to the page that opened the dialog
                          Navigator.pop(context, false);
                        },
                        child: Text(
                          'NO',
                          style: TextStyle(fontSize: 20.0),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _generateInformationScreen() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: <Widget>[
            Expanded(
              flex: 2,
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            'PPeak',
                            style: TextStyle(
                                fontSize: 20.0, color: Colors.yellowAccent),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            ventilator.getPPeakValue().toString(),
                            textAlign: TextAlign.right,
                            style: TextStyle(
                                fontSize: 80.0,
                                fontWeight: FontWeight.bold,
                                color: Colors.yellowAccent),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            'AUTO PEEP',
                            style: TextStyle(
                                fontSize: 20.0, color: Colors.yellowAccent),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            ventilator.getAutoPeep().toString(),
                            textAlign: TextAlign.right,
                            style: TextStyle(
                                fontSize: 80.0,
                                fontWeight: FontWeight.bold,
                                color: Colors.yellowAccent),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Expanded(
                            child: Align(
                              alignment: Alignment.bottomLeft,
                              child: Text(
                                'RR (bmp)',
                                style: TextStyle(
                                    fontSize: 20.0, color: Colors.greenAccent),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    ventType != Ventilator.modeCMV &&
                                            ventType != Ventilator.modePCMV
                                        ? ventilator.getActualRR().toString()
                                        : ventilator
                                            .getRestRateValue()
                                            .toString(),
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                        fontSize: 80.0,
                                        fontWeight: FontWeight.bold,
                                        color: ventilator.getFlagCPAP()
                                            ? Colors.blueAccent
                                            : Colors.greenAccent),
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    children: <Widget>[
                                      Expanded(
                                        child: Container(
                                          child: Center(
                                            child: Text(
                                              ventilator
                                                  .getMaxSettingValue(
                                                      Ventilator.stringResRate)
                                                  .toInt()
                                                  .toString(),
                                              style: TextStyle(
                                                  fontSize: 20.0,
                                                  color: Colors.greenAccent),
                                            ),
                                          ),
                                          margin: EdgeInsets.all(3.0),
                                          decoration: BoxDecoration(
                                              border: Border.all(
                                                  color: Colors.greenAccent)),
                                        ),
                                      ),
                                      Expanded(
                                        child: Container(
                                          child: Center(
                                            child: Text(
                                              ventilator
                                                  .getMinSettingValue(
                                                      Ventilator.stringResRate)
                                                  .toInt()
                                                  .toString(),
                                              style: TextStyle(
                                                  fontSize: 20.0,
                                                  color: Colors.greenAccent),
                                            ),
                                          ),
                                          margin: EdgeInsets.all(3.0),
                                          decoration: BoxDecoration(
                                              border: Border.all(
                                                  color: Colors.greenAccent)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Expanded(
                            child: Align(
                              alignment: Alignment.bottomLeft,
                              child: Text(
                                'FiO2 (%)',
                                style: TextStyle(
                                    fontSize: 20.0, color: Colors.greenAccent),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    ventilator.getCurrentFiO2Value().toString(),
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                        fontSize: 80.0,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.greenAccent),
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    children: <Widget>[
                                      Expanded(
                                        child: Container(
                                          child: Center(
                                            child: Text(
                                              ventilator
                                                  .getMaxSettingValue(
                                                      Ventilator.stringFiO2)
                                                  .toInt()
                                                  .toString(),
                                              style: TextStyle(
                                                  fontSize: 20.0,
                                                  color: Colors.greenAccent),
                                            ),
                                          ),
                                          margin: EdgeInsets.all(3.0),
                                          decoration: BoxDecoration(
                                              border: Border.all(
                                                  color: Colors.greenAccent)),
                                        ),
                                      ),
                                      Expanded(
                                        child: Container(
                                          child: Center(
                                            child: Text(
                                              ventilator
                                                  .getMinSettingValue(
                                                      Ventilator.stringFiO2)
                                                  .toInt()
                                                  .toString(),
                                              style: TextStyle(
                                                  fontSize: 20.0,
                                                  color: Colors.greenAccent),
                                            ),
                                          ),
                                          margin: EdgeInsets.all(3.0),
                                          decoration: BoxDecoration(
                                              border: Border.all(
                                                  color: Colors.greenAccent)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 1,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: Text(
                      ventType != Ventilator.modeCMV &&
                              ventType != Ventilator.modePCMV
                          ? ventilator.getActualIERatio()
                          : ventilator.isReverseIE()
                              ? 'I/E Ratio ' +
                                  ventilator.getIERatioValue().toString() +
                                  ' : 1'
                              : 'I/E Ratio 1 : ' +
                                  ventilator.getIERatioValue().toString(),
                      textAlign: TextAlign.right,
                      style: TextStyle(
                          fontSize: 65.0,
                          fontWeight: FontWeight.bold,
                          color: ventilator.getFlagCPAP()
                              ? Colors.blueAccent
                              : Colors.greenAccent),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomLeft,
                            child: Text(
                              'Flow (lpm)',
                              style:
                                  TextStyle(fontSize: 20.0, color: Colors.cyan),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                flex: 2,
                                child: Text(
                                  ventilator
                                      .getCurrentFlowValue()
                                      .toStringAsFixed(1),
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                      fontSize: 80.0,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.cyan),
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  children: <Widget>[
                                    Expanded(
                                      child: Container(
                                        child: Center(
                                          child: Text(
                                            ventilator
                                                .getMaxFlow()
                                                .toInt()
                                                .toString(),
                                            style: TextStyle(
                                                fontSize: 20.0,
                                                color: Colors.cyan),
                                          ),
                                        ),
                                        margin: EdgeInsets.all(3.0),
                                        decoration: BoxDecoration(
                                            border:
                                                Border.all(color: Colors.cyan)),
                                      ),
                                    ),
                                    Expanded(
                                      child: Container(
                                        child: Center(
                                          child: Text(
                                            ventilator
                                                .getMinFlow()
                                                .toInt()
                                                .toString(),
                                            style: TextStyle(
                                                fontSize: 20.0,
                                                color: Colors.cyan),
                                          ),
                                        ),
                                        margin: EdgeInsets.all(3.0),
                                        decoration: BoxDecoration(
                                            border:
                                                Border.all(color: Colors.cyan)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: Column(
                        children: <Widget>[
                          Expanded(
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  flex: 2,
                                  child: Align(
                                    alignment: Alignment.bottomCenter,
                                    child: Text(
                                      'HU (%)',
                                      style: TextStyle(
                                          fontSize: 25.0, color: Colors.cyan),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.bottomCenter,
                                    child: Text(
                                      ventilator.getCurrentHuValue().toString(),
                                      style: TextStyle(
                                          fontSize: 25.0, color: Colors.cyan),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  flex: 2,
                                  child: Align(
                                    alignment: Alignment.center,
                                    child: Text(
                                      'T (C)',
                                      style: TextStyle(
                                          fontSize: 25.0, color: Colors.cyan),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.center,
                                    child: Text(
                                      ventilator
                                          .getTemperatureValue()
                                          .toString(),
                                      style: TextStyle(
                                          fontSize: 25.0, color: Colors.cyan),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIOverlays([]);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
    ]);

    return WillPopScope(
      onWillPop: () async {
        bool _exit = await _showConfirmationDialog(
            'Stop Monitoring?',
            Text(
              'Do You Want to Stop Monitoring Machine?',
              style: TextStyle(fontSize: 20.0),
            ));
        if (_exit) {
          ventilator.connectionStop();
          SystemNavigator.pop();
        }
        return _exit;
      },
      child: Scaffold(
        appBar: _generateHeader(),
        body: Column(
          children: <Widget>[
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: ventilator.getCalibrationStatus() &&
                        ventilator.getConnection()
                    ? _generateStatusRow()
                    : _generateEmptyBlock(),
              ),
            ),
            Expanded(
              flex: 5,
              child: ventilator.getCalibrationStatus() &&
                      ventilator.getConnection()
                  ? _generateMonitorScreen()
                  : _generateInitialScreen(),
            ),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: ventilator.getCalibrationStatus() &&
                        ventilator.getConnection()
                    ? _generateSettingButtons()
                    : _generateStatusText(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _generateMonitorScreen() {
    return Row(
      children: _showInfo
          ? _generateInformationBlock()
          : <Widget>[
              Expanded(
                flex: 3,
                child: Column(
                  ///_generateInformationScreen
                  children: <Widget>[
                    Expanded(
                      flex: 5,
                      child: Row(
                        children: _showLog
                            ? _generateLogInfo()
                            : <Widget>[
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    children: _showSPO2Graph
                                        ? _generateGraphSPO2()
                                        : _showETCO2Graph
                                            ? _generateGraphETCO2()
                                            : _generateGraph(),
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: _infGrph
                                        ? _generateLung()
                                        : _generateControlDB(),
                                  ),
                                ),
                              ],
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Row(
                        children: _generateAlarmButton(),
                      ),
                    ),
                  ],
                ),
              ),
              _generateInformationScreen(),
            ],
    );
  }

  Widget _ventilatorSeries() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  child:
                      Hero(tag: 'logo', child: Image.asset('images/logo.png')),
                  width: 500.0,
                ),
                Text(
                  "Ventilator",
                  textAlign: TextAlign.right,
                  style: TextStyle(fontSize: 40.0),
                ),
              ],
            ),
            Divider(
              height: 50.0,
            ),
            Text(
              "900 SE AHR Series",
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 40.0),
            )
          ],
        ),
      ),
    );
  }

  Widget _generateInitialScreen() {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Text(
              'INITIAL CALIBRATION',
              style: TextStyle(
                fontSize: 40.0,
              ),
            ),
          ),
        ),
        Divider(
          height: 25.0,
        ),
        Expanded(
          flex: 5,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Visibility(
                visible: stringStatus == 'Flow',
                child: Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: ReusableCard(
                          colour: kSecondaryColor,
                          cardChild: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              Text(
                                'Flow',
                                style: TextStyle(fontSize: 30.0),
                              ),
                              Text(
                                'lpm',
                                style: TextStyle(fontSize: 20.0),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 5,
                        child: GraphWithPointer(
                          index: index,
                          maxY: ventilator == null
                              ? 100
                              : ventilator.getMaxFlow(),
                          minY: ventilator == null
                              ? 0
                              : ventilator.getMaxFlow() * -1,
                          totalSegmentY: kLineSegment,
                          dataSet: ventilator == null
                              ? List()
                              : ventilator.getFlowDataSet(),
                          backgroundColor: kPrimaryColor,
                          lineColor: Colors.greenAccent,
                          segmentYColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Visibility(
                visible: stringStatus == 'Pressure',
                child: Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: ReusableCard(
                          colour: kSecondaryColor,
                          cardChild: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              Text(
                                'Paw',
                                style: TextStyle(fontSize: 30.0),
                              ),
                              Text(
                                'cmH2O',
                                style: TextStyle(fontSize: 20.0),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 5,
                        child: GraphWithPointer(
                          index: index,
                          maxY:
                              ventilator == null ? 100 : ventilator.getMaxPaw(),
                          minY: ventilator == null ? 0 : ventilator.getMinPaw(),
                          totalSegmentY: kLineSegment,
                          dataSet: ventilator == null
                              ? List()
                              : ventilator.getPawDataSet(),
                          backgroundColor: kPrimaryColor,
                          lineColor: Colors.orangeAccent,
                          segmentYColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Visibility(
                  visible: stringStatus != 'Flow' && stringStatus != 'Pressure',
                  child: _ventilatorSeries()),
              Expanded(
                child: Column(
                  children: [
                    _generateCalibrationScreen(),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 20.0,
        ),
      ],
    );
  }
}

class LogList extends StatefulWidget {
  final List<InfoLog> logList;

  LogList(this.logList);
  @override
  _LogListState createState() => _LogListState();
}

class _LogListState extends State<LogList> {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        shrinkWrap: true,
        itemCount: widget.logList.length,
        itemBuilder: (BuildContext context, int index) {
          return LogCard(
            date: widget.logList[index].datelog,
            log: widget.logList[index].remark,
          );
        });
  }
}
