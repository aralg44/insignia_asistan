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
    IconData icon;
    String text;
    Color accent;
    Color bgColor;

    if (isShiftLight) {
      icon = Icons.bolt;
      text = 'VİTES YÜKSELT  ➔  $recommendedGear. VİTES';
      accent = Colors.white;
      bgColor = const Color(0xFFD92626);
    } else {
      switch (advice) {
        case ShiftAdvice.shiftUp:
          icon = Icons.keyboard_double_arrow_up_rounded;
          text = 'VİTES BÜYÜT  ➔  $recommendedGear. VİTES';
          accent = const Color(0xFF34D399);
          bgColor = const Color(0xFF122B24);
          break;
        case ShiftAdvice.shiftDown:
          icon = Icons.keyboard_double_arrow_down_rounded;
          text = 'VİTES KÜÇÜLT  ➔  $recommendedGear. VİTES';
          accent = const Color(0xFFFBBF24);
          bgColor = const Color(0xFF2D2312);
          break;
        case ShiftAdvice.maintain:
          icon = Icons.check_circle_outline_rounded;
          text = 'OPTİMAL VİTES SEYRİ';
          accent = Colors.white70;
          bgColor = const Color(0xFF141821);
          break;
      }
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isShiftLight ? Colors.redAccent : accent.withOpacity(0.45),
          width: 1.4,
        ),
        boxShadow: isShiftLight
            ? [
                BoxShadow(
                  color: Colors.redAccent.withOpacity(0.55),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: accent, size: 22),
          const SizedBox(width: 8),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                text,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: accent,
                  letterSpacing: 1.1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
