import 'package:flutter/material.dart';
import '../models/telemetry_data.dart';

class ShiftIndicatorBanner extends StatelessWidget {
  final ShiftAdvice advice;
  final String recommendedGear;
  final bool isShiftLight;

  const ShiftIndicatorBanner({
    super.key,
    required this.advice,
    required this.recommendedGear,
    required this.isShiftLight,
  });

  @override
  Widget build(BuildContext context) {
    if (isShiftLight) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.8),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.flash_on, color: Colors.white, size: 32),
            const SizedBox(width: 8),
            Text(
              'SHIFT! VİTES AT ➔ $recommendedGear',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      );
    }

    switch (advice) {
      case ShiftAdvice.shiftUp:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1B382B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.greenAccent, width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.arrow_upward, color: Colors.greenAccent, size: 28),
              const SizedBox(width: 8),
              Text(
                'VİTES BÜYÜT ➔ $recommendedGear',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.greenAccent,
                ),
              ),
            ],
          ),
        );

      case ShiftAdvice.shiftDown:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF382E1B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.orangeAccent, width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.arrow_downward, color: Colors.orangeAccent, size: 28),
              const SizedBox(width: 8),
              Text(
                'VİTES KÜÇÜLT ➔ $recommendedGear',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.orangeAccent,
                ),
              ),
            ],
          ),
        );

      case ShiftAdvice.maintain:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF161A22),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white12),
          ),
          child: const Center(
            child: Text(
              'OPTİMAL VİTES',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white54,
                letterSpacing: 2,
              ),
            ),
          ),
        );
    }
  }
}
