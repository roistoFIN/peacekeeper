import 'package:flutter/material.dart';

class PeacekeeperLogo extends StatelessWidget {
  final double size;
  final Color? color;

  const PeacekeeperLogo({super.key, this.size = 24.0, this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: size,
      width: size,
      child: CustomPaint(
        painter: PeacekeeperLogoPainter(color: color),
      ),
    );
  }
}

class PeacekeeperLogoPainter extends CustomPainter {
  final Color? color;

  PeacekeeperLogoPainter({this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color ?? const Color(0xFF607D8B) // Default: Blue Grey 500
      ..style = PaintingStyle.fill;

    // Scale logic to fit 512x512 path into `size`
    final scale = size.width / 512;
    canvas.scale(scale, scale);

    // Shield/Heart Path (Same as SVG/VectorDrawable)
    final path = Path();
    path.moveTo(256, 460);
    path.cubicTo(256, 460, 64, 360, 64, 180);
    path.cubicTo(64, 120, 100, 80, 160, 80);
    path.cubicTo(200, 80, 230, 100, 256, 130);
    path.cubicTo(282, 100, 312, 80, 352, 80);
    path.cubicTo(412, 80, 448, 120, 448, 180);
    path.cubicTo(448, 360, 256, 460, 256, 460);
    path.close();

    canvas.drawPath(path, paint);

    // Inner Line (Smile/Dove Wing)
    final linePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final linePath = Path();
    linePath.moveTo(160, 180);
    linePath.cubicTo(160, 180, 200, 220, 256, 220);
    linePath.cubicTo(312, 220, 352, 180, 352, 180);

    canvas.drawPath(linePath, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
