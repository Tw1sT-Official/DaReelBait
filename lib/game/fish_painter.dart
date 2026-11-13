import 'dart:math';
import 'package:flutter/material.dart';
import '../models/fish.dart';

class FishCatchPainter extends CustomPainter {
  final CaughtFish fish;
  final bool hasScaleAndTape;
  final double animationProgress; // subtle fin sway and breathing

  FishCatchPainter({
    required this.fish,
    required this.hasScaleAndTape,
    this.animationProgress = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Weathered Cedar Wood Dock Planks
    _drawDock(canvas, size);

    // 2. Draw Measuring Tape (underneath the fish)
    _drawMeasuringTape(canvas, size);

    // 3. Draw Anatomically Scaled Fish
    _drawFish(canvas, size);

    // 4. Draw Glistening Water Droplets
    _drawWaterDroplets(canvas, size);
  }

  void _drawDock(Canvas canvas, Size size) {
    // Weathered cedar planks with grain
    final plankColors = [
      const Color(0xFF4E342E),
      const Color(0xFF3E2723),
      const Color(0xFF5D4037),
      const Color(0xFF4E342E),
    ];

    const plankHeight = 55.0;
    for (double y = 0; y < size.height; y += plankHeight) {
      final idx = ((y / plankHeight).floor()) % plankColors.length;
      final paint = Paint()..color = plankColors[idx];
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, plankHeight - 2), paint);

      // Plank gap shadow
      final gapPaint = Paint()..color = Colors.black87;
      canvas.drawRect(Rect.fromLTWH(0, y + plankHeight - 2, size.width, 2), gapPaint);
    }
  }

  void _drawMeasuringTape(Canvas canvas, Size size) {
    final tapeY = size.height * 0.76;
    final tapeHeight = 24.0;

    // Yellow vintage cloth/steel measuring tape
    final tapePaint = Paint()..color = const Color(0xFFFFD54F);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(20, tapeY, size.width - 40, tapeHeight),
        const Radius.circular(4),
      ),
      tapePaint,
    );

    // Centimeter tick marks
    final tickPaint = Paint()
      ..color = Colors.black87
      ..strokeWidth = 1.0;

    final step = (size.width - 60) / 10.0;
    for (int i = 0; i <= 10; i++) {
      final x = 30 + i * step;
      final isMajor = i % 2 == 0;
      final tickH = isMajor ? 12.0 : 6.0;
      canvas.drawLine(Offset(x, tapeY), Offset(x, tapeY + tickH), tickPaint);
    }
  }

  void _drawFish(Canvas canvas, Size size) {
    final species = fish.species;

    // Center fish on dock
    final centerX = size.width * 0.5;
    final centerY = size.height * 0.42;

    // Dynamic width & height based on real length & girth
    // Map length (10cm - 120cm) to canvas pixels (140px - 280px)
    final lengthPixels = (fish.lengthCm * 2.8).clamp(150.0, size.width * 0.85);
    final heightPixels = (fish.girthCm * 2.2).clamp(45.0, 110.0);

    final left = centerX - (lengthPixels / 2.0);
    final right = centerX + (lengthPixels / 2.0);
    final top = centerY - (heightPixels / 2.0);
    final bottom = centerY + (heightPixels / 2.0);

    // 1. Draw Tail Fin (Caudal)
    final tailPaint = Paint()
      ..color = species.secondaryColor
      ..style = PaintingStyle.fill;

    final tailSway = sin(animationProgress * 6) * 3.0;
    final tailPath = Path()
      ..moveTo(left + (lengthPixels * 0.12), centerY)
      ..lineTo(left - 20, top + tailSway)
      ..quadraticBezierTo(left - 5, centerY, left - 20, bottom + tailSway)
      ..close();
    canvas.drawPath(tailPath, tailPaint);

    // 2. Draw Fish Body Ellipse Path
    final bodyPath = Path();
    bodyPath.moveTo(right, centerY); // Snout
    bodyPath.quadraticBezierTo(
      centerX + (lengthPixels * 0.1),
      top,
      left + (lengthPixels * 0.12),
      centerY,
    ); // Dorsal curve
    bodyPath.quadraticBezierTo(
      centerX + (lengthPixels * 0.1),
      bottom,
      right,
      centerY,
    ); // Belly curve
    bodyPath.close();

    // Body Gradient
    final bodyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          species.secondaryColor,
          species.primaryColor,
          species.bellyColor,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTRB(left, top, right, bottom));

    // Shadow on dock
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10.0);
    canvas.drawPath(bodyPath, shadowPaint);

    // Render Body
    canvas.drawPath(bodyPath, bodyPaint);

    // 3. Draw Lateral Line & Scale Texture
    final lateralPaint = Paint()
      ..color = Colors.black26
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawLine(
      Offset(left + lengthPixels * 0.18, centerY),
      Offset(right - lengthPixels * 0.22, centerY),
      lateralPaint,
    );

    // 4. Draw Dorsal & Pectoral Fins
    final finPaint = Paint()..color = species.primaryColor.withValues(alpha: 0.85);
    final dorsalPath = Path()
      ..moveTo(centerX - 20, top + 4)
      ..quadraticBezierTo(centerX, top - 18, centerX + 30, top + 4)
      ..close();
    canvas.drawPath(dorsalPath, finPaint);

    // Pectoral fin
    final pectoralPath = Path()
      ..moveTo(centerX + lengthPixels * 0.18, centerY + 6)
      ..quadraticBezierTo(centerX + lengthPixels * 0.14, centerY + 24, centerX + lengthPixels * 0.26, centerY + 18)
      ..close();
    canvas.drawPath(pectoralPath, finPaint);

    // 5. Draw Eye & Gills
    final eyePos = Offset(right - lengthPixels * 0.14, centerY - heightPixels * 0.15);
    // Eye white
    canvas.drawCircle(eyePos, 5.5, Paint()..color = Colors.white);
    // Iris gold
    canvas.drawCircle(eyePos, 4.0, Paint()..color = const Color(0xFFFFD54F));
    // Pupil
    canvas.drawCircle(eyePos, 2.5, Paint()..color = Colors.black);
    // Glint
    canvas.drawCircle(eyePos - const Offset(1, 1), 1.0, Paint()..color = Colors.white);

    // Gill curve
    final gillPaint = Paint()
      ..color = Colors.black38
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(right - lengthPixels * 0.24, centerY),
        width: heightPixels * 0.4,
        height: heightPixels * 0.75,
      ),
      -pi / 2,
      pi,
      false,
      gillPaint,
    );
  }

  void _drawWaterDroplets(Canvas canvas, Size size) {
    final dropletPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.75)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2);

    final droplets = [
      Offset(size.width * 0.45, size.height * 0.38),
      Offset(size.width * 0.52, size.height * 0.44),
      Offset(size.width * 0.38, size.height * 0.41),
      Offset(size.width * 0.62, size.height * 0.39),
      Offset(size.width * 0.68, size.height * 0.43),
    ];

    for (final d in droplets) {
      canvas.drawCircle(d, 2.0, dropletPaint);
    }
  }

  @override
  bool shouldRepaint(covariant FishCatchPainter oldDelegate) => true;
}
