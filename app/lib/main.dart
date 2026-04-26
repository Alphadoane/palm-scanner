import 'package:flutter/material.dart';
import 'screens/camera_screen.dart';

void main() {
  runApp(const PalmistryApp());
}

class PalmistryApp extends StatelessWidget {
  const PalmistryApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AR Palmistry AI',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
      ),
      home: CameraScreen(),
    );
  }
}
