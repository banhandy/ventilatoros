import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:usb_serial/usb_serial.dart';
import 'constants.dart';
import 'package:flutter/services.dart';
import 'package:soundpool/soundpool.dart';
import 'dtmodel.dart';
import 'component/database_helper.dart';
import 'component/info.dart';
import 'package:uuid/uuid.dart';
import 'package:sqflite/sqflite.dart';
import 'package:usb_serial/transaction.dart' as Tran;
import 'dart:typed_data';
import 'package:flutter_beep/flutter_beep.dart';

class Ventilator {
  //for connection via usb
  UsbPort _port;
  StreamSubscription<String> _subscription;
  Tran.Transaction<String> _transaction;
  int _deviceId;

  bool _connected = false;

  ///buat db
  DbHelper dbHelper = DbHelper();
  var uuid = Uuid();
  List<InfoGrafik> vList;
  int _ivList = 0;
  List _pawDS = List();
  List _vTidalDS = List();
  List _flowDS = List();
  List _createdAtDS = List();
  int _dbDuration;

  Soundpool _soundpool = Soundpool();
  Future<int> _soundId;
  int _alarmSoundStreamId;

  static const String genderMale = 'MALE';
  static const String genderFemale = 'FEMALE';
  static const String modeCPAP = 'CPAP';
  static const String modeCMV = 'V-CMV';
  static const String modeSCMV = '(S)V-CMV';
  static const String modePSV = 'PSV';
  static const String modeSIMV = 'SIMV';
  static const String modePSIMV = 'P-SIMV';
  static const String modePCMV = 'P-CMV';
  static const String modeSpontaneous = 'SPONTAN';
  static const String optionAdult = 'ADULT';
  static const String optionPediatric = 'PEDIATRIC';
  static const String optionNeoNatal = 'NEO NATAL';
  static const String stringFiO2 = 'FiO2';
  static const String stringVTidal = 'VOLUME TIDAL';
  static const String stringPeep = 'PEEP';
  static const String stringPressure = 'PRESSURE';
  static const String stringFlow = 'FLOW';
  static const String stringHumidifier = 'HUMIDIFIER';
  static const String stringTemp = 'TEMPERATURE';
  static const String stringMinuteVentilation = 'MINUTE VENTILATION';
  static const String stringResRate = 'RESPIRATION RATE';
  static const String stringIERatio = 'I/E RATIO';
  static const String stringOverPressure = 'OVER PRESSURE';
  static const String stringSpontaneousBreath = 'SPONTANEOUS BREATH';
  static const String stringPTrigger = 'PRESSURE TRIGGER';
  static const String stringFTrigger = 'FLOW TRIGGER';

  String ventType;
  String patientType;
  final int patientHeight;
  final String patientGender;

  double _weight = 0.0;

  bool _ePeep = false;
  int _iLoop = 0;
  int _tempLoop = 0;
  double _tempResInTime = 0;
  int _tempLoopValue = 0;
  bool _cycleChanged = false;
  bool _insp = false;
  double _cycleTime = 0;
  double _resInTime = 0;
  double _resOutTime = 0;
  int _pPeakValue = 0;
  int _loopValue = 0;
  bool _calibrate = false;
  bool _initMachine = false;
  bool _sensorFlow = false;
  bool _sensorPressure = false;
  bool _sensorO2 = false;
  bool _airLeak = false;
  bool _reverseIE = false;
  bool _calibFlag = false;

  int _overPressure = 50;
  double _minOverPressure = 50;
  double _maxOverPressure = 80;

  bool _leakage = false;
  int _difPressure = 0;
  int _prevPressure = 0;

  String _triggerSelected = stringPTrigger;
  bool _triggered = false;
  int _pTriggerValue = -10;
  double _minPTrigger = -20;
  double _maxPTrigger = 0;
  int _currentPTrigger = 0;

  int _fTriggerValue = 10;
  double _maxFTrigger = 20;
  double _minFTrigger = 1;
  double _currentFTrigger = 0;

  int _fio2Value = 21;
  double _minFiO2 = 21;
  double _maxFiO2 = 100;

  int _peepValue = 0;
  double _minPEEP = 0;
  double _maxPEEP = 20;

  int _humidifierValue = 75;
  double _minHumidifier = 0;
  double _maxHumidifier = 100;

  int _resRateValue = 15;
  int _actualRRValue = 0;
  double _minRestRate = 10;
  double _maxRestRate = 30;

  double _ieRatioValue = 2;
  String _actualIERatio = 'I/E Ratio 1 : 2';
  double _minIERatio = 1;
  double _maxIERatio = 4;

  DateTime _start;
  int _diff = 0;
  bool _isVenting = false;
  bool _respirationRateVisible;
  bool _flowVisible;
  bool _ieRatioVisible;
  bool _pressureVisible;
  bool _volumeVisible;
  bool _inspHold;
  bool _flagCPAP = false;
  int _actualLoop = 0;
  int _spontanBreathValue = 1;
  double _minSpontanBreath = 1;
  double _maxSpontanBreath = 2;
  int _flagSpontan = 0;
  bool _flagStartInsp = false;
  bool _setVT = false;

  bool _bluetoothError = false;

  int _pressureValue = 0;
  double _minPaw = 0;
  double _maxPaw = 0;
  List _pawDataSet = List(kDataWidth);

  double _flowValue = 0;
  double _minFlow = 0;
  double _maxFlow = 0;
  List _flowDataSet = List(kDataWidth);

  int _vTidalValue = 0;
  double _minVTidal = 0;
  double _maxVTidal = 0;
  List _vTidalDataSet = List(kDataWidth);

  String _mode = '-';
  String _option = '-';
  String _command = '';
  bool _ventStart = true;

  int _index = 0;
  List<int> _buffer = List<int>();
  double _currentFlow = 0;
  double _currentVolume = 0;

  double _vt = 0;

  ///5 charging, 4 full (100%), 3 3Quater(75%), 2 half(50%), 1 quarter(25%)
  int _batteryStatus = 3;
  int _tempValue = 0;
  int _huValue = 0;
  int _o2Flag = 0;
  int _airFlag = 0;
  int _uvFlag = 0;
  int _currentFio2Value = 21;
  int _currentSPO2 = 0;
  double _minSPO2 = 0;
  double _maxSPO2 = 100;
  List _SPO2DataSet = List(kDataWidth);

  int _currentETCO2 = 0;
  double _minETCO2 = 0;
  double _maxETCO2 = 100;
  List _ETCO2DataSet = List(kDataWidth);

  double _huAlarmMax = 90;
  double _huAlarmMin = 50;
  double _vteAlarmMax = 600;
  double _vteAlarmMin = 50;
  double _pAlarmMax = 80;
  double _pAlarmMin = 10;
  double _mveAlarmMax = 90;
  double _mveAlarmMin = 50;
  double _fioAlarmMax = 90;
  double _fioAlarmMin = 30;
  double _tempAlarmMax = 50;
  double _tempAlarmMin = 40;
  double _minTemp = 0;
  double _maxTemp = 100;
  double _minMVe = 0;
  double _maxMVe = 100;

  double _currentMVe = 0;
  double _currentVTe = 0;
  double _currentVTi = 0;
  double _currentVT = 0;
  int _currentPeep = 0;
  double _currentPaw = 0;
  double _flowIns = 0;
  double _flowExp = 0;
  double _flow = 0;

  List<GraphXYData> _volumeFlowDataSet = List<GraphXYData>();
  List<GraphXYData> _pressureFlowDataSet = List<GraphXYData>();
  List<GraphXYData> _pressureVolumeDataSet = List<GraphXYData>();

  Ventilator(
      {this.ventType,
      this.patientType,
      this.patientHeight,
      this.patientGender}) {
    UsbSerial.usbEventStream.listen((UsbEvent event) {
      _getPorts();
    });
    _getPorts();

    _start = DateTime.now();
    _inspHold = false;

    ///check db length
    dbHelper.initgraphDb();
    checkOverData();
    //getLogGraph();
    getDBDuration();

    setVentType();
    initDataSet();
    calculateCycle();
    _calculateWeight();

    _soundId = _loadSound();
  }

  double getMaxETCO2() {
    return _maxETCO2;
  }

  double getMinETCO2() {
    return _minETCO2;
  }

  double getMaxSPO2() {
    return _maxSPO2;
  }

  double getMinSPO2() {
    return _minSPO2;
  }

  List getETCO2DataSet() {
    return _ETCO2DataSet;
  }

  List getSPO2DataSet() {
    return _SPO2DataSet;
  }

  String getSelectedTrigger() {
    return _triggerSelected;
  }

  int getPTrigger() {
    return _pTriggerValue;
  }

  int getFTrigger() {
    return _fTriggerValue;
  }

  int getCurrentPaw() {
    return _currentPaw.toInt();
  }

  void setFTrigger(int value) {
    _fTriggerValue = value;
  }

  void setPTrigger(int value) {
    _pTriggerValue = value;
  }

  void switchTrigger() {
    _triggerSelected == Ventilator.stringPTrigger
        ? _triggerSelected = Ventilator.stringFTrigger
        : _triggerSelected = Ventilator.stringPTrigger;
  }

  int getSpontanBreath() {
    return _spontanBreathValue;
  }

  void setSpontanBreath(value) {
    _spontanBreathValue = value;
    if (_index != 0) _cycleChanged = true;
    calculateCycle();
  }

  int getIdealVT() {
    return _weight.toInt() * 4;
  }

  void _calculateWeight() {
    if (patientGender == genderMale) {
      _weight = 30 + ((patientHeight - 130) / 2 * 1.8);
    } else {
      _weight = 25.6 + ((patientHeight - 130) / 2 * 1.85);
    }
    _calculateIdealVT();
  }

  int _calculateVT() {
    return (_flowValue / 60 * 1000 * _resInTime).toInt();
  }

  double _calculateFlow() {
    return _vTidalValue / 1000 / _resInTime * 60;
  }

