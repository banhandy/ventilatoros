import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutterappventilator/constants.dart';

class LogCard extends StatelessWidget {
  final String log;
  final DateTime date;

  final f = NumberFormat("#,###.0#", "en_US");

  LogCard({this.date, this.log});

  String generateMonth(int month) {
    String monthName = '';
    switch (month) {
      case (1):
        {
          monthName = 'JAN';
        }
        break;
      case (2):
        {
          monthName = 'FEB';
        }
        break;
      case (3):
        {
          monthName = 'MAR';
        }
        break;
      case (4):
        {
          monthName = 'APR';
        }
        break;
      case (5):
        {
          monthName = 'MAY';
        }
        break;
      case (6):
        {
          monthName = 'JUN';
        }
        break;
      case (7):
        {
          monthName = 'JUL';
        }
        break;
      case (8):
        {
          monthName = 'AUG';
        }
        break;
      case (9):
        {
          monthName = 'SEP';
        }
        break;
      case (10):
        {
          monthName = 'OCT';
        }
        break;
      case (11):
        {
          monthName = 'NOV';
        }
        break;
      case (12):
        {
          monthName = 'DEC';
        }
        break;
    }
    return monthName;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1.0,
      margin: EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
      child: Container(
        decoration: BoxDecoration(color: kPrimaryColor),
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
          leading: Container(
            padding: EdgeInsets.only(right: 10.0),
            decoration: kBoxBorderOneSide,
            child: Column(
              children: <Widget>[
                Text(
                  date.day.toString() + ' ' + generateMonth(date.month),
                  style: TextStyle(fontSize: 20.0),
                ),
                Text(
                  date.year.toString(),
                  style: TextStyle(fontSize: 20.0),
                ),
              ],
            ),
          ),
          title: Text(
            this.log,
            style: TextStyle(fontSize: 20.0),
          ),
          subtitle: Row(
            children: <Widget>[
              Text(
                this.date.hour.toString() +
                    ':' +
                    this.date.minute.toString() +
                    ':' +
                    this.date.second.toString(),
                style: TextStyle(fontSize: 20.0),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
