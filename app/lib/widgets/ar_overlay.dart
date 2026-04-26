import 'package:flutter/material.dart';

class PalmOverlay extends StatelessWidget {
  final List<String> labels;
  final List<dynamic> nodes;
  final List<dynamic> edges;
  final List<dynamic> labelPositions;

  const PalmOverlay({
    required this.labels,
    required this.nodes,
    required this.edges,
    required this.labelPositions,
  });

  Color _getLineColor(String type) {
    switch (type) {
      case 'life_line': return Colors.greenAccent;
      case 'head_line': return Colors.blueAccent;
      case 'heart_line': return Colors.redAccent;
      case 'fate_line': return Colors.purpleAccent;
      case 'sun_line': return Colors.orangeAccent;
      case 'health_line': return Colors.yellowAccent;
      case 'marriage_line': return Colors.pinkAccent;
      case 'money_line': return Colors.lightGreenAccent;
      case 'travel_lines': return Colors.cyanAccent;
      case 'girdle_of_venus': return Colors.deepOrangeAccent;
      case 'ring_of_solomon': return Colors.indigoAccent;
      case 'ring_of_saturn': return Colors.tealAccent;
      case 'ring_of_apollo': return Colors.amberAccent;
      case 'ring_of_mercury': return Colors.lightBlueAccent;
      case 'bracelet_lines': return Colors.white70;
      default: return Colors.white54;
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: PalmPainter(
        nodes: nodes,
        edges: edges,
        labelPositions: labelPositions,
        lineColors: { for (var n in nodes) n['type']: _getLineColor(n['type']) },
      ),
    );
  }
}

class PalmPainter extends CustomPainter {
  final List<dynamic> nodes;
  final List<dynamic> edges;
  final List<dynamic> labelPositions;
  final Map<String, Color> lineColors;

  PalmPainter({
    required this.nodes,
    required this.edges,
    required this.labelPositions,
    required this.lineColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    // Draw Nodes (Centers of detected lines)
    for (var node in nodes) {
      paint.color = lineColors[node['type']] ?? Colors.white;
      canvas.drawCircle(Offset(node['x'], node['y']), 6.0, paint);
      
      // Draw small halo
      canvas.drawCircle(
        Offset(node['x'], node['y']), 
        10.0, 
        paint..color = paint.color.withOpacity(0.3)
      );
    }

    // Draw Edges (Relationships)
    for (var edge in edges) {
      final startNode = nodes.firstWhere((n) => n['id'] == edge[0]);
      final endNode = nodes.firstWhere((n) => n['id'] == edge[1]);
      
      paint.color = Colors.white.withOpacity(0.5);
      paint.strokeWidth = 2.0;
      canvas.drawLine(
        Offset(startNode['x'], startNode['y']),
        Offset(endNode['x'], endNode['y']),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