  void _roundVT() async {
    double roundVT = 0;
    roundVT = _vTidalValue / 100;
    int tempRound = 0;
    tempRound = roundVT.toInt();
    double tempDigit = 0;
    tempDigit = roundVT - tempRound;
    if (tempDigit > 0.5)
      tempDigit = 1;
    else
      tempDigit = 0.5;
    roundVT = tempRound.toDouble() + tempDigit;
    roundVT = roundVT * 100;
    _vTidalValue = roundVT.toInt();
    _command = "v." + _vTidalValue.toString() + "\n";
    await _port.write(Uint8List.fromList(_command.codeUnits));
  }

  void _calculateIdealVT() {
    _vTidalValue = (_weight * kVtIBW).toInt();
    _roundVT();
    double newFlow = _calculateFlow();
    setFlowValue(_roundFlow(newFlow));
  }

  void setReverseIE() async {
    _reverseIE = !_reverseIE;
    if (_reverseIE) {
      _command = "i." + (_ieRatioValue * 10).toString() + "\n";
      await _port.write(Uint8List.fromList(_command.codeUnits));
      _command = "e.10\n";
      await _port.write(Uint8List.fromList(_command.codeUnits));
    } else {
      _command = "i.10\n";
      await _port.write(Uint8List.fromList(_command.codeUnits));
      _command = "e." + (_ieRatioValue * 10).toString() + "\n";
      await _port.write(Uint8List.fromList(_command.codeUnits));
    }
    if (_index != 0) _cycleChanged = true;
    calculateCycle();
  }

  bool isReverseIE() {
    return _reverseIE;
  }

  double getWeight() {
    return _weight;
  }

  double getFlowInsp() {
    return _flowIns;
  }

  double getFlowExp() {
    return _flowExp;
  }

  void preCheckList() {
    if (_airLeak && _sensorPressure && _initMachine && _sensorFlow && _sensorO2)
      _calibrate = true;
  }

  int getBatteryStatus() {
    return _batteryStatus;
  }

  int getAutoPeep() {
    return _currentPeep <= _peepValue ? 0 : _currentPeep - _peepValue;
  }

  double getvtIBW() {
    return _currentVTi / _weight;
  }

  double getFlowTotal() {
    return _flowIns + _flowExp;
  }

  int getSPO2Value() {
    return _currentSPO2;
  }

  int getETCO2Value() {
    return _currentETCO2;
  }

  int getCurrentFiO2Value() {
    return _currentFio2Value;
  }

  void resetCheckList() {
    _airLeak = false;
    _sensorO2 = false;
    _sensorPressure = false;
    _initMachine = false;
    _sensorFlow = false;
    _calibrate = false;
  }

  void clearDataSet() {
    for (int i = 0; i < kDataWidth; i++) {
      _pawDataSet[i] = 0;
      _flowDataSet[i] = 0;
      _vTidalDataSet[i] = 0;
    }
    //_pawDataSet.clear();
    //_pawDataSet = generateDataSet();
    //_flowDataSet.clear();
    //_flowDataSet = generateDataSet();
    //_vTidalDataSet.clear();
    //_vTidalDataSet = generateDataSet();
    _pressureFlowDataSet.clear();
    _pressureVolumeDataSet.clear();
    _volumeFlowDataSet.clear();
  }

  void checkPEEP() async {
    if (_currentPaw <= _peepValue) {
      if (!_ePeep) {
        _ePeep = true;
        _command = 'D.\n';
        await _port.write(Uint8List.fromList(_command.codeUnits));
      }
    } else {
      if (_ePeep) {
        _ePeep = false;
        _command = 'C.\n';
        await _port.write(Uint8List.fromList(_command.codeUnits));
      }
    }
  }

  /* void getArdruinoData() {
    connection.input.listen((data) {
      _buffer += data;

      while (true) {
        // If there is a sample, and it is full sent

        int flag1 = _buffer.indexOf('w'.codeUnitAt(0));
        if (flag1 == 0) {
          _initMachine = true;
          preCheckList();
          setMachineInitData();
          _buffer.removeRange(0, 1);
        }

        int flag2 = _buffer.indexOf('x'.codeUnitAt(0));
        if (flag2 == 0) {
          _sensorFlow = true;
          _calibFlag = false;
          preCheckList();
          _buffer.removeRange(0, 1);
        }

        int flag3 = _buffer.indexOf('y'.codeUnitAt(0));
        if (flag3 == 0) {
          _sensorPressure = true;
          _calibFlag = false;
          preCheckList();
          _buffer.removeRange(0, 1);
        }

        int flag4 = _buffer.indexOf('z'.codeUnitAt(0));
        if (flag4 == 0) {
          _airLeak = true;
          preCheckList();
          _buffer.removeRange(0, 1);
        }

        int flag5 = _buffer.indexOf('m'.codeUnitAt(0));
        if (flag5 == 0) {
          _sensorO2 = true;
          preCheckList();
          _buffer.removeRange(0, 1);
        }

        int flag9 = _buffer.indexOf('t'.codeUnitAt(0));
        if (flag9 >= 0 && _buffer.length - flag9 >= 11) {
          ///get flow value from machine
          int _flagFlow = _buffer[flag9 + 1];
          _flow = _buffer[flag9 + 2] + (_buffer[flag9 + 3] / 100);

          if (_flagFlow == 1)
            _currentFlow = _flow * -1;
          else
            _currentFlow = _flow;

          _currentVolume = _currentVolume + (_currentFlow / 60 * 200);
          if (_currentVolume < 0) _currentVolume = 0;

          ///cari leak
          _prevPressure = _currentPaw.toInt();

          ///get pressure value from machine
          int _flagPaw = _buffer[flag9 + 4];
          _currentPaw = _buffer[flag9 + 5].toDouble();
          if (_flagPaw == 1) _currentPaw = _currentPaw * -1;

          ///cari leak
          _difPressure = _prevPressure - _currentPaw.toInt();
          if ((_difPressure) > 25)
            _leakage = true;
          else
            _leakage = false;

          if (_leakage) _triggerLeak();
          int _flagFTrigger = _buffer[flag9 + 6];
          _currentFTrigger = _buffer[flag9 + 7] + (_buffer[flag9 + 8] / 100);
          if (_flagFTrigger == 1) {
            _currentFTrigger = _currentFTrigger * -1;
          }

          int _flagPTrigger = _buffer[flag9 + 9];
          _currentPTrigger = _buffer[flag9 + 10];

          if (_flagPTrigger == 1) _currentPTrigger = _currentPTrigger * -1;

          if (_triggerSelected == Ventilator.stringFTrigger
              ? _currentFlow >= _fTriggerValue
              : _currentPaw <= _pTriggerValue) _triggered = true;

          ///cari PPeak
          if (_currentPaw > _pPeakValue) _pPeakValue = _currentPaw.toInt();

          ///buat xy untuk grafik
          GraphXYData pf = GraphXYData(
              y: _currentPaw,
              x: _currentFlow < 0 ? _currentFlow * -1 : _currentFlow);
          GraphXYData vf = GraphXYData(
              y: _currentVolume,
              x: _currentFlow < 0 ? _currentFlow * -1 : _currentFlow);
          GraphXYData pV = GraphXYData(y: _currentPaw, x: _currentVolume);
          _volumeFlowDataSet.add(vf);
          _pressureVolumeDataSet.add(pV);
          _pressureFlowDataSet.add(pf);

          ///simpan _currentflow, _currentvolume, paw
          if (!_calibFlag) {
            var _v1 = uuid.v1();
            _inserDbGraph(_currentPaw, _currentVolume, _currentFlow, _v1);
          }

          setFlowDataSet(_index, _currentFlow);
          setPawDataSet(_index, _currentPaw);
          setVTidalDataSet(_index, _currentVolume);

          checkPEEP();

          ///untuk grafik SPO2 yang 1 detik
          setSPO2DataSet(_index, _currentSPO2.toDouble());
          _index++;
          if (_index == kDataWidth) _index = 0;

          _buffer.removeRange(0, flag9 + 11);
        }

        int flag6 = _buffer.indexOf('l'.codeUnitAt(0));
        if (flag6 >= 0 && _buffer.length - flag6 >= 2) {
          _currentETCO2 = _buffer[flag6 + 1];
          setETCO2DataSet(_index, _currentETCO2.toDouble());
          _buffer.removeRange(0, flag6 + 2);
        }

        int flag7 = _buffer.indexOf('a'.codeUnitAt(0));
        if (flag7 >= 0 && _buffer.length - flag7 >= 8) {
          _batteryStatus = _buffer[flag7 + 1];
          _uvFlag = _buffer[flag7 + 2];
          _o2Flag = _buffer[flag7 + 3];
          _airFlag = _buffer[flag7 + 4];
          _currentFio2Value = _buffer[flag7 + 5];
          _tempValue = _buffer[flag7 + 6];
          _huValue = _buffer[flag7 + 7];

          _buffer.removeRange(0, flag7 + 8);
        }

        int flag8 = _buffer.indexOf('v'.codeUnitAt(0));
        if (flag8 >= 0 && _buffer.length - flag8 >= 2) {
          _currentSPO2 = _buffer[flag8 + 1];
          setSPO2DataSet(_index, _currentSPO2.toDouble());
          _buffer.removeRange(0, flag8 + 2);
        } else {
          break;
        }
      }
    }).onDone(() {
      _connected = false;
      _bluetoothError = true;
      print('Disconnected by remote request');
    });
  }
*/
  void calculateCycle() {
    switch (ventType) {
      case modePSIMV:
      case modeSIMV:
        _tempLoop = _iLoop;
        _tempResInTime = _resInTime;
        _tempLoopValue = (_cycleTime * 10).toInt();

        _cycleTime = 60 / (_resRateValue * (_spontanBreathValue + 1));
        _loopValue = (_cycleTime * 10).toInt();

        if (_reverseIE) {
          _resInTime = (_cycleTime / (1 + _ieRatioValue)) * _ieRatioValue;
          _resOutTime = (_cycleTime / (1 + _ieRatioValue)) * 1;
        } else {
          _resInTime = (_cycleTime / (1 + _ieRatioValue)) * 1;
          _resOutTime = (_cycleTime / (1 + _ieRatioValue)) * _ieRatioValue;
        }
        _flagSpontan = 0;
        _iLoop = 0;
        _actualLoop = 0;
        _pressureFlowDataSet.clear();
        _pressureVolumeDataSet.clear();
        _volumeFlowDataSet.clear();
        break;
      case modeCMV:
      case modePCMV:
        _tempLoop = _iLoop;
        _tempResInTime = _resInTime;
        _tempLoopValue = (_cycleTime * 10).toInt();

        _cycleTime = 60 / _resRateValue;
        _loopValue = (_cycleTime * 10).toInt();
        if (_reverseIE) {
          _resInTime = (_cycleTime / (1 + _ieRatioValue)) * _ieRatioValue;
          _resOutTime = (_cycleTime / (1 + _ieRatioValue)) * 1;
        } else {
          _resInTime = (_cycleTime / (1 + _ieRatioValue)) * 1;
          _resOutTime = (_cycleTime / (1 + _ieRatioValue)) * _ieRatioValue;
        }

        _iLoop = 0;
        _actualLoop = 0;
        _pressureFlowDataSet.clear();
        _pressureVolumeDataSet.clear();
        _volumeFlowDataSet.clear();
        break;
      default:
        _tempLoop = _iLoop;
        _tempResInTime = _resInTime;
        _tempLoopValue = (_cycleTime * 10).toInt();

        _cycleTime = 60 / _resRateValue;
        _loopValue = (_cycleTime * 10).toInt();
        if (_reverseIE) {
          _resInTime = (_cycleTime / (1 + _ieRatioValue)) * _ieRatioValue;
          _resOutTime = (_cycleTime / (1 + _ieRatioValue)) * 1;
        } else {
          _resInTime = (_cycleTime / (1 + _ieRatioValue)) * 1;
          _resOutTime = (_cycleTime / (1 + _ieRatioValue)) * _ieRatioValue;
        }

        _iLoop = 0;
        _actualLoop = 0;
        _pressureFlowDataSet.clear();
        _pressureVolumeDataSet.clear();
        _volumeFlowDataSet.clear();
        break;
    }
  }

