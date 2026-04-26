import 'package:flutter/material.dart';

class AppState extends ChangeNotifier {
  List<String> labels = [];
  double confidence = 0.0;
  bool isProcessing = false;
  List<dynamic> nodes = [];
  List<dynamic> edges = [];
  List<dynamic> labelPositions = [];

  void updateResults(Map<dynamic, dynamic> data) {
    labels = List<String>.from(data['labels'] ?? []);
    confidence = (data['confidence'] ?? 0.0).toDouble();
    nodes = data['nodes'] ?? [];
    edges = data['edges'] ?? [];
    labelPositions = data['labelPositions'] ?? [];
    notifyListeners();
  }
}
