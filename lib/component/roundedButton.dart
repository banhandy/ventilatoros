import 'package:flutter/material.dart';

class ReusableButton extends StatelessWidget {
  final Function onPress;
  final String title;
  final Color btnColor;
  final double height;

  ReusableButton({this.title, this.onPress, this.btnColor, this.height});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPress,
      child: Container(
        height: height,
        child: Center(
            child: Text(
          title,
          style: TextStyle(fontSize: 30.0),
        )),
        margin: EdgeInsets.all(10.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.0),
          color: btnColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 5.0,
              spreadRadius: 0.0,
              offset: Offset(2.0, 2.0), // shadow direction: bottom right
            )
          ],
        ),
      ),
    );
  }
}
