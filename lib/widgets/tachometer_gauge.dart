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
    return SizedBox(
      width: 320,
      height: 320,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(320, 320),
            painter: _GaugePainter(
              rpm: rpm,
              isShiftLight: isShiftLight,
            ),
          ),
          // Kadran Merkezi Göstergeleri
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Anlık Vites Göstergesi
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                decoration: BoxDecoration(
                  color: isShiftLight ? Colors.redAccent.withOpacity(0.3) : Colors.black54,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isShiftLight ? Colors.red : Colors.cyanAccent.withOpacity(0.5),
                    width: 2,
                  ),
                ),
                child: Text(
                  currentGear,
                  style: TextStyle(
                    fontSize: 54,
                    fontWeight: FontWeight.w900,
                    color: isShiftLight ? Colors.redAccent : (currentGear == 'N' ? Colors.amber : Colors.white),
                    shadows: [
                      Shadow(
                        color: isShiftLight ? Colors.red : Colors.cyanAccent,
                        blurRadius: 16,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              // Hız Bilgisi
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    speedKmh.toStringAsFixed(0),
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'km/h',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white60,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              // Devir Bilgisi
              Text(
                '${rpm.toStringAsFixed(0)} RPM',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isShiftLight ? Colors.redAccent : Colors.cyanAccent,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ],
      ),
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
    final radius = size.width / 2 - 16;

    const startAngle = 135 * (pi / 180);
    const sweepAngle = 270 * (pi / 180);

    // Arka plan yayın çizimi
    final bgPaint = Paint()
      ..color = const Color(0xFF1E222D)
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

    // Aktif devir oranı (Maks 7000 RPM)
    double progress = (rpm / 7000.0).clamp(0.0, 1.0);
    double activeSweep = sweepAngle * progress;

    // Renk geçişi: Düşük devir cyan -> Orta devir turuncu -> Kırmızı bölge (Redline)
    Color activeColor;
    if (isShiftLight) {
      activeColor = Colors.redAccent;
    } else if (rpm >= 5800) {
      activeColor = const Color(0xFFFF3333); // Redline
    } else if (rpm >= 4500) {
      activeColor = const Color(0xFFFF9900); // Yüksek Devir
    } else {
      activeColor = const Color(0xFF00E5FF); // Normal Devir
    }

    final activePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;

    if (isShiftLight) {
      activePaint.maskFilter = const MaskFilter.blur(BlurStyle.solid, 10);
    }

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      activeSweep,
      false,
      activePaint,
    );

    // Redline işaret çizgisi (5800 - 7000 RPM)
    final redlinePaint = Paint()
      ..color = Colors.red.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    double redlineStartAngle = startAngle + (sweepAngle * (5800 / 7000));
    double redlineSweepAngle = sweepAngle * ((7000 - 5800) / 7000);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius + 10),
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