  bool getCalibrationStatus() {
    return _calibrate;
  }

  bool getInitMachineStatus() {
    return _initMachine;
  }

  bool getSensorFlowCheckStatus() {
    return _sensorFlow;
  }

  double getActualFlow() {
    return _flow;
  }

  bool getSensorO2CheckStatus() {
    return _sensorO2;
  }

  bool getSensorPressureCheckStatus() {
    return _sensorPressure;
  }

  bool getAirLeakCheckStatus() {
    return _airLeak;
  }

  double getCycleTime() {
    return _cycleTime;
  }

  double getResInTime() {
    return _resInTime;
  }

  double getResOutTime() {
    return _resOutTime;
  }

  double getCycle() {
    return _cycleTime * 1000 / 200;
  }

  double getCurrentMve() {
    return _currentMVe;
  }

  double getCurrentVTe() {
    return _currentVTe;
  }

  double getCurrentVTi() {
    return _currentVTi;
  }

  int getCurrentPEEP() {
    return _currentPeep;
  }

  double getCurrentVT() {
    return _currentVT;
  }

  void _triggerLeak() async {
    _command = 'B.\n';
    await _port.write(Uint8List.fromList(_command.codeUnits));
  }

  void _psvMode() async {
    if (_triggered) {
      if (_flagCPAP) _flagCPAP = false;
      if (_cycleChanged ? _tempLoop == 0 : _iLoop == 0) {
        _currentVTe = (_currentVTi - _currentVolume);
        _flowExp = _currentVTe / 1000 / _resOutTime * 60;
        _currentVT = _currentVTe + _currentVTi;
        _currentMVe = _currentVTi / 1000 * _resRateValue;
        _insp = true;
        _command = '1.\n';
        _currentVolume = 0;
        //_vt = 0;
        _pPeakValue = 0;
        _currentFlow = 0;
        _currentPeep = _currentPaw.toInt();
        _pressureFlowDataSet.clear();
        _pressureVolumeDataSet.clear();
        _volumeFlowDataSet.clear();
        await _port.write(Uint8List.fromList(_command.codeUnits));
      } //else
      if (_cycleChanged
          ? _tempLoop > _tempResInTime * 5 && _insp
          : _iLoop > _resInTime * 5 && _insp) {
        _command = '2.\n';
        await _port.write(Uint8List.fromList(_command.codeUnits));
        _insp = false;
        _currentVTi = _currentVolume;
        _flowIns = _currentVTi / 1000 / _resInTime * 60;
      }

      if (_cycleChanged ? _tempLoop < _tempLoopValue : _iLoop < _loopValue) {
        _cycleChanged ? _tempLoop++ : _iLoop++;
      } else {
        _playSound();
        _cycleChanged = false;
        //_cycleTime = _cycleTime + (_actualLoop * 200 / 1000);
        /*if (_reverseIE) {
          _resInTime = (_cycleTime / (1 + _ieRatioValue)) * _ieRatioValue;
          _resOutTime = (_cycleTime / (1 + _ieRatioValue)) * 1;
        } else {
          _resInTime = (_cycleTime / (1 + _ieRatioValue)) * 1;
          _resOutTime = (_cycleTime / (1 + _ieRatioValue)) * _ieRatioValue;
        }*/
        _actualRRValue = 60 ~/ (_cycleTime + (_actualLoop * 200 / 1000));
        //_loopValue = (_cycleTime * 5).toInt();
        _iLoop = 0;

        _actualLoop = 0;
        _flagStartInsp = false;
        _triggered = false;
      }
    } else {
      //if (!_flagCPAP) {
      _flagCPAP = true;
      _command = '4.\n';
      await _port.write(Uint8List.fromList(_command.codeUnits));
      //}
      _actualLoop++;
      /*if (_currentFlow > 0) _flagStartInsp = true;
      if (_flagStartInsp) _actualLoop++;

      if (_currentFlow > 0 && !_insp && _actualLoop > _resInTime * 5) {
        _cycleTime = (_actualLoop - 1) * 200 / 1000;
        _resOutTime = _cycleTime - _resInTime;
        _actualRRValue = 60 ~/ _cycleTime;
        _currentMVe = _currentVTi / 1000 * _actualRRValue;
        if (_resOutTime > _resInTime) {
          _actualIERatio =
              'I/E Ratio 1 : ' + (_resOutTime / _resInTime).toStringAsFixed(1);
        } else {
          _actualIERatio = 'I/E Ratio ' +
              (_resInTime / _resOutTime).toStringAsFixed(1) +
              ' : 1';
        }
        _actualLoop = 0;
        _playSound();
        _flagStartInsp = false;
      }

      if (_currentFlow > 0 && _actualLoop == 1) {
        _insp = true;
        _currentVTe = (_currentVTi - _currentVolume);
        _flowExp = _currentVTe / 1000 / _resOutTime * 60;
        _currentVT = _currentVTe + _currentVTi;

        _currentVolume = 0;
        //_vt = 0;
        _pPeakValue = 0;
        _currentFlow = 0;
        _currentPeep = _currentPaw.toInt();
        _pressureFlowDataSet.clear();
        _pressureVolumeDataSet.clear();
        _volumeFlowDataSet.clear();
      } else if (_currentFlow < 0 && _insp) {
        _insp = false;
        _currentVTi = _currentVolume;
        _resInTime = (_actualLoop - 1) * 200 / 1000;
        _flowIns = _currentVTi / 1000 / _resInTime * 60;
      }*/

    }
    //_command = '3';
    //connection.output.add(utf8.encode(_command + "\r\n"));
  }

  void _cpapMode() async {
    if (!_flagCPAP) {
      ///hilangin kirim 4 trs
      _flagCPAP = true;
      _command = '4.\n';
      await _port.write(Uint8List.fromList(_command.codeUnits));
    }

    if (_currentFlow > 0) _flagStartInsp = true;
    if (_flagStartInsp) _actualLoop++;

    if (_currentFlow >= 0 && !_insp && _actualLoop > _resInTime * 5) {
      _cycleTime = (_actualLoop - 1) * 200 / 1000;
      _resOutTime = _cycleTime - _resInTime;
      _actualRRValue = 60 ~/ _cycleTime;
      _currentMVe = _currentVTi / 1000 * _actualRRValue;
      if (_resOutTime > _resInTime) {
        _actualIERatio =
            'I/E Ratio 1 : ' + (_resOutTime / _resInTime).toStringAsFixed(1);
      } else {
        _actualIERatio = 'I/E Ratio ' +
            (_resInTime / _resOutTime).toStringAsFixed(1) +
            ' : 1';
      }
      _actualLoop = 0;
      _playSound();
      _flagStartInsp = false;
    }

    if (_currentFlow > 0 && _actualLoop == 1) {
      _insp = true;
      _currentVTe = (_currentVTi - _currentVolume);
      _flowExp = _currentVTe / 1000 / _resOutTime * 60;
      _currentVT = _currentVTe + _currentVTi;

      _currentVolume = 0;
      //_vt = 0;
      _pPeakValue = 0;
      _currentFlow = 0;
      _currentPeep = _currentPaw.toInt();
      _pressureFlowDataSet.clear();
      _pressureVolumeDataSet.clear();
      _volumeFlowDataSet.clear();
    } else if (_currentFlow < 0 && _insp) {
      _insp = false;
      _currentVTi = _currentVolume;
      _resInTime = (_actualLoop - 1) * 200 / 1000;
      _flowIns = _currentVTi / 1000 / _resInTime * 60;
    }
    //_command = '3';
    //connection.output.add(utf8.encode(_command + "\r\n"));
  }

  int getActualRR() {
    return _actualRRValue;
  }

  String getActualIERatio() {
    return _actualIERatio;
  }

