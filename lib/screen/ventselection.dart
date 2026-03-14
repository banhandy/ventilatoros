import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutterappventilator/component/reusablecard.dart';
import 'package:flutterappventilator/constants.dart';
import 'package:flutterappventilator/screen/monitor.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutterappventilator/component/valuepickerdialog.dart';
import 'package:flutterappventilator/ventilator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VentSelectionPage extends StatefulWidget {
  static String id = 'Vent Selection Page';
  @override
  _VentSelectionPageState createState() => _VentSelectionPageState();
}

class _VentSelectionPageState extends State<VentSelectionPage> {
  DateTime selectedDate = DateTime.now();
  Color inactiveColor = kSecondaryColor;
  Color activeColor = kAccentColor;
  String patientName = 'John Doe';
  int patientHeight = 150;
  String patientGender = Ventilator.genderMale;

  double _fontSize = 30.0;
  String ventType = Ventilator.modeCPAP;
  String patientType = Ventilator.optionAdult;

  Future<DateTime> _selectDate(BuildContext context) async {
    final DateTime picked = await showDatePicker(
        context: context,
        initialDate: selectedDate,
        firstDate: DateTime(1910, 1),
        lastDate: DateTime.now());

    if (picked != null && picked != selectedDate)
      setState(() {
        selectedDate = picked;
      });
    return selectedDate;
  }

  Future<int> _showValuePickerDialogInt(String title, int value, String unit,
      Color bgColor, Color btnColor, bool unitFront) async {
    // <-- note the async keyword here

    final selectedValue = await showDialog<double>(
      context: context,
      builder: (context) => ValuePickerDialog(
        initialValue: value.toDouble(),
        minValue: kMinHeight.toDouble(),
        maxValue: kMaxHeight.toDouble(),
        title: title,
        unit: unit,
        bgColor: bgColor,
        btnColor: btnColor,
        unitFront: unitFront,
      ),
    );

    return selectedValue.toInt();
  }

