import 'package:flutter/material.dart';

class InfoBox extends StatelessWidget {
  final String upperText;
  final String lowerText;
  final double value;
  final Color bgColor;
  final bool isInteger;
  final bool frontUnit;
  final Function onPress;

  final double _upperTextSize = 30.0;
  final double _lowerTextSize = 20.0;

  InfoBox({
    this.value,
    this.upperText,
    this.lowerText,
    this.bgColor,
    this.isInteger,
    this.frontUnit = false,
    this.onPress,
  });

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
            onTap: onPress,
            child: Container(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                  Text(
                    upperText,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: _upperTextSize),
                  ),
                  SizedBox(
                    height: 10.0,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: frontUnit
                        ? [
                            Text(
                              lowerText,
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: _lowerTextSize),
                            ),
                            Text(
                              isInteger
                                  ? value.toStringAsFixed(0)
                                  : value.toStringAsFixed(1),
                              style: TextStyle(fontSize: 40.0),
                            ),
                          ]
                        : [
                            Text(
                              isInteger
                                  ? value.toStringAsFixed(0)
                                  : value.toStringAsFixed(1),
                              style: TextStyle(fontSize: 40.0),
                            ),
                            Text(
                              lowerText,
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: _lowerTextSize),
                            ),
                          ],
                  ),
                ])),
          ),
        ),
      ),
    );
  }
}