  void _newSimvMode() async {
    double _tempResInTime = 0;
    if (_flagSpontan == 0) {
      if (_flagCPAP) _flagCPAP = false;
      if (_cycleChanged ? _tempLoop == 0 : _iLoop == 0) {
        _currentVTe = (_currentVTi - _currentVolume);
        _flowExp = _currentVTe / 1000 / _resOutTime * 60;
        _currentVT = _currentVTe + _currentVTi;
        _currentMVe = _currentVTi / 1000 * _resRateValue;
        _insp = true;
        _command = '1.\n';
        _currentVolume = 0;
        //_vt = 0;
        _pPeakValue = 0;
        _currentFlow = 0;
        _currentPeep = _currentPaw.toInt();
        _pressureFlowDataSet.clear();
        _pressureVolumeDataSet.clear();
        _volumeFlowDataSet.clear();
        await _port.write(Uint8List.fromList(_command.codeUnits));
      } //else
      if (_cycleChanged
          ? _tempLoop > _tempResInTime * 5 && _insp
          : _iLoop > _resInTime * 5 && _insp) {
        _command = '2.\n';
        await _port.write(Uint8List.fromList(_command.codeUnits));
        _insp = false;
        _currentVTi = _currentVolume;
        _flowIns = _currentVTi / 1000 / _resInTime * 60;
      }

      if (_cycleChanged ? _tempLoop < _tempLoopValue : _iLoop < _loopValue) {
        _cycleChanged ? _tempLoop++ : _iLoop++;
      } else {
        _playSound();
        _cycleChanged = false;
        _iLoop = 0;
        _flagSpontan++;
        _actualLoop = 0;
        _flagStartInsp = false;
      }
      /*if (_cycleChanged
          ? _tempLoop < _tempLoopValue - 1
          : _iLoop < _loopValue - 1) {
        _cycleChanged ? _tempLoop++ : _iLoop++;
      } else {
        _playSound();
        _cycleChanged = false;
        _iLoop = 0;
        _flagSpontan++;
        _actualLoop = 0;
        _flagStartInsp = false;
      }
      if (_cycleChanged ? _tempLoop == 1 : _iLoop == 1) {
        _currentVTe = (_currentVTi - _currentVolume);
        _flowExp = _currentVTe / 1000 / _resOutTime * 60;
        _currentVT = _currentVTe + _currentVTi;
        _currentMVe = _currentVTi / 1000 * _resRateValue;
        _insp = true;
        _command = '1';
        _currentVolume = 0;
        //_vt = 0;
        _pPeakValue = 0;
        _currentFlow = 0;
        _currentPeep = _currentPaw.toInt();
        _pressureFlowDataSet.clear();
        _pressureVolumeDataSet.clear();
        _volumeFlowDataSet.clear();
        connection.output.add(utf8.encode(_command + "\r\n"));
      } //else
      if (_cycleChanged
          ? _tempLoop > _tempResInTime * 5 && _insp
          : _iLoop > _resInTime * 5 && _insp) {
        _command = '2';
        connection.output.add(utf8.encode(_command + "\r\n"));
        _insp = false;
        _currentVTi = _currentVolume;
        _flowIns = _currentVTi / 1000 / _resInTime * 60;
      }*/
    } else if (_iLoop < _loopValue) {
      if (!_flagCPAP) {
        ///hilangin kirim 4 trs
        _flagCPAP = true;
        _command = '4.\n';
        await _port.write(Uint8List.fromList(_command.codeUnits));
        // _tempResInTime = _resInTime;
      }
      if (_currentFlow > 0) _flagStartInsp = true;
      if (_flagStartInsp) _actualLoop++;

      if (_currentFlow > 0 && !_insp && _actualLoop > _resInTime * 5) {
        if (_flagSpontan == 1)
          _cycleTime = (_actualLoop - 2) * 200 / 1000;
        else
          _cycleTime = (_actualLoop - 1) * 200 / 1000;
        _resOutTime = _cycleTime - _resInTime;
        _actualRRValue = 60 ~/ _cycleTime;
        _currentMVe = _currentVTi / 1000 * _actualRRValue;
        if (_resOutTime > _resInTime) {
          _actualIERatio =
              'I/E Ratio 1 : ' + (_resOutTime / _resInTime).toStringAsFixed(1);
        } else {
          _actualIERatio = 'I/E Ratio ' +
              (_resInTime / _resOutTime).toStringAsFixed(1) +
              ' : 1';
        }
        if (_flagSpontan == 1)
          _loopValue = _actualLoop - 2;
        else
          _loopValue = _actualLoop - 1;
        _flagStartInsp = false;
        _actualLoop = 0;
        _iLoop = 0;
        _playSound();
        if (_flagSpontan >= _spontanBreathValue)
          _flagSpontan = 0;
        else
          _flagSpontan++;
      }

      if (_currentFlow > 0 && _actualLoop == 1) {
        _insp = true;
        _currentVTe = (_currentVTi - _currentVolume);
        _flowExp = _currentVTe / 1000 / _resOutTime * 60;
        _currentVT = _currentVTe + _currentVTi;

        _currentVolume = 0;
        //_vt = 0;
        _pPeakValue = 0;
        _currentFlow = 0;
        _currentPeep = _currentPaw.toInt();
        _pressureFlowDataSet.clear();
        _pressureVolumeDataSet.clear();
        _volumeFlowDataSet.clear();
      } else if (_currentFlow < 0 && _insp) {
        _insp = false;
        _currentVTi = _currentVolume;
        if (_flagSpontan == 1)
          _resInTime = (_actualLoop - 2) * 200 / 1000;
        else
          _resInTime = (_actualLoop - 1) * 200 / 1000;
        _flowIns = _currentVTi / 1000 / _resInTime * 60;
      }
      _iLoop++;
    } else {
      if (_flagSpontan >= _spontanBreathValue)
        _flagSpontan = 0;
      else
        _flagSpontan++;
      //_resInTime = _tempResInTime;
      _playSound();
      _actualLoop = 0;
      _iLoop = 0;
      _flagStartInsp = false;
    }
    //_command = '3';
    //connection.output.add(utf8.encode(_command + "\r\n"));
  }

  bool getFlagCPAP() {
    return _flagCPAP;
  }

  void _cmvMode() async {
    if (_cycleChanged ? _tempLoop == 0 : _iLoop == 0) {
      _currentVTe = (_currentVTi - _currentVolume);
      _flowExp = _currentVTe / 1000 / _resOutTime * 60;
      _currentVT = _currentVTe + _currentVTi;
      _currentMVe = _currentVTi / 1000 * _resRateValue;
      _insp = true;
      _command = '1.\n';
      _currentVolume = 0;
      //_vt = 0;
      _pPeakValue = 0;
      _currentFlow = 0;
      _currentPeep = _currentPaw.toInt();
      _pressureFlowDataSet.clear();
      _pressureVolumeDataSet.clear();
      _volumeFlowDataSet.clear();
      await _port.write(Uint8List.fromList(_command.codeUnits));
    } //else
    if (_cycleChanged
        ? _tempLoop > _tempResInTime * 5 && _insp
        : _iLoop > _resInTime * 5 && _insp) {
      _command = '2.\n';
      await _port.write(Uint8List.fromList(_command.codeUnits));
      _insp = false;
      _currentVTi = _currentVolume;
      _flowIns = _currentVTi / 1000 / _resInTime * 60;
    }

    if (_cycleChanged ? _tempLoop < _tempLoopValue : _iLoop < _loopValue) {
      _cycleChanged ? _tempLoop++ : _iLoop++;
    } else {
      _playSound();
      _cycleChanged = false;
      _iLoop = 0;
    }
    //_command = '3';
    //connection.output.add(utf8.encode(_command + "\r\n"));
  }

  int getIndex() {
    return _index;
  }

  void startCalib() async {
    if (_index != 0 && !_calibFlag) _index = 0;
    if (!_calibFlag) _calibFlag = true;
    _command = '3.\n';
    await _port.write(Uint8List.fromList(_command.codeUnits));
  }

  void startVenting(int index) async {
    if (_calibFlag) {
      _calibFlag = false;
      _index = 0;
    }

    if (_ventStart) {
      switch (ventType) {
        case modeCMV:
          _cmvMode();
          break;
        case modePCMV:
          _cmvMode();
          break;
        case modeCPAP:
          _cpapMode();
          break;
        case modeSIMV:
          //_simvMode();
          _newSimvMode();
          break;
        case modePSV:
          _psvMode();
          break;
      }
      _command = '3.\n';
      await _port.write(Uint8List.fromList(_command.codeUnits));
      _command = 'L.\n';
      await _port.write(Uint8List.fromList(_command.codeUnits));
    }
    /* else {
      if (ventType != modeCPAP) {
        _command = '3';
        connection.output.add(utf8.encode(_command + "\r\n"));
        if (_iLoop < _loopValue) {
          _iLoop++;
        } else {
          _playSound();
          _iLoop = 0;
        }
      }
    }*/
  }

  Future<int> _loadSound() async {
    var asset = await rootBundle.load("media/beep-02.wav");
    return await _soundpool.load(asset);
  }

  /*
  Future<void> _playSound() async {
    var _alarmSound = await _soundId;
    _alarmSoundStreamId = await _soundpool.play(_alarmSound);
  }
  */

  void _playSound() {
    FlutterBeep.playSysSound(AndroidSoundIDs.TONE_SUP_ERROR);
  }

  List<GraphXYData> getPressureFlowDataSet() {
    return _pressureFlowDataSet;
  }

  List<GraphXYData> getVolumeFlowDataSet() {
    return _volumeFlowDataSet;
  }

  List<GraphXYData> getPressureVolumeDataSet() {
    return _pressureVolumeDataSet;
  }

  bool getConnection() {
    return _connected;
  }

  Future<void> connectionStop() async {
    dbHelper.closeDB();
    _disconnect();
  }