  AppBar _generateHeaderWithTab() {
    return AppBar(
      bottom: TabBar(
        tabs: <Widget>[
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Expanded(
                  child: Center(
                    child: FaIcon(
                      FontAwesomeIcons.userInjured,
                      size: 30.0,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    "Patient Details",
                    textAlign: TextAlign.left,
                    style: TextStyle(fontSize: _fontSize),
                  ),
                )
              ],
            ),
          ),
          Tab(
            child: Column(children: <Widget>[
              Expanded(
                child: Text(
                  "Mode : " + ventType + ' - ' + patientType,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: _fontSize),
                ),
              ),
            ]),
          ),
        ],
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Container(
            child: Hero(
              tag: 'logo',
              child: Image.asset('images/logo.png'),
            ),
            width: 180.0,
          ),
          Text(
            "Ventilator",
            textAlign: TextAlign.right,
          ),
        ],
      ),
      actions: <Widget>[
        Padding(
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
        )
      ],
    );
  }

  void _setNewVentValue(String type) {
    setState(() {
      ventType = type;
    });
  }

  void _setNewPatientValue(String type) {
    setState(() {
      patientType = type;
    });
  }

  void _setNewPatientGender(String type) {
    setState(() {
      patientGender = type;
    });
  }

  Column _generateVentMode() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(
          child: Center(
            child: Text(
              "Ventilator Option",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: _fontSize),
            ),
          ),
        ),
        Expanded(
          child: Row(
            children: <Widget>[
              Expanded(
                child: ReusableCard(
                  colour: patientType == Ventilator.optionAdult
                      ? activeColor
                      : inactiveColor,
                  cardChild: Center(
                    child: Text(
                      Ventilator.optionAdult,
                      style: TextStyle(fontSize: _fontSize),
                    ),
                  ),
                  onPress: () {
                    _setNewPatientValue(Ventilator.optionAdult);
                  },
                ),
              ),
              Expanded(
                child: ReusableCard(
                  colour: patientType == Ventilator.optionPediatric
                      ? activeColor
                      : inactiveColor,
                  cardChild: Center(
                    child: Text(
                      Ventilator.optionPediatric,
                      style: TextStyle(fontSize: _fontSize),
                    ),
                  ),
                  onPress: () {
                    _setNewPatientValue(Ventilator.optionPediatric);
                  },
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: Text(
              "Ventilator Mode",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: _fontSize),
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                flex: 2,
                child: Center(
                  child: Text(
                    'Volume Cycle',
                    style: TextStyle(fontSize: _fontSize),
                  ),
                ),
              ),
              Expanded(
                child: SizedBox(
                  width: 1.0,
                ),
              ),
              Expanded(
                child: SizedBox(
                  width: 1.0,
                ),
              ),
              Expanded(
                flex: 1,
                child: ReusableCard(
                  colour: ventType == Ventilator.modeCMV
                      ? activeColor
                      : inactiveColor,
                  cardChild: Center(
                    child: Text(
                      Ventilator.modeCMV,
                      style: TextStyle(fontSize: _fontSize),
                    ),
                  ),
                  onPress: () {
                    _setNewVentValue(Ventilator.modeCMV);
                  },
                ),
              ),
              Expanded(
                flex: 1,
                child: ReusableCard(
                  colour: ventType == Ventilator.modeSIMV
                      ? activeColor
                      : inactiveColor,
                  cardChild: Center(
                    child: Text(
                      Ventilator.modeSIMV,
                      style: TextStyle(fontSize: _fontSize),
                    ),
                  ),
                  onPress: () {
                    _setNewVentValue(Ventilator.modeSIMV);
                  },
                ),
              ),
              Expanded(
                flex: 1,
                child: ReusableCard(
                  colour: ventType == Ventilator.modeSCMV
                      ? activeColor
                      : inactiveColor,
                  cardChild: Center(
                    child: Text(
                      Ventilator.modeSCMV,
                      style: TextStyle(fontSize: _fontSize),
                    ),
                  ),
                  onPress: () {
                    _setNewVentValue(Ventilator.modeSCMV);
                  },
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 3,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                flex: 2,
                child: Center(
                  child: Text(
                    'Pressure Cycle',
                    style: TextStyle(fontSize: _fontSize),
                  ),
                ),
              ),
              Expanded(
                child: ReusableCard(
                  colour: ventType == Ventilator.modePSV
                      ? activeColor
                      : inactiveColor,
                  cardChild: Center(
                    child: Text(
                      Ventilator.modePSV,
                      style: TextStyle(fontSize: _fontSize),
                    ),
                  ),
                  onPress: () {
                    _setNewVentValue(Ventilator.modePSV);
                  },
                ),
              ),
              Expanded(
                child: ReusableCard(
                  colour: ventType == Ventilator.modePCMV
                      ? activeColor
                      : inactiveColor,
                  cardChild: Center(
                    child: Text(
                      Ventilator.modePCMV,
                      style: TextStyle(fontSize: _fontSize),
                    ),
                  ),
                  onPress: () {
                    _setNewVentValue(Ventilator.modePCMV);
                  },
                ),
              ),
              Expanded(
                child: ReusableCard(
                  colour: ventType == Ventilator.modeSpontaneous
                      ? activeColor
                      : inactiveColor,
                  cardChild: Center(
                    child: Text(
                      Ventilator.modeSpontaneous,
                      style: TextStyle(fontSize: _fontSize),
                    ),
                  ),
                  onPress: () {
                    _setNewVentValue(Ventilator.modeSpontaneous);
                  },
                ),
              ),
              Expanded(
                child: ReusableCard(
                  colour: ventType == Ventilator.modePSIMV
                      ? activeColor
                      : inactiveColor,
                  cardChild: Center(
                    child: Text(
                      Ventilator.modePSIMV,
                      style: TextStyle(fontSize: _fontSize),
                    ),
                  ),
                  onPress: () {
                    _setNewVentValue(Ventilator.modePSIMV);
                  },
                ),
              ),
              Expanded(
                child: ReusableCard(
                  colour: ventType == Ventilator.modeCPAP
                      ? activeColor
                      : inactiveColor,
                  cardChild: Center(
                    child: Text(
                      Ventilator.modeCPAP,
                      style: TextStyle(fontSize: _fontSize),
                    ),
                  ),
                  onPress: () {
                    _setNewVentValue(Ventilator.modeCPAP);
                  },
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 10.0,
        ),
        Expanded(
          flex: 2,
          child: MaterialButton(
            color: kAccentColor,
            onPressed: () async {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              prefs.setString('ventType', ventType);
              prefs.setString('patientType', patientType);
              prefs.setString('patientName', patientName);
              prefs.setInt('patientHeight', patientHeight);
              prefs.setString('birthdate', selectedDate.toIso8601String());
              prefs.setString('patientGender', patientGender);
              Navigator.pushReplacementNamed(context, MonitorPage.id);
            },
            child: Text(
              'Connect To Machine',
              style: TextStyle(fontSize: _fontSize),
            ),
          ),
        ),
      ],
    );
  }

  Padding _generatePatientDetails() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Patient ',
                    textAlign: TextAlign.left,
                    style: TextStyle(fontSize: _fontSize),
                  ),
                ),
                SizedBox(
                  width: 10.0,
                ),
                Expanded(
                    child: TextField(
                  textAlign: TextAlign.left,
                  onChanged: (value) {
                    if (value != null || value != '') patientName = value;
                  },
                  style: TextStyle(fontSize: _fontSize),
                  decoration: InputDecoration(hintText: patientName),
                )),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Height',
                    textAlign: TextAlign.left,
                    style: TextStyle(fontSize: _fontSize),
                  ),
                ),
                SizedBox(
                  width: 10.0,
                ),
                Expanded(
                  child: GestureDetector(
                    child: Text(
                      patientHeight.toStringAsFixed(0) + ' cm',
                      textAlign: TextAlign.left,
                      style: TextStyle(fontSize: _fontSize),
                    ),
                    onTap: () async {
                      int selectedValue = await _showValuePickerDialogInt(
                          'Select Height',
                          patientHeight,
                          'cm',
                          kSecondaryColor,
                          kAccentColor,
                          false);
                      setState(() {
                        patientHeight = selectedValue;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    "Birth Date",
                    style: TextStyle(fontSize: _fontSize),
                    textAlign: TextAlign.left,
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    child: Text(
                      "${selectedDate.toLocal()}".split(' ')[0],
                      style: TextStyle(fontSize: _fontSize),
                    ),
                    onTap: () {
                      _selectDate(context);
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                "Gender",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: _fontSize),
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: <Widget>[
                Expanded(
                  child: ReusableCard(
                    colour: patientGender == Ventilator.genderMale
                        ? activeColor
                        : inactiveColor,
                    cardChild: Center(
                      child: Text(
                        Ventilator.genderMale,
                        style: TextStyle(fontSize: _fontSize),
                      ),
                    ),
                    onPress: () {
                      _setNewPatientGender(Ventilator.genderMale);
                    },
                  ),
                ),
                Expanded(
                  child: ReusableCard(
                    colour: patientGender == Ventilator.genderFemale
                        ? activeColor
                        : inactiveColor,
                    cardChild: Center(
                      child: Text(
                        Ventilator.genderFemale,
                        style: TextStyle(fontSize: _fontSize),
                      ),
                    ),
                    onPress: () {
                      _setNewPatientGender(Ventilator.genderFemale);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  TabBarView _generateBodyWithTab() {
    return TabBarView(
      children: <Widget>[
        _generatePatientDetails(),
        _generateVentMode(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIOverlays([]);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
    ]);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: _generateHeaderWithTab(),
        body: _generateBodyWithTab(),
      ),
    );
//    return Scaffold(
//      appBar: _generateHeader(),
//      body: _bodyVentSelection(),
//    );
  }
}
