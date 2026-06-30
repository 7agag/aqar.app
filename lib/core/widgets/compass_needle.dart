import 'package:flutter/material.dart';

class CompassNeedle extends StatelessWidget {
  final double rotation;

  const CompassNeedle({super.key, required this.rotation});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -rotation * (3.14159265359 / 180),
      child: SizedBox(
        width: 24,
        height: 24,
        child: CustomPaint(painter: const _CompassPainter()),
      ),
    );
  }
}

class _CompassPainter extends CustomPainter {
  const _CompassPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;

    final ringPaint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(Offset(cx, cy), r - 1, ringPaint);

    final northPaint = Paint()..color = Colors.red.shade400;
    final northPath = Path()
      ..moveTo(cx, cy - r + 2)
      ..lineTo(cx - r * 0.35, cy)
      ..lineTo(cx + r * 0.35, cy)
      ..close();
    canvas.drawPath(northPath, northPaint);

    final southPaint = Paint()..color = Colors.grey.shade300;
    final southPath = Path()
      ..moveTo(cx, cy + r - 2)
      ..lineTo(cx - r * 0.35, cy)
      ..lineTo(cx + r * 0.35, cy)
      ..close();
    canvas.drawPath(southPath, southPaint);

    canvas.drawCircle(
      Offset(cx, cy),
      1.5,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant _CompassPainter oldDelegate) => false;
}
