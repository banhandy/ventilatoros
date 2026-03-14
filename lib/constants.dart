import 'package:flutter/material.dart';

Color kSecondaryColor = Color.fromRGBO(64, 75, 96, .9);
Color kPrimaryColor = Color.fromRGBO(58, 66, 86, 1.0);
Color kAccentColor = Colors.redAccent;

const BoxDecoration kBoxBorderOneSide = BoxDecoration(
    border: Border(right: BorderSide(width: 1.0, color: Colors.white24)));

int kLineSegment = 4;
int kMaxHeight = 250;
int kMinHeight = 130;
int kDataWidth = 150;
int kXSegment = 3;
double kVtIBW = 8;

String kVentSeries = "V-900-SE AHR";
String kSerialNumber = "S/N : 00001";

//class InfoFile {
//  static int iDay;
//  static int iHour;
//  static int iMinute;
//  static int iSecond;
//}

class InfoIdle {
  static bool bdelay;
}

class InfoPage {
  static bool bInfo;
  static int iStart;
  static int iStartDB;
  static int iEnd;
  static int iLength;
  static String startDate;
}

class LogPage {
  static int iStart;
  static int iLength;
  static int iTotalData;
}