  // Method to disconnect bluetooth
  /*
  void _disconnect() async {
    await connection.close();
    if (!connection.isConnected) {
      _connected = false;
    }
  }
*/
/*
  Future<void> getPairedDevices() async {
    List<BluetoothDevice> devices = [];

    // To get the list of paired devices
    try {
      devices = await _bluetooth.getBondedDevices();
    } on PlatformException {
      print("Error");
    }

    print('devices list updated');
    _devicesList.forEach((device) {
      print(device.name);
      //TODO ganti nama device HC05 atau HC-05
      if (device.name == 'HC05') {
        _device = device;
        _connect();
      }
    });
    _devicesList = devices;
  }

  Future<void> enableBluetooth() async {
    // Retrieving the current Bluetooth state
    _bluetoothState = await FlutterBluetoothSerial.instance.state;

    // If the bluetooth is off, then turn it on first
    // and then retrieve the devices that are paired.
    if (_bluetoothState == BluetoothState.STATE_OFF) {
      await FlutterBluetoothSerial.instance.requestEnable();
      await getPairedDevices();
      return true;
    } else {
      await getPairedDevices();
    }
    return false;
  }
*/
  /*void _connect() async {
    if (_device == null) {
    } else {
      if (!isConnected) {
        _bluetoothError = false;
        await BluetoothConnection.toAddress(_device.address)
            .then((_connection) {
          print('Connected to the device');

          connection = _connection;
          _connected = true;
          getArdruinoData();
        }).catchError((error) {
          _bluetoothError = true;

          print('Cannot connect, exception occurred');
          print(error);
        });
      }
    }
  }
*/
  bool isBluetoothError() {
    return _bluetoothError;
  }

  // for usb connection
  void _disconnect() async {
    _connectTo(null);
  }

  Future<bool> _connectTo(device) async {
    if (_subscription != null) {
      _subscription.cancel();
      _subscription = null;
    }

    if (_transaction != null) {
      _transaction.dispose();
      _transaction = null;
    }

    if (_port != null) {
      _port.close();
      _port = null;
    }

    if (device == null) {
      _deviceId = null;
      _connected = false;
      return true;
    }

    _port = await device.create();
    if (!await _port.open()) {
      _connected = false;
      return false;
    }

    _deviceId = device.deviceId;
    await _port.setDTR(true);
    await _port.setRTS(true);
    await _port.setPortParameters(
        115200, UsbPort.DATABITS_8, UsbPort.STOPBITS_1, UsbPort.PARITY_NONE);

    _transaction = Tran.Transaction.stringTerminated(
        _port.inputStream, Uint8List.fromList([13, 10]));

    _subscription = _transaction.stream.listen((String line) {
      if (line.length > 1) {
        var dataSensor = line.split(".");
        if (dataSensor[0] == 't') {
          ///get flow value from machine
          int _flagFlow = int.parse(dataSensor[1]);
          _flow = int.parse(dataSensor[2]) + (int.parse(dataSensor[3]) / 100);

          if (_flagFlow == 1)
            _currentFlow = _flow * -1;
          else
            _currentFlow = _flow;

          _currentVolume = double.parse(dataSensor[11]);
          if (_currentVolume < 0) _currentVolume = 0;

          ///cari leak
          _prevPressure = _currentPaw.toInt();

          ///get pressure value from machine
          int _flagPaw = int.parse(dataSensor[4]);
          _currentPaw = int.parse(dataSensor[5]).toDouble();
          if (_flagPaw == 1) _currentPaw = _currentPaw * -1;

          ///cari leak
          _difPressure = _prevPressure - _currentPaw.toInt();
          if ((_difPressure) > 25)
            _leakage = true;
          else
            _leakage = false;

          if (_leakage) _triggerLeak();
          int _flagFTrigger = int.parse(dataSensor[6]);
          _currentFTrigger =
              int.parse(dataSensor[7]) + (int.parse(dataSensor[8]) / 100);
          if (_flagFTrigger == 1) {
            _currentFTrigger = _currentFTrigger * -1;
          }

          int _flagPTrigger = int.parse(dataSensor[9]);
          _currentPTrigger = int.parse(dataSensor[10]);

          if (_flagPTrigger == 1) _currentPTrigger = _currentPTrigger * -1;

          if (_triggerSelected == Ventilator.stringFTrigger
              ? _currentFlow >= _fTriggerValue
              : _currentPaw <= _pTriggerValue) _triggered = true;

          ///cari PPeak
          if (_currentPaw > _pPeakValue) _pPeakValue = _currentPaw.toInt();

          ///buat xy untuk grafik
          GraphXYData pf = GraphXYData(
              y: _currentPaw,
              x: _currentFlow < 0 ? _currentFlow * -1 : _currentFlow);
          GraphXYData vf = GraphXYData(
              y: _currentVolume,
              x: _currentFlow < 0 ? _currentFlow * -1 : _currentFlow);
          GraphXYData pV = GraphXYData(y: _currentPaw, x: _currentVolume);
          _volumeFlowDataSet.add(vf);
          _pressureVolumeDataSet.add(pV);
          _pressureFlowDataSet.add(pf);

          ///simpan _currentflow, _currentvolume, paw
          if (!_calibFlag) {
            var _v1 = uuid.v1();
            _inserDbGraph(_currentPaw, _currentVolume, _currentFlow, _v1);
          }

          setFlowDataSet(_index, _currentFlow);
          setPawDataSet(_index, _currentPaw);
          setVTidalDataSet(_index, _currentVolume);

          checkPEEP();

          ///untuk grafik SPO2 yang 1 detik
          setSPO2DataSet(_index, _currentSPO2.toDouble());
          _index++;
          if (_index == kDataWidth) _index = 0;
        } else if (dataSensor[0] == 'a') {
          _batteryStatus = int.parse(dataSensor[1]);
          _uvFlag = int.parse(dataSensor[2]);
          _o2Flag = int.parse(dataSensor[3]);
          _airFlag = int.parse(dataSensor[4]);
          _currentFio2Value = int.parse(dataSensor[5]);
          _tempValue = int.parse(dataSensor[6]);
          _huValue = int.parse(dataSensor[7]);
        } else if (dataSensor[0] == 'v') {
          _currentSPO2 = int.parse(dataSensor[1]);
          setSPO2DataSet(_index, _currentSPO2.toDouble());
        } else if (dataSensor[0] == 'l') {
          _currentETCO2 = int.parse(dataSensor[1]);
          setETCO2DataSet(_index, _currentETCO2.toDouble());
        }
      } else {
        if (line == 'z') {
          _airLeak = true;
          preCheckList();
        } else if (line == 'w') {
          _initMachine = true;
          preCheckList();
          //setMachineInitData();
        } else if (line == 'x') {
          _sensorFlow = true;
          _calibFlag = false;
          preCheckList();
        } else if (line == 'y') {
          _sensorPressure = true;
          _calibFlag = false;
          preCheckList();
        } else if (line == 'm') {
          _sensorO2 = true;
          preCheckList();
        }
      }

      /*








        int flag9 = _buffer.indexOf('t'.codeUnitAt(0));
        if (flag9 >= 0 && _buffer.length - flag9 >= 11) {
          ///get flow value from machine
          int _flagFlow = _buffer[flag9 + 1];
          _flow = _buffer[flag9 + 2] + (_buffer[flag9 + 3] / 100);

          if (_flagFlow == 1)
            _currentFlow = _flow * -1;
          else
            _currentFlow = _flow;

          _currentVolume = _currentVolume + (_currentFlow / 60 * 200);
          if (_currentVolume < 0) _currentVolume = 0;

          ///cari leak
          _prevPressure = _currentPaw.toInt();

          ///get pressure value from machine
          int _flagPaw = _buffer[flag9 + 4];
          _currentPaw = _buffer[flag9 + 5].toDouble();
          if (_flagPaw == 1) _currentPaw = _currentPaw * -1;

          ///cari leak
          _difPressure = _prevPressure - _currentPaw.toInt();
          if ((_difPressure) > 25)
            _leakage = true;
          else
            _leakage = false;

          if (_leakage) _triggerLeak();
          int _flagFTrigger = _buffer[flag9 + 6];
          _currentFTrigger = _buffer[flag9 + 7] + (_buffer[flag9 + 8] / 100);
          if (_flagFTrigger == 1) {
            _currentFTrigger = _currentFTrigger * -1;
          }

          int _flagPTrigger = _buffer[flag9 + 9];
          _currentPTrigger = _buffer[flag9 + 10];

          if (_flagPTrigger == 1) _currentPTrigger = _currentPTrigger * -1;

          if (_triggerSelected == Ventilator.stringFTrigger
              ? _currentFlow >= _fTriggerValue
              : _currentPaw <= _pTriggerValue) _triggered = true;

          ///cari PPeak
          if (_currentPaw > _pPeakValue) _pPeakValue = _currentPaw.toInt();

          ///buat xy untuk grafik
          GraphXYData pf = GraphXYData(
              y: _currentPaw,
              x: _currentFlow < 0 ? _currentFlow * -1 : _currentFlow);
          GraphXYData vf = GraphXYData(
              y: _currentVolume,
              x: _currentFlow < 0 ? _currentFlow * -1 : _currentFlow);
          GraphXYData pV = GraphXYData(y: _currentPaw, x: _currentVolume);
          _volumeFlowDataSet.add(vf);
          _pressureVolumeDataSet.add(pV);
          _pressureFlowDataSet.add(pf);

          ///simpan _currentflow, _currentvolume, paw
          if (!_calibFlag) {
            var _v1 = uuid.v1();
            _inserDbGraph(_currentPaw, _currentVolume, _currentFlow, _v1);
          }

          setFlowDataSet(_index, _currentFlow);
          setPawDataSet(_index, _currentPaw);
          setVTidalDataSet(_index, _currentVolume);

          checkPEEP();

          ///untuk grafik SPO2 yang 1 detik
          setSPO2DataSet(_index, _currentSPO2.toDouble());
          _index++;
          if (_index == kDataWidth) _index = 0;

          _buffer.removeRange(0, flag9 + 11);
        }






      * */
    });

    _connected = true;

    return true;
  }

  void _getPorts() async {
    //_ports = [];
    List<UsbDevice> devices = await UsbSerial.listDevices();
    //print(devices);
    await _connectTo(devices.isEmpty ? null : devices[0]);
  }

  void getOtherMachineStatus() async {
    if (_connected) {
      await _port.write(Uint8List.fromList("A.\n".codeUnits));
      await _port.write(Uint8List.fromList("V.\n".codeUnits));
    }
  }

