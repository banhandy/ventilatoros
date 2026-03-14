import 'package:flutter/material.dart';
import 'package:flutterappventilator/screen/monitor.dart';
import 'package:flutterappventilator/screen/ventselection.dart';
import 'screen/patientdetails.dart';
import 'constants.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zenmed+ Ventilator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        primaryColor: kPrimaryColor,
        scaffoldBackgroundColor: kPrimaryColor,
        accentColor: kAccentColor,
      ),
      initialRoute: PatientDetailsPage.id,
      routes: {
        PatientDetailsPage.id: (context) => PatientDetailsPage(),
        VentSelectionPage.id: (context) => VentSelectionPage(),
        MonitorPage.id: (context) => MonitorPage(),
      },
    );
  }
}
