import 'package:flutter/material.dart';

class AlarmBox extends StatelessWidget {
  final String upperText;
  final String lowerText;
  final Color bgColor;
  final Function onPress;
  final Function doubleTap;

  final double _upperTextSize = 20.0;
  final double _lowerTextSize = 10.0;

  AlarmBox(
      {this.upperText,
      this.lowerText,
      this.bgColor,
      this.onPress,
      this.doubleTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(2.0),
        child: Material(
          elevation: 1.0,
          color: bgColor,
          borderRadius: BorderRadius.circular(5.0),
          child: InkWell(
            onDoubleTap: doubleTap,
            onTap: onPress,
            child: Container(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Text(
                    upperText,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: _upperTextSize),
                  ),
                  Text(
                    lowerText,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: _lowerTextSize),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