  void sendAllParam() async {
    _command = "v." + _vTidalValue.toString() + "\n";
    await _port.write(Uint8List.fromList(_command.codeUnits));
    _command = "p." + _pressureValue.toString() + "\n";
    await _port.write(Uint8List.fromList(_command.codeUnits));
    _command = "f." + (_flowValue * 100).toString() + "\n";
    await _port.write(Uint8List.fromList(_command.codeUnits));
    _command = "rr." + _resRateValue.toString() + "\n";
    await _port.write(Uint8List.fromList(_command.codeUnits));
    if (_reverseIE) {
      _command = "i." + (_ieRatioValue * 10).toString() + "\n";
      await _port.write(Uint8List.fromList(_command.codeUnits));
      _command = "e.10\n";
      await _port.write(Uint8List.fromList(_command.codeUnits));
    } else {
      _command = "i.10\n";
      await _port.write(Uint8List.fromList(_command.codeUnits));
      _command = "e." + (_ieRatioValue * 10).toString() + "\n";
      await _port.write(Uint8List.fromList(_command.codeUnits));
    }
    _command = "mode." + getModeCode(ventType).toString() + "\n";
    await _port.write(Uint8List.fromList(_command.codeUnits));
    _command = "fi." + _fio2Value.toString() + "\n";
    await _port.write(Uint8List.fromList(_command.codeUnits));
    _command = "op." + _overPressure.toString() + "\n";
    await _port.write(Uint8List.fromList(_command.codeUnits));
    _command = "pe." + _peepValue.toString() + "\n";
    await _port.write(Uint8List.fromList(_command.codeUnits));
    _command = 'W.\n';
    await _port.write(Uint8List.fromList(_command.codeUnits));
  }

  void initMachine() async {
    if (_connected) {
      sendAllParam();
      //connection.output.add(utf8.encode(_command + "\r\n"));
    }
  }

  void checkO2() async {
    if (_connected) {
      _command = 'M.\n';
      await _port.write(Uint8List.fromList(_command.codeUnits));
      //connection.output.add(utf8.encode(_command + "\r\n"));
    }
  }

  void checkPressure() async {
    if (_connected) {
      _command = 'Y.\n';
      await _port.write(Uint8List.fromList(_command.codeUnits));
      //connection.output.add(utf8.encode(_command + "\r\n"));
    }
  }

  void checkFlow() async {
    if (_connected) {
      _command = 'X.\n';
      await _port.write(Uint8List.fromList(_command.codeUnits));
      //connection.output.add(utf8.encode(_command + "\r\n"));
    }
  }

  void checkAirLeak() async {
    if (_connected) {
      _command = 'Z.\n';
      await _port.write(Uint8List.fromList(_command.codeUnits));
      //connection.output.add(utf8.encode(_command + "\r\n"));
    }
  }

  int getModeCode(String mode) {
    int modeCode = 0;
    switch (mode) {
      case modeCMV:
        modeCode = 1;
        break;
      case modePCMV:
        modeCode = 5;
        break;
      case modeSIMV:
        modeCode = 2;
        break;
      case modePSIMV:
        modeCode = 6;
        break;
      case modeCPAP:
        modeCode = 7;
        break;
      case modePSV:
        modeCode = 4;
        break;
      case modeSCMV:
        modeCode = 3;
        break;
    }
    return modeCode;
  }

  void setMachineInitData() async {
    if (_connected) {
      int countPMovement = (_pressureValue ~/ 10);
      for (int i = 0; i < countPMovement; i++) {
        await _port.write(Uint8List.fromList("P.\n".codeUnits));
      }

      if (_flowValue == 0.5) {
        await _port.write(Uint8List.fromList("R.\n".codeUnits));
      } else {
        int countFMovement = (_flowValue ~/ 1);
        for (int i = 0; i < countFMovement; i++) {
          if (i < 3) {
            await _port.write(Uint8List.fromList("R\n".codeUnits));
            await _port.write(Uint8List.fromList("R\n".codeUnits));
          } else {
            await _port.write(Uint8List.fromList("R\n".codeUnits));
          }
        }
        if (_flowValue % 1 != 0) {
          if (countFMovement < 3)
            await _port.write(Uint8List.fromList("R\n".codeUnits));
          else
            await _port.write(Uint8List.fromList("T\n".codeUnits));
        }
      }
    }
  }

  void reconnectToMachine() {
    //_connect();
    _getPorts();
  }

  void continueVenting() async {
    _isVenting = true;
    _start = DateTime.now();
    if (_insp && ventType != modeCPAP)
      _command = '1.\n';
    else
      _command = '4.\n';
    await _port.write(Uint8List.fromList(_command.codeUnits));
  }

  void pauseVenting() async {
    _isVenting = false;
    _diff = DateTime.now().difference(_start).inMilliseconds;
    _saveDuration(DateTime.now().difference(_start).inSeconds);
    if (_insp && ventType != modeCPAP)
      _command = '2.\n';
    else {
      _flagCPAP = false;
      _command = '5.\n';
    }
    await _port.write(Uint8List.fromList(_command.codeUnits));
  }

  void switchInspHold() async {
    _inspHold = !_inspHold;
    if (_inspHold) {
      _ventStart = false;
      _command = '1.\n';
      await _port.write(Uint8List.fromList(_command.codeUnits));
    } else {
      _ventStart = true;
    }
  }

  bool isInspHold() {
    return _inspHold;
  }

  double getMinSettingValue(String setString) {
    double minValue;
    switch (setString) {
      case stringFTrigger:
        minValue = _minFTrigger;
        break;
      case stringPTrigger:
        minValue = _minPTrigger;
        break;
      case stringSpontaneousBreath:
        minValue = _minSpontanBreath;
        break;
      case stringOverPressure:
        minValue = _minOverPressure;
        break;
      case stringFiO2:
        minValue = _minFiO2;
        break;
      case stringVTidal:
        minValue = _minVTidal;
        break;
      case stringPeep:
        minValue = _minPEEP;
        break;
      case stringPressure:
        minValue = _minPaw;
        break;
      case stringFlow:
        minValue = _minFlow;
        break;
      case stringHumidifier:
        minValue = _minHumidifier;
        break;
      case stringResRate:
        minValue = ventType == modeSIMV || ventType == modePSIMV
            ? _minRestRate / 2
            : _minRestRate;
        break;
      case stringIERatio:
        minValue = _minIERatio;
        break;
      case stringTemp:
        minValue = _minTemp;
        break;
      case stringMinuteVentilation:
        minValue = _minMVe;
        break;
    }
    return minValue;
  }

  void setMaxAlarmValue(setString, double value) {
    switch (setString) {
      case stringFiO2:
        _fioAlarmMax = value;
        break;
      case stringHumidifier:
        _huAlarmMax = value;
        break;
      case stringPressure:
        _pAlarmMax = value;
        break;
      case stringVTidal:
        _vteAlarmMax = value;
        break;
      case stringTemp:
        _tempAlarmMax = value;
        break;
      case stringMinuteVentilation:
        _mveAlarmMax = value;
        break;
    }
  }

  void setMinAlarmValue(setString, double value) {
    switch (setString) {
      case stringFiO2:
        _fioAlarmMin = value;
        break;
      case stringHumidifier:
        _huAlarmMin = value;
        break;
      case stringPressure:
        _pAlarmMin = value;
        break;
      case stringVTidal:
        _vteAlarmMin = value;
        break;
      case stringTemp:
        _tempAlarmMin = value;
        break;
      case stringMinuteVentilation:
        _mveAlarmMin = value;
        break;
    }
  }

  double getMaxAlarmValue(String setString) {
    double maxValue;
    switch (setString) {
      case stringFiO2:
        maxValue = _fioAlarmMax;
        break;
      case stringHumidifier:
        maxValue = _huAlarmMax;
        break;
      case stringPressure:
        maxValue = _pAlarmMax;
        break;
      case stringVTidal:
        maxValue = _vteAlarmMax;
        break;
      case stringTemp:
        maxValue = _tempAlarmMax;
        break;
      case stringMinuteVentilation:
        maxValue = _mveAlarmMax;
        break;
    }
    return maxValue;
  }

  double getMinAlarmValue(String setString) {
    double maxValue;
    switch (setString) {
      case stringFiO2:
        maxValue = _fioAlarmMin;
        break;
      case stringHumidifier:
        maxValue = _huAlarmMin;
        break;
      case stringPressure:
        maxValue = _pAlarmMin;
        break;
      case stringVTidal:
        maxValue = _vteAlarmMin;
        break;
      case stringTemp:
        maxValue = _tempAlarmMin;
        break;
      case stringMinuteVentilation:
        maxValue = _mveAlarmMin;
        break;
    }
    return maxValue;
  }

  double getMaxSettingValue(String setString) {
    double maxValue;
    switch (setString) {
      case stringFTrigger:
        maxValue = _maxFTrigger;
        break;
      case stringPTrigger:
        maxValue = _maxPTrigger;
        break;
      case stringSpontaneousBreath:
        maxValue = _maxSpontanBreath;
        break;
      case stringOverPressure:
        maxValue = _maxOverPressure;
        break;
      case stringFiO2:
        maxValue = _maxFiO2;
        break;
      case stringVTidal:
        maxValue = _maxVTidal;
        break;
      case stringPeep:
        maxValue = _maxPEEP;
        break;
      case stringPressure:
        maxValue = _maxPaw;
        break;
      case stringFlow:
        maxValue = _maxFlow;
        break;
      case stringHumidifier:
        maxValue = _maxHumidifier;
        break;
      case stringResRate:
        maxValue = ventType == modeSIMV || ventType == modePSIMV
            ? _maxRestRate / 2
            : _maxRestRate;

        break;
      case stringIERatio:
        maxValue = _maxIERatio;
        break;
      case stringTemp:
        maxValue = _maxTemp;
        break;
      case stringMinuteVentilation:
        maxValue = _maxMVe;
        break;
    }
    return maxValue;
  }

  double getFlowValue() {
    return _flowValue;
  }

  double getCurrentFlowValue() {
    return _currentFlow;
  }

  void setPeepValue(int value) async {
    //setNewPeepMachine(-_peepValue, _peepValue);

    _peepValue = value;
    _command = "pe." + _peepValue.toString() + "\n";
    await _port.write(Uint8List.fromList(_command.codeUnits));
  }

