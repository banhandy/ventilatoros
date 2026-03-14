import 'package:flutter/material.dart';

class ReusableCard extends StatelessWidget {
  ReusableCard({@required this.colour, this.cardChild, this.onPress});
  final Color colour;
  final Widget cardChild;
  final Function onPress;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Material(
        elevation: 1.0,
        color: colour,
        borderRadius: BorderRadius.circular(10.0),
        child: InkWell(
          onTap: onPress,
          child: Container(
            child: cardChild,
          ),
        ),
      ),
    );
  }
}
