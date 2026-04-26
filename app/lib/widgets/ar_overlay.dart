import 'package:flutter/material.dart';
import 'palm_label_chip.dart';

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
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Custom painter for edges and nodes
        CustomPaint(
          size: Size.infinite,
          painter: PalmGraphPainter(nodes: nodes, edges: edges),
        ),
        
        // Animated AR labels
        ...labelPositions.map((pos) {
          int index = labelPositions.indexOf(pos);
          if (index >= labels.length) return const SizedBox.shrink();
          
          return AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            left: (pos['x'] ?? 0).toDouble(),
            top: (pos['y'] ?? 0).toDouble(),
            child: PalmLabelChip(text: labels[index]),
          );
        }).toList(),
      ],
    );
  }
}

class PalmGraphPainter extends CustomPainter {
  final List<dynamic> nodes;
  final List<dynamic> edges;

  PalmGraphPainter({required this.nodes, required this.edges});

  @override
  void paint(Canvas canvas, Size size) {
    final paintLine = Paint()
      ..color = Colors.greenAccent.withOpacity(0.8)
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    final paintNode = Paint()
      ..color = Colors.redAccent
      ..style = Paint.Style.fill;

    // Draw edges
    for (var edge in edges) {
      if (edge is List && edge.length == 2) {
        int aIdx = edge[0];
        int bIdx = edge[1];
        if (aIdx < nodes.length && bIdx < nodes.length) {
          var a = nodes[aIdx];
          var b = nodes[bIdx];
          canvas.drawLine(
            Offset((a['x'] ?? 0).toDouble(), (a['y'] ?? 0).toDouble()),
            Offset((b['x'] ?? 0).toDouble(), (b['y'] ?? 0).toDouble()),
            paintLine,
          );
        }
      }
    }

    // Draw nodes
    for (var node in nodes) {
      canvas.drawCircle(
        Offset((node['x'] ?? 0).toDouble(), (node['y'] ?? 0).toDouble()),
        6.0,
        paintNode,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