  void setNewPeepMachine(int value, int previousValue) async {
    if (_connected && value != 0) {
      if (value < 0) {
        int countPMovement = value * -1;
        for (int i = 0; i < countPMovement; i++) {
          _command = 'g.\n';
          await _port.write(Uint8List.fromList(_command.codeUnits));
        }
      } else {
        int countPMovement = value;
        for (int i = 0; i < countPMovement; i++) {
          _command = 'f.\n';
          await _port.write(Uint8List.fromList(_command.codeUnits));
        }
      }
    }
  }

  void setFlowValue(double value) async {
    //setNewFlowMachine(value - _flowValue, _flowValue);
    _flowValue = value;
    _command = "f." + (_flowValue * 100).toString() + "\n";
    await _port.write(Uint8List.fromList(_command.codeUnits));
    if (!_setVT) {
      _vTidalValue = _calculateVT();
      _roundVT();
    } else {
      _setVT = false;
    }
  }

  void setNewFlowMachine(double value, double previousValue) async {
    if (_connected && value != 0) {
      if (value < 0) {
        value = value * -1;
        if (value == 0.5) {
          if (previousValue < 3)
            _command = 'R.\n';
          else
            _command = 'T.\n';
          await _port.write(Uint8List.fromList(_command.codeUnits));
        } else {
          int countFMovement = (value ~/ 1);
          for (int i = 0; i < countFMovement; i++) {
            if (previousValue + i < 3) {
              _command = 'R.\n';
              await _port.write(Uint8List.fromList(_command.codeUnits));
              _command = 'R.\n';
              await _port.write(Uint8List.fromList(_command.codeUnits));
            } else {
              _command = 'R.\n';
              await _port.write(Uint8List.fromList(_command.codeUnits));
            }
          }
          if (value % 1 != 0) {
            if (previousValue + countFMovement < 3)
              _command = 'R.\n';
            else
              _command = 'T.\n';
            await _port.write(Uint8List.fromList(_command.codeUnits));
          }
        }
      } else {
        if (value == 0.5) {
          if (previousValue < 3)
            _command = 'S.\n';
          else
            _command = 'U.\n';
          await _port.write(Uint8List.fromList(_command.codeUnits));
        } else {
          int countFMovement = (value ~/ 1);

          for (int i = 0; i < countFMovement; i++) {
            if (previousValue + i < 3) {
              _command = 'S.\n';
              await _port.write(Uint8List.fromList(_command.codeUnits));
              _command = 'S.\n';
              await _port.write(Uint8List.fromList(_command.codeUnits));
            } else {
              _command = 'S.\n';
              await _port.write(Uint8List.fromList(_command.codeUnits));
            }
          }
          if (value % 1 != 0) {
            if (previousValue + countFMovement < 3)
              _command = 'S.\n';
            else
              _command = 'U.\n';
            await _port.write(Uint8List.fromList(_command.codeUnits));
          }
        }
      }
    }
  }

  int getVTidalValue() {
    return _vTidalValue;
  }

  int getPPeakValue() {
    return _pPeakValue;
  }

  void setPPeakValue(int value) {
    _pPeakValue = value;
  }

  double _roundFlow(double flowValue) {
    int tempRound = 0;
    tempRound = flowValue.toInt();
    double tempDigit = 0;
    tempDigit = flowValue - tempRound;
    if (tempDigit > 0.5)
      tempDigit = 1;
    else
      tempDigit = 0.5;
    return tempRound.toDouble() + tempDigit;
  }

  void setVTidalValue(int value) async {
    _vTidalValue = value;
    _command = "v." + _vTidalValue.toString() + "\n";
    await _port.write(Uint8List.fromList(_command.codeUnits));
    _setVT = true;
    double newFlow = _calculateFlow();
    setFlowValue(_roundFlow(newFlow));
  }

  int getPressureValue() {
    return _pressureValue;
  }

  int getOverPressureValue() {
    return _overPressure;
  }

  void setOverPressureValue(int value) async {
    //setNewOverPressureMachine(value - _overPressure);

    _overPressure = value;
    _command = "op." + _overPressure.toString() + "\n";
    await _port.write(Uint8List.fromList(_command.codeUnits));
  }

  void setPressureValue(int value) async {
    //setNewPressureMachine(value - _pressureValue);

    _pressureValue = value;
    _command = "p." + _overPressure.toString() + "\n";
    await _port.write(Uint8List.fromList(_command.codeUnits));
  }

  void setNewOverPressureMachine(int value) async {
    if (_connected && value != 0) {
      if (value < 0) {
        int countPMovement = ((value * -1) ~/ 10);
        for (int i = 0; i < countPMovement; i++) {
          _command = 'G.\n';
          await _port.write(Uint8List.fromList(_command.codeUnits));
        }
      } else {
        int countPMovement = ((value) ~/ 10);
        for (int i = 0; i < countPMovement; i++) {
          _command = 'F.\n';
          await _port.write(Uint8List.fromList(_command.codeUnits));
        }
      }
    }
  }

  void setNewPressureMachine(int value) async {
    if (_connected && value != 0) {
      if (value < 0) {
        int countPMovement = ((value * -1) ~/ 10);
        for (int i = 0; i < countPMovement; i++) {
          _command = 'Q.\n';
          await _port.write(Uint8List.fromList(_command.codeUnits));
        }
      } else {
        int countPMovement = ((value) ~/ 10);
        for (int i = 0; i < countPMovement; i++) {
          _command = 'P.\n';
          await _port.write(Uint8List.fromList(_command.codeUnits));
        }
      }
    }
  }

  double getIERatioValue() {
    return _ieRatioValue;
  }

  void setIERatioValue(double value) async {
    _ieRatioValue = value;
    if (_reverseIE) {
      _command = "i." + (_ieRatioValue * 10).toString() + "\n";
      await _port.write(Uint8List.fromList(_command.codeUnits));
      _command = "e.10\n";
      await _port.write(Uint8List.fromList(_command.codeUnits));
    } else {
      _command = "i.10\n";
      await _port.write(Uint8List.fromList(_command.codeUnits));
      _command = "e." + (_ieRatioValue * 10).toString() + "\n";
      await _port.write(Uint8List.fromList(_command.codeUnits));
    }
    if (_index != 0) _cycleChanged = true;
    calculateCycle();
  }

  int getRestRateValue() {
    return _resRateValue;
  }

  void setRestRateValue(int value) async {
    _resRateValue = value;
    _command = "rr." + _resRateValue.toString() + "\n";
    await _port.write(Uint8List.fromList(_command.codeUnits));
    if (_index != 0) _cycleChanged = true;
    calculateCycle();
  }

  int getHumidifierValue() {
    return _humidifierValue;
  }

  int getTemperatureValue() {
    return _tempValue;
  }

  int getCurrentHuValue() {
    return _huValue;
  }

  int getO2Flag() {
    return _o2Flag;
  }

  int getAirFlag() {
    return _airFlag;
  }

  int getUvFlag() {
    return _uvFlag;
  }

  void setHumidifierValue(int value) {
    _humidifierValue = value;
  }

  int getFiO2Value() {
    return _fio2Value;
  }

  void setFiO2Value(int value) async {
    //setNewFioMachine(value - _fio2Value);
    _fio2Value = value;
    _command = "fi." + _fio2Value.toString() + "\n";
    await _port.write(Uint8List.fromList(_command.codeUnits));
  }

  void setNewFioMachine(int value) async {
    if (_connected && value != 0) {
      if (value < 0) {
        int countPMovement = ((value * -1) ~/ 10);
        for (int i = 0; i < countPMovement; i++) {
          _command = 'I.\n';
          await _port.write(Uint8List.fromList(_command.codeUnits));
        }
      } else {
        int countPMovement = ((value) ~/ 10);
        for (int i = 0; i < countPMovement; i++) {
          _command = 'H.\n';
          await _port.write(Uint8List.fromList(_command.codeUnits));
        }
      }
    }
  }

  int getPeepValue() {
    return _peepValue;
  }

  String getDuration() {
    int miliSecond = 0;

    if (_isVenting)
      miliSecond = DateTime.now().difference(_start).inMilliseconds + _diff;
    else
      miliSecond = _diff;
    //int miliSecond = DateTime.now().difference(_start).inMilliseconds + _diff;
    int seconds = (miliSecond / 1000).truncate();
    int minutes = (seconds / 60).truncate();
    int hours = (minutes / 60).truncate();
    int days = (hours / 24).truncate();
    String dayStr = (days).toString().padLeft(2, '0');
    String hourStr = (hours % 24).toString().padLeft(2, '0');
    String minutesStr = (minutes % 60).toString().padLeft(2, '0');
    String secondsStr = (seconds % 60).toString().padLeft(2, '0');
    return '$dayStr d $hourStr:$minutesStr:$secondsStr';
  }

  String getDBDurationString() {
    int seconds = 0;
    int machDuration = 0;
    if (_dbDuration != null) machDuration = _dbDuration;
    if (_isVenting)
      seconds = DateTime.now().difference(_start).inSeconds +
          (_diff / 1000).truncate() +
          machDuration;
    else
      seconds = (_diff / 1000).truncate() + machDuration;

    int minutes = (seconds / 60).truncate();
    int hours = (minutes / 60).truncate();
    int days = (hours / 24).truncate();
    String dayStr = (days).toString().padLeft(1, '0');
    String hourStr = (hours % 24).toString().padLeft(2, '0');
    String minutesStr = (minutes % 60).toString().padLeft(2, '0');
    String secondsStr = (seconds % 60).toString().padLeft(2, '0');
    return '$dayStr d $hourStr:$minutesStr:$secondsStr';
  }

  ///tambahan untuk DB

  Future<void> _saveDuration(int seconds) async {
    int _rowHsl = await dbHelper.getDuration();

    if (_rowHsl == null) {
      SecondsData secondsData = SecondsData(seconds: seconds);
      await dbHelper.insertDuration(secondsData);
    } else {
      _rowHsl += seconds;
      SecondsData secondsData = SecondsData(seconds: _rowHsl);
      await dbHelper.updateDuration(secondsData);
    }
  }

  void getDBDuration() async {
    _dbDuration = await dbHelper.getDuration();
  }

  void setPawDS(double value) {
    _pawDS.add(value);
  }

