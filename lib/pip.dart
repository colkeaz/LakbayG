import 'package:flutter/material.dart';

enum PipPose { map, point, perch }

class Pip extends StatelessWidget {
  final PipPose pose;
  final double width;
  const Pip(this.pose, {super.key, this.width = 102});

  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/pip/${pose.name}.png',
    width: width,
    height: width * 92 / 102,
    fit: BoxFit.contain,
    excludeFromSemantics: true,
  );
}

/// Points toward a guide instruction, giving scaled text the full row.
class PipCue extends StatelessWidget {
  final Widget child;
  const PipCue({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.textScalerOf(context).scale(16) >= 28) return child;
    return Row(
      children: [
        const Pip(PipPose.point, width: 52),
        const SizedBox(width: 10),
        Expanded(child: child),
      ],
    );
  }
}
