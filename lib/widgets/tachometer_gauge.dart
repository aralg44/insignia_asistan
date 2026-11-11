import 'dart:math';
import 'package:flutter/material.dart';

class TachometerGauge extends StatelessWidget {
  final double rpm;
  final double speedKmh;
  final String currentGear;
  final bool isShiftLight;

  const TachometerGauge({
    super.key,
    required this.rpm,
    required this.speedKmh,
    required this.currentGear,
    required this.isShiftLight,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double gaugeSize = min(constraints.maxWidth, 275.0);
        return Center(
          child: SizedBox(
            width: gaugeSize,
            height: gaugeSize,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: Size(gaugeSize, gaugeSize),
                  painter: _GaugePainter(
                    rpm: rpm,
                    isShiftLight: isShiftLight,
                  ),
                ),
                // Kadran Merkezi Göstergeleri
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'VİTES',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.white38,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      // Anlık Vites Göstergesi
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 68,
                        height: 68,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isShiftLight
                                ? [Colors.redAccent.withOpacity(0.45), Colors.red.shade900.withOpacity(0.6)]
                                : [const Color(0xFF1A202C), const Color(0xFF0F131A)],
                          ),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isShiftLight
                                ? Colors.redAccent
                                : (currentGear == 'N'
                                    ? Colors.amberAccent.withOpacity(0.6)
                                    : Colors.cyanAccent.withOpacity(0.55)),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (isShiftLight
                                      ? Colors.redAccent
                                      : Colors.cyanAccent)
                                  .withOpacity(0.22),
                              blurRadius: 14,
                            ),
                          ],
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            currentGear,
                            style: TextStyle(
                              fontSize: 44,
                              height: 1.0,
                              fontWeight: FontWeight.w900,
                              color: isShiftLight
                                  ? Colors.redAccent
                                  : (currentGear == 'N' ? Colors.amberAccent : Colors.white),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Hız Bilgisi
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              speedKmh.toStringAsFixed(0),
                              style: const TextStyle(
                                fontSize: 34,
                                height: 1.05,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'km/s',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white54,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      // Devir Bilgisi
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${rpm.toStringAsFixed(0)} d/d',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isShiftLight ? Colors.redAccent : Colors.cyanAccent,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double rpm;
  final bool isShiftLight;

  _GaugePainter({required this.rpm, required this.isShiftLight});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 18;

    const startAngle = 135 * (pi / 180);
    const sweepAngle = 270 * (pi / 180);

    // Dış ince çerçeve
    final outerRingPaint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius + 12, outerRingPaint);

    // Arka plan yayın çizimi
    final bgPaint = Paint()
      ..color = const Color(0xFF1A1F2B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      bgPaint,
    );

    // Kadran kademe çizgileri (0..7 x1000 RPM)
    final tickPaint = Paint()
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i <= 14; i++) {
      final bool isMajor = i % 2 == 0;
      final double frac = i / 14.0;
      final double angle = startAngle + sweepAngle * frac;
      final bool isRedZone = i >= 12; // 6000+ RPM
      tickPaint.color = isRedZone
          ? Colors.redAccent.withOpacity(isMajor ? 0.85 : 0.45)
          : Colors.white.withOpacity(isMajor ? 0.35 : 0.15);
      tickPaint.strokeWidth = isMajor ? 2.2 : 1.2;

      final double innerR = radius - (isMajor ? 16 : 12);
      final double outerR = radius - 9;
      final p1 = Offset(center.dx + cos(angle) * innerR, center.dy + sin(angle) * innerR);
      final p2 = Offset(center.dx + cos(angle) * outerR, center.dy + sin(angle) * outerR);
      canvas.drawLine(p1, p2, tickPaint);
    }

    // Aktif devir oranı (Maks 7000 RPM)
    double progress = (rpm / 7000.0).clamp(0.0, 1.0);
    double activeSweep = sweepAngle * progress;

    Color activeColor;
    if (isShiftLight || rpm >= 5800) {
      activeColor = const Color(0xFFFF3B30);
    } else if (rpm >= 4500) {
      activeColor = const Color(0xFFFF9500);
    } else {
      activeColor = const Color(0xFF00E5FF);
    }

    final activePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    if (isShiftLight) {
      activePaint.maskFilter = const MaskFilter.blur(BlurStyle.solid, 8);
    }

    if (activeSweep > 0.01) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        activeSweep,
        false,
        activePaint,
      );
    }

    // Redline işaret yayı (5800 - 7000 RPM)
    final redlinePaint = Paint()
      ..color = Colors.redAccent.withOpacity(0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    double redlineStartAngle = startAngle + (sweepAngle * (5800 / 7000));
    double redlineSweepAngle = sweepAngle * ((7000 - 5800) / 7000);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius + 11),
      redlineStartAngle,
      redlineSweepAngle,
      false,
      redlinePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.rpm != rpm || oldDelegate.isShiftLight != isShiftLight;
  }
}