  void setVTidalDS(double value) {
    _vTidalDS.add(value);
  }

  void setFlowDS(double value) {
    _flowDS.add(value);
  }

  void setCreatedAtDS(DateTime value) {
    _createdAtDS.add(value);
  }

  void setUPDBData() {
    _pawDS.clear();
    _vTidalDS.clear();
    _flowDS.clear();
    _createdAtDS.clear();
    int iStart = 0;
    iStart = InfoPage.iStart;
    int iReverse = iStart + InfoPage.iLength - 1;
    _ivList = InfoDS.linfoDS.length;

    if (iStart + InfoPage.iLength > _ivList) {
      int noData = iStart + InfoPage.iLength - _ivList;
      for (int i = 0; i < noData; i++) {
        setVTidalDS(0);
        setPawDS(0);
        setFlowDS(0);
        setCreatedAtDS(DateTime.now());
        iReverse--;
      }
      for (int i = InfoPage.iStart;
          i < iStart + InfoPage.iLength - noData;
          i++) {
        setVTidalDS(InfoDS.linfoDS[iReverse].vt);
        setPawDS(InfoDS.linfoDS[iReverse].paw);
        setFlowDS(InfoDS.linfoDS[iReverse].flow);
        setCreatedAtDS(InfoDS.linfoDS[iReverse].created_at);
        iReverse--;
      }
    } else {
      for (int i = InfoPage.iStart;
          i < InfoPage.iStart + InfoPage.iLength;
          i++) {
        setVTidalDS(InfoDS.linfoDS[iReverse].vt);
        setPawDS(InfoDS.linfoDS[iReverse].paw);
        setFlowDS(InfoDS.linfoDS[iReverse].flow);
        setCreatedAtDS(InfoDS.linfoDS[iReverse].created_at);
        iReverse--;
      }
    }
  }

  void checkOverData() async {
    int iData = await dbHelper.getCount();
    if (iData > 1296000) {
      int iCount = iData - 1296000;
      int test = await dbHelper.deleteFilter(iCount);
      print('del $test');
    }
  }

  String getCreatedDS(int index) {
    String dateValue = '';
    if (_createdAtDS.length > 0) dateValue = _createdAtDS[index].toString();
    return dateValue;
  }

  List getVTidalDS() {
    return _vTidalDS;
  }

  List getPawDS() {
    return _pawDS;
  }

  List getFlowDS() {
    return _flowDS;
  }

  Future<void> _inserDbGraph(
      double _par1, double _par2, double _par3, String _par4) async {
    InsGrafik insertGraph = InsGrafik(_par1, _par2, _par3, _par4);
    int _rslInsert = await dbHelper.insertGraph(insertGraph);
    if (_rslInsert > 0) {
      //print('insert');
    }
  }

  ///end tambahan DB

  List generateDataSet() {
    List dataSet = List();
    for (int i = 0; i < kDataWidth; i++) {
      dataSet.add(0);
    }
    return dataSet;
  }

  void initDataSet() {
    for (int i = 0; i < kDataWidth; i++) {
      _pawDataSet[i] = 0;
      _flowDataSet[i] = 0;
      _vTidalDataSet[i] = 0;
      _SPO2DataSet[i] = 0;
      _ETCO2DataSet[i] = 0;
    }
    //_pawDataSet = generateDataSet();
    //_flowDataSet = generateDataSet();
    // _vTidalDataSet = generateDataSet();
    _pawDS = generateDataSet();
    _flowDS = generateDataSet();
    _vTidalDS = generateDataSet();
  }

  void setPatientType(String type) {
    patientType = type;
    setMinMaxDataSet();
  }

  void setVentMode(String mode) {
    ventType = mode;
    _flagCPAP = false;
    setVentType();
  }

  void setMinMaxDataSet() {
    switch (patientType) {
      case optionAdult:
        _minPaw = 0.0;
        if (ventType == modeCPAP)
          _maxPaw = 20;
        else
          _maxPaw = 80.0;
        _minFlow = 0.0;
        _maxFlow = 40.5;
        _minVTidal = 0.0;
        _maxVTidal = 900.0;
        _option = 'ADULT';
        if (ventType == modeCPAP) {
          if (_calibrate)
            setPressureValue(0);
          else
            _pressureValue = 0;
        } else {
          if (_calibrate)
            setPressureValue(40);
          else
            _pressureValue = 40;
        }
        /*if (_calibrate)
          setVTidalValue(400);
        else
          _vTidalValue = 400;*/

        break;
      case optionNeoNatal:
        _minPaw = 0.0;
        _maxPaw = 30.0;
        _minFlow = 0.0;
        _maxFlow = 3.0;
        _minVTidal = 0.0;
        _maxVTidal = 50.0;
        _option = 'NEO NATAL';
        _pressureValue = 20;
        _vTidalValue = 30;
        _flowValue = 2.0;
        break;
      case optionPediatric:
        _minPaw = 0.0;
        if (ventType == modeCPAP)
          _maxPaw = 20;
        else
          _maxPaw = 50.0;
        _minFlow = 0.0;
        _maxFlow = 6.0;
        _minVTidal = 0.0;
        _maxVTidal = 200.0;
        setVTidalValue(100);
        _option = 'PEDIATRIC';
        if (ventType == modeCPAP) {
          if (_calibrate)
            setPressureValue(0);
          else
            _pressureValue = 0;
        } else {
          if (_calibrate)
            setPressureValue(20);
          else
            _pressureValue = 20;
        }
        if (_vTidalValue > _maxVTidal) {
          if (_calibrate)
            setVTidalValue(180);
          else
            _vTidalValue = 180;
        }
        break;
    }
    if ((ventType == modeSIMV || ventType == modePSIMV) && _resRateValue > 15)
      setRestRateValue(_resRateValue ~/ 2);
    if ((ventType != modeSIMV || ventType != modePSIMV) && _resRateValue < 10)
      setRestRateValue(_resRateValue * 2);
  }

  void setVentType() {
    switch (ventType) {
      case modeSpontaneous:
        _mode = 'SPONTANEOUS';
        _ieRatioVisible = true;
        _respirationRateVisible = true;
        _flowVisible = false;
        _pressureVisible = true;
        _volumeVisible = false;
        break;
      case modePCMV:
        _mode = 'PRESSURED CONTROLLED MANDATORY VENTILATION (P-CMV)';
        _ieRatioVisible = true;
        _respirationRateVisible = true;
        _flowVisible = false;
        _pressureVisible = true;
        _volumeVisible = false;
        break;
      case modePSIMV:
        _mode =
            'PRESSURE CONTROLLED SYNCHRONIZED INTERMITTENT MANDATORY VENTIALTION (P-SIMV)';
        _ieRatioVisible = true;
        _respirationRateVisible = true;
        _flowVisible = false;
        _pressureVisible = true;
        _volumeVisible = false;
        break;
      case modeSIMV:
        _mode = 'SYNCHRONIZED INTERMITTENT MANDATORY VENTILATION (SIMV)';
        _ieRatioVisible = true;
        _respirationRateVisible = true;
        _flowVisible = true;
        _pressureVisible = false;
        _volumeVisible = true;
        break;
      case modeSCMV:
        _mode = 'SENSING VOLUME CONTROLLED MANDATORY VENTILATION ((S)V-CMV)';
        _ieRatioVisible = true;
        _respirationRateVisible = true;
        _pressureVisible = false;
        _volumeVisible = true;
        break;
      case modeCPAP:
        _mode = 'CONTINUOUS POSITIVE AIRWAY PRESSURE (CPAP)';
        _ieRatioVisible = false;
        _respirationRateVisible = false;
        _flowVisible = true;
        _pressureVisible = true;
        _volumeVisible = true;

        break;
      case modeCMV:
        _mode = 'VOLUME CONTROLLED MANDATORY VENTILATION (V-CMV)';
        _ieRatioVisible = true;
        _respirationRateVisible = true;
        _flowVisible = true;
        _pressureVisible = false;
        _volumeVisible = true;
        break;
      case modePSV:
        _mode = 'PRESSURE SUPPORT VENTILATION (PSV)';
        _ieRatioVisible = true;
        _respirationRateVisible = true;
        _flowVisible = true;
        _pressureVisible = false;
        _volumeVisible = false;
        break;
    }
    setMinMaxDataSet();
    calculateCycle();
    sendAllParam();
  }

  bool isVisibleFlow() {
    return _flowVisible;
  }

  bool isVisiblePressure() {
    return _pressureVisible;
  }

  bool isVisibleVolume() {
    return _volumeVisible;
  }

  bool isVisibleRespiration() {
    return _respirationRateVisible;
  }

  bool isVisibleIERatio() {
    return _ieRatioVisible;
  }

  double getVTidalDataAtIndex(int index) {
    return _vTidalDataSet[index];
  }

  double getCurrentVolume() {
    return _currentVolume;
    //return _vt;
  }

  double getFlowDataAtIndex(int index) {
    return _flowDataSet[index];
  }

  double getPawDataAtIndex(int index) {
    return _pawDataSet[index];
  }

  void setPawDataSet(int index, double value) {
    _pawDataSet[index] = value;
  }

  List getPawDataSet() {
    return _pawDataSet;
  }

  void setVTidalDataSet(int index, double value) {
    _vTidalDataSet[index] = value;
  }

  List getVTidalDataSet() {
    return _vTidalDataSet;
  }

  void setETCO2DataSet(int index, double value) {
    _ETCO2DataSet[index] = value;
  }

  void setSPO2DataSet(int index, double value) {
    _SPO2DataSet[index] = value;
  }

  void setFlowDataSet(int index, double value) {
    _flowDataSet[index] = value;
  }

  List getFlowDataSet() {
    return _flowDataSet;
  }

  String getMode() {
    return _mode;
  }

  String getOption() {
    return _option;
  }

  double getMinPaw() {
    return _minPaw;
  }

  double getMaxPaw() {
    return _maxPaw;
  }

  double getMinFlow() {
    return _minFlow;
  }

  double getMaxFlow() {
    return _maxFlow;
  }

  double getMinVTidal() {
    return _minVTidal;
  }

  double getMaxVTidal() {
    return _maxVTidal;
  }
}
