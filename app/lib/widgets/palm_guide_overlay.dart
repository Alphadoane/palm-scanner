import 'package:flutter/material.dart';

class PalmGuidePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final dashPaint = Paint()
      ..color = Colors.blueAccent.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final center = Offset(size.width / 2, size.height / 2);
    
    // Draw a stylized palm outline
    final path = Path();
    
    // Bottom of palm (wrist area)
    path.moveTo(center.dx - 60, center.dy + 150);
    path.quadraticBezierTo(center.dx, center.dy + 170, center.dx + 60, center.dy + 150);
    
    // Right side up to pinky
    path.lineTo(center.dx + 80, center.dy + 50);
    
    // Pinky
    path.quadraticBezierTo(center.dx + 90, center.dy - 50, center.dx + 60, center.dy - 60);
    path.quadraticBezierTo(center.dx + 40, center.dy - 50, center.dx + 45, center.dy);
    
    // Ring finger
    path.quadraticBezierTo(center.dx + 50, center.dy - 100, center.dx + 25, center.dy - 110);
    path.quadraticBezierTo(center.dx + 5, center.dy - 100, center.dx + 10, center.dy);
    
    // Middle finger
    path.quadraticBezierTo(center.dx + 15, center.dy - 130, center.dx - 10, center.dy - 140);
    path.quadraticBezierTo(center.dx - 35, center.dy - 130, center.dx - 25, center.dy);
    
    // Index finger
    path.quadraticBezierTo(center.dx - 30, center.dy - 110, center.dx - 55, center.dy - 120);
    path.quadraticBezierTo(center.dx - 80, center.dy - 110, center.dx - 65, center.dy);
    
    // Left side down to thumb
    path.quadraticBezierTo(center.dx - 100, center.dy + 20, center.dx - 120, center.dy + 50);
    
    // Thumb
    path.quadraticBezierTo(center.dx - 160, center.dy + 80, center.dx - 120, center.dy + 110);
    path.quadraticBezierTo(center.dx - 90, center.dy + 100, center.dx - 80, center.dy + 80);
    
    // Back to wrist
    path.lineTo(center.dx - 60, center.dy + 150);

    canvas.drawPath(path, paint);
    
    // Draw some scan lines or crosshair
    canvas.drawLine(
      Offset(center.dx - 20, center.dy),
      Offset(center.dx + 20, center.dy),
      dashPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - 20),
      Offset(center.dx, center.dy + 20),
      dashPaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class PalmGuideOverlay extends StatelessWidget {
  const PalmGuideOverlay({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: PalmGuidePainter(),
      ),
    );
  }
}
