import 'package:flutter/material.dart';

class ValuePickerDialog extends StatefulWidget {
  /// initial selection for the slider
  final double initialValue;
  final String title;
  final double minValue;
  final double maxValue;
  final String unit;
  final Color bgColor;
  final Color btnColor;
  final bool unitFront;
  final bool isDecimal;
  final double division;

  const ValuePickerDialog(
      {Key key,
      this.initialValue,
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
  _ValuePickerDialogState createState() => _ValuePickerDialogState();
}

class _ValuePickerDialogState extends State<ValuePickerDialog> {
  /// current selection of the slider
  double _selectedValue;
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
    _selectedValue = widget.initialValue;
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

  Text checkUnitPosition(bool unitFront, bool isDecimal) {
    if (unitFront) {
      String text;
      if (isDecimal) {
        text = _unit + ' ' + _selectedValue.toStringAsFixed(1);
      } else {
        text = _unit + ' ' + _selectedValue.toInt().toString();
      }
      return Text(
        text,
        style: TextStyle(fontSize: 30.0),
        textAlign: TextAlign.center,
      );
    }
    return Text(
      isDecimal
          ? _selectedValue.toStringAsFixed(1) + ' ' + _unit
          : _selectedValue.toInt().toString() + ' ' + _unit,
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
          checkUnitPosition(_unitFront, _isDecimal),
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
                      if (_division != 1) {
                        if (_selectedValue - _division >= _minValue)
                          _selectedValue -= _division;
                        else
                          _selectedValue = _minValue;
                      } else {
                        if (_selectedValue - 0.1 >= _minValue)
                          _selectedValue -= 0.1;
                        else
                          _selectedValue = _minValue;
                      }
                      //if (_selectedValue - 0.1 >= _minValue)
                      // _division != 1
                      //     ? _selectedValue -= _division
                      //     : _selectedValue -= 0.1;
                      //else
                      //  _selectedValue = _minValue;
                    } else {
                      if (_division != 1) {
                        if (_selectedValue - _division >= _minValue)
                          _selectedValue -= _division;
                        else
                          _selectedValue = _minValue;
                      } else {
                        if (_selectedValue - 1 >= _minValue)
                          _selectedValue -= 1;
                        else
                          _selectedValue = _minValue;
                      }
                      //if (_selectedValue - 1 >= _minValue)
                      //  _division != 1
                      //      ? _selectedValue -= _division
                      //      : _selectedValue -= 1;
                      //else
                      //  _selectedValue = _minValue;
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
                  thumbShape: RoundSliderThumbShape(enabledThumbRadius: 15.0),
                  thumbColor: Color(0xFFEB1555),
                  activeTrackColor: Colors.white,
                  overlayColor: Color(0x29EB1555),
                  inactiveTrackColor: Color(0xFF8D8E98),
                ),
                child: Container(
                  width: 400.0,
                  child: Slider(
                    divisions: ((_maxValue - _minValue) ~/ _division),
                    value: _selectedValue,
                    min: _minValue,
                    max: _maxValue,
                    onChanged: (value) {
                      setState(() {
                        _selectedValue = value;
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
                      if (_division != 1) {
                        if (_selectedValue + _division <= _maxValue)
                          _selectedValue += _division;
                        else
                          _selectedValue = _maxValue;
                      } else {
                        if (_selectedValue + 0.1 <= _maxValue)
                          _selectedValue += 0.1;
                        else
                          _selectedValue = _maxValue;
                      }

                      /*if (_selectedValue + 0.1 <= _maxValue)
                        _division != 1
                            ? _selectedValue += _division
                            : _selectedValue += 0.1;
                      else
                        _selectedValue = _maxValue;*/
                    } else {
                      if (_division != 1) {
                        if (_selectedValue + _division <= _maxValue)
                          _selectedValue += _division;
                        else
                          _selectedValue = _maxValue;
                      } else {
                        if (_selectedValue + 1 <= _maxValue)
                          _selectedValue += 1;
                        else
                          _selectedValue = _maxValue;
                      }
                      /*if (_selectedValue + 1 <= _maxValue)
                        _division != 1
                            ? _selectedValue += _division
                            : _selectedValue += 1;
                      else
                        _selectedValue = _maxValue;*/
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
              Navigator.pop(context, _selectedValue);
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
