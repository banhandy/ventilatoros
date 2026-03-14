import 'package:flutter/material.dart';
import 'package:flutterappventilator/dtmodel.dart';

class RangeValuePickerDialog extends StatefulWidget {
  /// initial selection for the slider
  final MinMaxData minMaxData;
  final String title;
  final double minValue;
  final double maxValue;
  final String unit;
  final Color bgColor;
  final Color btnColor;
  final bool unitFront;
  final bool isDecimal;
  final double division;

  const RangeValuePickerDialog(
      {Key key,
      this.minMaxData,
      this.title,
      this.minValue,
      this.maxValue,
      this.unit,
      this.bgColor,
      this.btnColor,
      this.unitFront = false,
      this.isDecimal = false,
      this.division = 1})
      : super(key: key);

  @override
  _RangeValuePickerDialogState createState() => _RangeValuePickerDialogState();
}

class _RangeValuePickerDialogState extends State<RangeValuePickerDialog> {
  /// current selection of the slider

  MinMaxData _minMaxData;
  String _title;
  double _minValue;
  double _maxValue;
  String _unit;
  Color _bgColor;
  Color _btnColor;
  bool _unitFront;
  bool _isDecimal;
  double _division;

  @override
  void initState() {
    super.initState();
    _minMaxData = widget.minMaxData;
    _title = widget.title;
    _minValue = widget.minValue;
    _maxValue = widget.maxValue;
    _unit = widget.unit;
    _bgColor = widget.bgColor;
    _btnColor = widget.btnColor;
    _unitFront = widget.unitFront;
    _isDecimal = widget.isDecimal;
    _division = widget.division;
  }

  Text checkMinUnitPosition(bool unitFront, bool isDecimal) {
    if (unitFront) {
      String text;
      if (isDecimal) {
        text = _unit + ' ' + _minMaxData.min.toStringAsFixed(1);
      } else {
        text = _unit + ' ' + _minMaxData.min.toInt().toString();
      }
      return Text(
        text,
        style: TextStyle(fontSize: 30.0),
        textAlign: TextAlign.center,
      );
    }
    return Text(
      isDecimal
          ? _minMaxData.min.toStringAsFixed(1) + ' ' + _unit
          : _minMaxData.min.toInt().toString() + ' ' + _unit,
      style: TextStyle(fontSize: 30.0),
      textAlign: TextAlign.center,
    );
  }

  Text checkMaxUnitPosition(bool unitFront, bool isDecimal) {
    if (unitFront) {
      String text;
      if (isDecimal) {
        text = _unit + ' ' + _minMaxData.max.toStringAsFixed(1);
      } else {
        text = _unit + ' ' + _minMaxData.max.toInt().toString();
      }
      return Text(
        text,
        style: TextStyle(fontSize: 30.0),
        textAlign: TextAlign.center,
      );
    }
    return Text(
      isDecimal
          ? _minMaxData.max.toStringAsFixed(1) + ' ' + _unit
          : _minMaxData.max.toInt().toString() + ' ' + _unit,
      style: TextStyle(fontSize: 30.0),
      textAlign: TextAlign.center,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        _title,
        style: TextStyle(fontSize: 30.0),
        textAlign: TextAlign.center,
      ),
      backgroundColor: _bgColor,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10.0))),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              checkMinUnitPosition(_unitFront, _isDecimal),
              SizedBox(
                width: 30.0,
              ),
              checkMaxUnitPosition(_unitFront, _isDecimal),
            ],
          ),
          SizedBox(
            height: 10.0,
          ),
          Row(
            children: <Widget>[
              SizedBox(
                width: 20.0,
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    if (_isDecimal) {
                      if (_minMaxData.min - 0.1 >= _minValue)
                        _division != 1
                            ? _minMaxData.min -= _division
                            : _minMaxData.min -= 0.1;
                      else
                        _minMaxData.min = _minValue;
                    } else {
                      if (_minMaxData.min - 1 >= _minValue)
                        _division != 1
                            ? _minMaxData.min -= _division
                            : _minMaxData.min -= 1;
                      else
                        _minMaxData.min = _minValue;
                    }
                  });
                },
                child: Text(
                  _minValue.toInt().toString(),
                  style: TextStyle(fontSize: 30.0),
                ),
              ),
              SizedBox(
                width: 20.0,
              ),
              SliderTheme(
                data: SliderThemeData(
                  rangeThumbShape:
                      RoundRangeSliderThumbShape(enabledThumbRadius: 15.0),
                  thumbColor: Color(0xFFEB1555),
                  activeTrackColor: Colors.white,
                  overlayColor: Color(0x29EB1555),
                  inactiveTrackColor: Color(0xFF8D8E98),
                ),
                child: Container(
                  width: 400.0,
                  child: RangeSlider(
                    min: _minValue,
                    max: _maxValue,
                    values: RangeValues(_minMaxData.min, _minMaxData.max),
                    onChanged: (rangeValue) {
                      setState(() {
                        _minMaxData.min = rangeValue.start;
                        _minMaxData.max = rangeValue.end;
                      });
                    },
                  ),
                ),
              ),
              SizedBox(
                width: 20.0,
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    if (_isDecimal) {
                      if (_minMaxData.max + 0.1 <= _maxValue)
                        _division != 1
                            ? _minMaxData.max += _division
                            : _minMaxData.max += 0.1;
                      else
                        _minMaxData.max = _maxValue;
                    } else {
                      if (_minMaxData.max + 1 <= _maxValue)
                        _division != 1
                            ? _minMaxData.max += _division
                            : _minMaxData.max += 1;
                      else
                        _minMaxData.max = _maxValue;
                    }
                  });
                },
                child: Text(
                  _maxValue.toInt().toString(),
                  style: TextStyle(fontSize: 30.0),
                ),
              ),
              SizedBox(
                width: 20.0,
              ),
            ],
          ),
          SizedBox(
            height: 20.0,
          ),
          MaterialButton(
            height: 50.0,
            elevation: 2.0,
            color: _btnColor,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(10.0))),
            onPressed: () {
              // Use the second argument of Navigator.pop(...) to pass
              // back a result to the page that opened the dialog
              Navigator.pop(context, _minMaxData);
            },
            child: Text(
              'DONE',
              style: TextStyle(fontSize: 20.0),
            ),
          )
        ],
      ),
      actions: <Widget>[],
    );
  }
}
