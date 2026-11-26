import 'package:flutter/material.dart';

enum PipPose { map, point, perch }

/// Pip's three illustrations share one resolution-independent drawing.
class Pip extends StatelessWidget {
  final PipPose pose;
  const Pip(this.pose, {super.key});

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(size: const Size(102, 92), painter: _PipPainter(pose)),
  );
}

class _PipPainter extends CustomPainter {
  final PipPose pose;
  _PipPainter(this.pose);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 102, size.height / 92);
    const ink = Color(0xff273d39), chestnut = Color(0xff975931);
    final paint = Paint();
    void oval(double x, double y, double w, double h, Color color) {
      canvas.drawOval(Rect.fromLTWH(x, y, w, h), paint..color = color);
    }

    void shape(List<Offset> points, Color color) {
      canvas.drawPath(Path()..addPolygon(points, true), paint..color = color);
    }

    oval(8, 76, 86, 5, const Color(0xffcfdbca));
    for (final x in [44.0, 54.0]) {
      canvas.drawLine(
        Offset(x, 67),
        Offset(x - 2, 77),
        paint
          ..color = ink
          ..strokeWidth = 2,
      );
      canvas.drawLine(Offset(x - 4, 77), Offset(x + 4, 77), paint);
    }
    shape(const [
      Offset(34, 51),
      Offset(4, 44),
      Offset(16, 61),
      Offset(42, 65),
    ], chestnut);
    oval(23, 32, 49, 41, const Color(0xffbd8859));
    oval(39, 32, 34, 38, const Color(0xfff6ddb5));
    oval(40, 12, 38, 36, chestnut);
    oval(47, 24, 31, 23, const Color(0xffffebcb));
    oval(53, 31, 10, 9, ink);
    oval(66, 23, 5, 5, ink);
    shape(const [Offset(76, 27), Offset(88, 30), Offset(76, 34)], ink);
    if (pose != PipPose.perch) {
      final y = pose == PipPose.point ? 56.0 : 45.0;
      shape([
        Offset(54, y),
        Offset(65, y + 3),
        Offset(75, y),
        Offset(87, y + 4),
        Offset(85, y + 20),
        Offset(74, y + 17),
        Offset(64, y + 20),
        Offset(52, y + 16),
      ], const Color(0xff246f65));
      shape([
        Offset(65, y + 3),
        Offset(75, y),
        Offset(74, y + 17),
        Offset(64, y + 20),
      ], const Color(0xffa5cabc));
    }
    canvas.save();
    canvas.translate(39, 48);
    canvas.rotate(pose == PipPose.point ? -.45 : .35);
    oval(-15, -2, pose == PipPose.point ? 44 : 30, 13, chestnut);
    canvas.restore();
    if (pose == PipPose.perch) {
      canvas.drawLine(
        const Offset(22, 78),
        const Offset(76, 78),
        paint
          ..color = chestnut
          ..strokeWidth = 3,
      );
    }
  }

  @override
  bool shouldRepaint(_PipPainter oldDelegate) => pose != oldDelegate.pose;
}
