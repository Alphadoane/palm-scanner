import 'package:flutter/material.dart';
import '../services/native_bridge.dart';
import '../widgets/ar_overlay.dart';
import '../widgets/confidence_card.dart';

class CameraScreen extends StatefulWidget {
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final NativeBridge bridge = NativeBridge();
  List<String> results = [];
  double confidence = 0.0;

  // AR Overlay Data
  List<dynamic> nodes = [];
  List<dynamic> edges = [];
  List<dynamic> labelPositions = [];

  @override
  void initState() {
    super.initState();
    bridge.startCamera();
    bridge.streamResults().listen((data) {
      if (mounted) {
        setState(() {
          results = List<String>.from(data['labels'] ?? []);
          confidence = (data['confidence'] ?? 0.0).toDouble();
          nodes = data['nodes'] ?? [];
          edges = data['edges'] ?? [];
          labelPositions = data['labelPositions'] ?? [];
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Native camera preview is rendered underneath by the native layer
          Container(
            color: Colors.black,
            child: const Center(
              child: Text("Native Camera Preview Placeholder", style: TextStyle(color: Colors.grey)),
            ),
          ),
          
          // AR Overlay rendering
          PalmOverlay(
            labels: results,
            nodes: nodes,
            edges: edges,
            labelPositions: labelPositions,
          ),
          
          // Results Panel at the bottom
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ConfidenceCard(confidence: confidence),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: results.map((label) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            const Icon(Icons.back_hand, color: Colors.blueAccent, size: 20),
                            const SizedBox(width: 8),
                            Text(label, style: const TextStyle(color: Colors.white, fontSize: 16)),
                          ],
                        ),
                      )).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
