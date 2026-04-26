import 'package:flutter/material.dart';

class ConfidenceCard extends StatelessWidget {
  final double confidence;
  const ConfidenceCard({required this.confidence, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color confidenceColor;
    if (confidence > 0.8) {
      confidenceColor = Colors.greenAccent;
    } else if (confidence > 0.5) {
      confidenceColor = Colors.orangeAccent;
    } else {
      confidenceColor = Colors.redAccent;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Interpretation Confidence",
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            Text(
              "${(confidence * 100).toStringAsFixed(1)}%",
              style: TextStyle(color: confidenceColor, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: confidence,
            backgroundColor: Colors.grey[800],
            color: confidenceColor,
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}
