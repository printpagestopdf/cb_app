import 'package:flutter/material.dart';
import 'package:cb_app/parts/utils.dart';
import 'dart:math';
import 'dart:ui' as ui;
// import 'dart:math' as math;

class _SpiralCircle {
  double x, y, radius, angle, speed, angularSpeed;
  Color color;

  _SpiralCircle(this.x, this.y, this.radius, this.angle, this.speed, this.angularSpeed, this.color);

  void update(double t) {
    x = x + cos(angle) * speed * t;
    y = y + sin(angle) * speed * t;
    angle += angularSpeed * t;
  }
}

class AnimatedBackground extends StatefulWidget {
  final double? width;
  final double? height;

  const AnimatedBackground({this.width, this.height, super.key});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground> with SingleTickerProviderStateMixin {
  late List<_SpiralCircle> circles;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    circles = List.generate((max(widget.width ?? 100, widget.height ?? 100) / 2).abs().toInt(), (_) {
      const centerX = 0.0;
      // (widget.width ?? 0) / 2;
      // 100.0; // Mittelpunkt des Bildschirms
      const centerY = 0.0;
      // (widget.height ?? 0) / 2;
      // 100.0; // Mittelpunkt des Bildschirms
      final radius = Random().nextDouble() * 10 + 5;
      final angle = Random().nextDouble() * 2 * pi;
      final speed = Random().nextDouble() * 100 + 50;
      final angularSpeed = Random().nextDouble() * pi;
      final color = Color.fromARGB(
        255,
        Random().nextInt(256),
        Random().nextInt(256),
        Random().nextInt(256),
      );

      return _SpiralCircle(centerX, centerY, radius, angle, speed, angularSpeed, color);
    });

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    );

    _controller.repeat();

    _controller.addListener(() {
      for (var circle in circles) {
        circle.update(1.0 / 180.0);
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BackgroundPainter(circles),
    );
  }
}

class _BackgroundPainter extends CustomPainter {
  final List<_SpiralCircle> circles;

  _BackgroundPainter(this.circles);

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()
      ..shader = const SweepGradient(
        center: FractionalOffset.center,
        colors: <Color>[
          Color(0xFF4285F4), // blue
          Color(0xFF34A853), // green
          Color(0xFFFBBC05), // yellow
          Color(0xFFEA4335), // red
          Color(0xFF4285F4), // blue again to seamlessly transition to the start
        ],
        stops: <double>[0.0, 0.25, 0.5, 0.75, 1.0],
        transform: GradientRotation(pi / 4),
      ).createShader(Rect.largest);
    canvas.drawRect(Rect.largest, backgroundPaint);

    for (var circle in circles) {
      final x = circle.x;
      final y = circle.y;
      final radius = circle.radius;
      final color = circle.color;
      final circlePaint = Paint()..color = color;

      canvas.drawCircle(Offset(x, y), radius, circlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
