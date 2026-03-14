import 'package:flutter/material.dart';
import 'package:flutterappventilator/component/reusablecard.dart';

class SettingButton extends StatelessWidget {
  final Color btnColor;
  final Function onPress;
  final Function onLongPress;
  final String title;
  final String unit;
  final int value;
  final bool unitFront;
  final double decimalValue;
  final bool isDecimal;
  SettingButton(
      {this.btnColor,
      this.title,
      this.value = 0,
      this.unit,
      this.onPress,
      this.unitFront = false,
      this.decimalValue = 0.0,
      this.isDecimal = false,
      this.onLongPress});

  Text checkUnitFront(bool unitFront, bool isDecimal) {
    if (unitFront) {
      String text;
      if (isDecimal) {
        text = unit + ' ' + decimalValue.toString();
      } else {
        text = unit + ' ' + value.toString();
      }
      return Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 18.0),
      );
    }
    return Text(
      (isDecimal)
          ? decimalValue.toString() + ' ' + unit
          : value.toString() + ' ' + unit,
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 18.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onLongPress: onLongPress,
        child: ReusableCard(
          colour: btnColor,
          cardChild: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18.0),
              ),
              checkUnitFront(unitFront, isDecimal),
            ],
          ),
          onPress: onPress,
        ),
      ),
    );
  }
}
