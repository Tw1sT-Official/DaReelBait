import 'dart:math';
import 'package:flutter/material.dart';

enum FishingState {
  idle,
  casting,
  waitingForBite,
  nibbling,
  hooked,
  reelingFight,
  catchLanded,
}

class WaterPainter extends CustomPainter {
  final double timeSeconds;
  final FishingState state;
  final double castProgress; // 0.0 to 1.0
  final double tension; // 0.0 (slack) to 1.0 (snapping)
  final double rodSteerAngle; // -1.0 (left) to 1.0 (right)
  final double fishDistanceMeters; // e.g. 25m down to 0m
  final double fishLateralOffset; // -1.0 (swimming left) to 1.0 (swimming right)
  final bool hasBobberSubmerged;
  final int currentHour; // real device hour
  final String locationType; // lake, creek, river, bayou, ocean

  WaterPainter({
    required this.timeSeconds,
    required this.state,
    required this.castProgress,
    required this.tension,
    required this.rodSteerAngle,
    required this.fishDistanceMeters,
    required this.fishLateralOffset,
    required this.hasBobberSubmerged,
    required this.currentHour,
    this.locationType = 'lake',
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Real-Time Atmospheric Sky & Horizon
    _drawSkyAndHorizon(canvas, size);

    // 2. Draw Distant Mountains / Shoreline
    _drawShoreline(canvas, size);

    // 3. Draw Water Surface with Layered Sine Ripples
    _drawWaterSurface(canvas, size);

    // 4. Draw Floating Vegetation (Lily Pads & Reeds)
    _drawVegetation(canvas, size);

    // 5. Draw Underwater Shadows (approaching fish)
    _drawUnderwaterShadows(canvas, size);

    // 6. Draw Fishing Line & Bobber
    _drawBobberAndLine(canvas, size);

    // 7. Draw Procedural Flexible Fishing Rod
    _drawFishingRod(canvas, size);
  }

  void _drawSkyAndHorizon(Canvas canvas, Size size) {
    List<Color> skyColors;
    double horizonY = size.height * 0.42;

    if (currentHour >= 6 && currentHour < 11) {
      // 🌅 Morning: Soft golden peach to pale sky blue
      skyColors = [
        const Color(0xFF90CAF9),
        const Color(0xFFFFCC80),
        const Color(0xFFFFE0B2),
      ];
    } else if (currentHour >= 11 && currentHour < 16) {
      // ☀️ Midday: Crisp vibrant azure blue
      skyColors = [
        const Color(0xFF1E88E5),
        const Color(0xFF64B5F6),
        const Color(0xFFBBDEFB),
      ];
    } else if (currentHour >= 16 && currentHour < 20) {
      // 🌇 Golden Dusk: Rich amber, violet, and deep rose
      skyColors = [
        const Color(0xFF4A148C),
        const Color(0xFFC2185B),
        const Color(0xFFFF8F00),
      ];
    } else {
      // 🌙 Night: Deep starry indigo and midnight obsidian
      skyColors = [
        const Color(0xFF0A0E17),
        const Color(0xFF141E30),
        const Color(0xFF243B55),
      ];
    }

    final skyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: skyColors,
      ).createShader(Rect.fromLTWH(0, 0, size.width, horizonY));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, horizonY), skyPaint);

    // Sun or Moon
    final celestialPaint = Paint();
    if (currentHour >= 6 && currentHour < 20) {
      // Sun
      celestialPaint.color = currentHour >= 16 ? const Color(0xFFFFAB91) : const Color(0xFFFFF9C4);
      celestialPaint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      canvas.drawCircle(Offset(size.width * 0.75, horizonY * 0.45), 26, celestialPaint);
    } else {
      // Moon & Stars
      celestialPaint.color = const Color(0xFFFFFDE7);
      celestialPaint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(Offset(size.width * 0.8, horizonY * 0.35), 20, celestialPaint);

      // Distant stars
      final starPaint = Paint()..color = Colors.white70;
      final rng = Random(42);
      for (int i = 0; i < 35; i++) {
        final sx = rng.nextDouble() * size.width;
        final sy = rng.nextDouble() * (horizonY * 0.7);
        final twinkle = (sin(timeSeconds * 3 + i) * 0.5 + 0.5);
        canvas.drawCircle(Offset(sx, sy), 0.8 + twinkle * 0.8, starPaint);
      }
    }
  }

  void _drawShoreline(Canvas canvas, Size size) {
    final horizonY = size.height * 0.42;

    // Distant mountain layers
    final mountainPaint = Paint()
      ..color = (currentHour >= 20 || currentHour < 6)
          ? const Color(0xFF0F1724)
          : const Color(0xFF2D4030).withValues(alpha: 0.7);

    final path = Path();
    path.moveTo(0, horizonY);
    for (double x = 0; x <= size.width; x += 30) {
      final my = horizonY - 25 - sin((x / 70.0) + 1.2) * 18 - cos(x / 45.0) * 8;
      path.lineTo(x, my);
    }
    path.lineTo(size.width, horizonY);
    path.close();
    canvas.drawPath(path, mountainPaint);
  }

  void _drawWaterSurface(Canvas canvas, Size size) {
    final horizonY = size.height * 0.42;
    final waterHeight = size.height - horizonY;

    // Water Gradient based on time & depth
    List<Color> waterColors;
    if (currentHour >= 6 && currentHour < 11) {
      waterColors = [const Color(0xFF4DB6AC), const Color(0xFF00695C), const Color(0xFF004D40)];
    } else if (currentHour >= 11 && currentHour < 16) {
      waterColors = [const Color(0xFF0288D1), const Color(0xFF01579B), const Color(0xFF002F6C)];
    } else if (currentHour >= 16 && currentHour < 20) {
      waterColors = [const Color(0xFF7B1FA2), const Color(0xFF4A148C), const Color(0xFF1A0033)];
    } else {
      waterColors = [const Color(0xFF1A237E), const Color(0xFF0D1B2A), const Color(0xFF050811)];
    }

    final waterPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: waterColors,
      ).createShader(Rect.fromLTWH(0, horizonY, size.width, waterHeight));

    canvas.drawRect(Rect.fromLTWH(0, horizonY, size.width, waterHeight), waterPaint);

    // Layered Sine Waves (water ripples)
    final ripplePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (int i = 0; i < 7; i++) {
      final yBase = horizonY + 20 + i * (waterHeight / 8);
      final speed = 1.0 + (i * 0.2);
      final amp = 2.0 + (i * 0.8);

      final wavePath = Path();
      wavePath.moveTo(0, yBase);
      for (double x = 0; x <= size.width; x += 20) {
        final wy = yBase + sin((x / 50.0) + (timeSeconds * speed) + i) * amp;
        wavePath.lineTo(x, wy);
      }
      canvas.drawPath(wavePath, ripplePaint);
    }
  }

  void _drawVegetation(Canvas canvas, Size size) {
    final horizonY = size.height * 0.42;

    // Lily pads near edges
    final padPaint = Paint()..color = const Color(0xFF2E7D32);
    final flowerPaint = Paint()..color = const Color(0xFFFF80AB);

    final pads = [
      Offset(size.width * 0.12, horizonY + 70),
      Offset(size.width * 0.22, horizonY + 95),
      Offset(size.width * 0.82, horizonY + 80),
      Offset(size.width * 0.90, horizonY + 115),
    ];

    for (int i = 0; i < pads.length; i++) {
      final p = pads[i];
      final bob = sin(timeSeconds * 1.5 + i) * 1.5;
      final center = Offset(p.dx, p.dy + bob);

      // Pad oval
      canvas.drawOval(
        Rect.fromCenter(center: center, width: 36, height: 20),
        padPaint,
      );

      // Floating Lotus Blossom on pad 0 and 2
      if (i == 0 || i == 2) {
        canvas.drawCircle(center + const Offset(4, -3), 4.5, flowerPaint);
      }
    }
  }

  void _drawUnderwaterShadows(Canvas canvas, Size size) {
    if (state == FishingState.waitingForBite || state == FishingState.nibbling) {
      // Faint fish silhouette shadow circling near bobber
      final bobberPos = _getBobberPosition(size);
      final shadowPhase = timeSeconds * 0.9;
      final radius = state == FishingState.nibbling ? 18.0 : 45.0;

      final sx = bobberPos.dx + cos(shadowPhase) * radius;
      final sy = bobberPos.dy + sin(shadowPhase) * (radius * 0.4) + 12;

      final shadowPaint = Paint()
        ..color = Colors.black.withValues(alpha: state == FishingState.nibbling ? 0.35 : 0.20)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

      canvas.drawOval(
        Rect.fromCenter(center: Offset(sx, sy), width: 28, height: 10),
        shadowPaint,
      );
    } else if (state == FishingState.reelingFight) {
      // Splashing fish during fight
      final bobberPos = _getBobberPosition(size);
      final splashPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);

      final splashRadius = 10.0 + sin(timeSeconds * 15) * 4.0;
      canvas.drawCircle(bobberPos, splashRadius, splashPaint);
    }
  }

  Offset _getBobberPosition(Size size) {
    final horizonY = size.height * 0.42;
    final targetY = horizonY + (size.height * 0.22);
    final targetX = size.width * 0.5 + (fishLateralOffset * 80.0);

    if (state == FishingState.idle) {
      return Offset(size.width * 0.5, size.height * 0.65);
    }

    if (state == FishingState.casting) {
      // Arc path during cast
      final start = Offset(size.width * 0.85, size.height * 0.75);
      final midY = horizonY - 40;
      final t = castProgress;
      final cx = start.dx + (targetX - start.dx) * t;
      final cy = (1 - t) * (1 - t) * start.dy + 2 * (1 - t) * t * midY + t * t * targetY;
      return Offset(cx, cy);
    }

    // Floating bobber with wave bobbing
    final waveBob = sin(timeSeconds * 2.5) * 2.5;
    final nibbleBob = (state == FishingState.nibbling) ? sin(timeSeconds * 12) * 5.0 : 0.0;
    final submerge = hasBobberSubmerged ? 14.0 : 0.0;

    return Offset(targetX, targetY + waveBob + nibbleBob + submerge);
  }

  void _drawBobberAndLine(Canvas canvas, Size size) {
    if (state == FishingState.idle) return;

    final bobberPos = _getBobberPosition(size);
    final rodTip = _getRodTipPosition(size);

    // 1. Draw Curved Fishing Line (Bezier Physics)
    final linePaint = Paint()
      ..color = Colors.white70
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Sag depends on tension: slack sags heavily, taut is nearly straight
    final sag = (1.0 - tension).clamp(0.05, 1.0) * 60.0;
    final midX = (rodTip.dx + bobberPos.dx) / 2.0;
    final midY = ((rodTip.dy + bobberPos.dy) / 2.0) + sag;

    final linePath = Path()
      ..moveTo(rodTip.dx, rodTip.dy)
      ..quadraticBezierTo(midX, midY, bobberPos.dx, bobberPos.dy);

    canvas.drawPath(linePath, linePaint);

    // 2. Draw Floating Bobber (Red / White Classic)
    final bobberRadius = 8.0;

    // Outer ripple ring
    final ripplePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawOval(
      Rect.fromCenter(center: bobberPos + const Offset(0, 4), width: 22, height: 8),
      ripplePaint,
    );

    // Red top half
    final redPaint = Paint()..color = const Color(0xFFFF1744);
    canvas.drawArc(
      Rect.fromCircle(center: bobberPos, radius: bobberRadius),
      pi,
      pi,
      true,
      redPaint,
    );

    // White bottom half
    final whitePaint = Paint()..color = Colors.white;
    canvas.drawArc(
      Rect.fromCircle(center: bobberPos, radius: bobberRadius),
      0,
      pi,
      true,
      whitePaint,
    );

    // Center band
    final blackPaint = Paint()
      ..color = Colors.black87
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      bobberPos - Offset(bobberRadius, 0),
      bobberPos + Offset(bobberRadius, 0),
      blackPaint,
    );
  }

  Offset _getRodTipPosition(Size size) {
    // Dynamic rod deflection based on tension and left-hand steering angle
    final flexBend = tension * 45.0;
    final steerX = rodSteerAngle * 40.0;

    final tipX = (size.width * 0.72) + steerX - (flexBend * 0.6);
    final tipY = (size.height * 0.58) + (flexBend * 0.8);
    return Offset(tipX, tipY);
  }

  void _drawFishingRod(Canvas canvas, Size size) {
    final rodBase = Offset(size.width * 0.92, size.height + 10);
    final rodTip = _getRodTipPosition(size);

    // Rod shaft with realistic parabolic curve
    final rodPath = Path();
    rodPath.moveTo(rodBase.dx, rodBase.dy);

    final ctrlX = rodBase.dx - 40;
    final ctrlY = rodBase.dy - (rodBase.dy - rodTip.dy) * 0.5;

    rodPath.quadraticBezierTo(ctrlX, ctrlY, rodTip.dx, rodTip.dy);

    final rodPaint = Paint()
      ..color = const Color(0xFFD7CCC8) // Bamboo / warm composite
      ..strokeWidth = 5.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawPath(rodPath, rodPaint);

    // Rod guide rings & silver tip
    final tipGuidePaint = Paint()..color = const Color(0xFFECEFF1);
    canvas.drawCircle(rodTip, 3.5, tipGuidePaint);
  }

  @override
  bool shouldRepaint(covariant WaterPainter oldDelegate) => true;
}
