import 'package:flutter/material.dart';
import 'main_navigation.dart';

void main() {
  runApp(const PalmistryApp());
}

class PalmistryApp extends StatelessWidget {
  const PalmistryApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AR Palmistry AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.blueAccent,
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const MainNavigation(),
    );
  }
}
