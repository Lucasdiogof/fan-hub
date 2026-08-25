import 'package:flutter/rendering.dart';

class CircleRevealClipper extends CustomClipper<Path> {
  const CircleRevealClipper({required this.center, required this.radius});

  final Offset center;
  final double radius;

  @override
  Path getClip(Size size) =>
      Path()..addOval(Rect.fromCircle(center: center, radius: radius));

  @override
  bool shouldReclip(CircleRevealClipper oldClipper) =>
      oldClipper.radius != radius || oldClipper.center != center;
}
