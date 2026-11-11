import '../models/car_specs.dart';
import '../models/telemetry_data.dart';

class GearCalculatorService {
  final CarSpecs specs;
  DrivingMode drivingMode;

  GearCalculatorService({
    required this.specs,
    this.drivingMode = DrivingMode.sport,
  });

  /// Anlık RPM ve Hız (km/h) değerinden aktif vitesi tespit eder
  String detectCurrentGear(double rpm, double speedKmh) {
    // 5 km/h altı veya rölantide araç boşta kabul edilir
    if (speedKmh < 4.0 || rpm < 600.0) {
      return 'N';
    }

    double currentRatio = rpm / speedKmh;
    const double tolerance = 0.08; // %8 eşleşme toleransı (lastik aşınması ve debriyaj kayması payı)

    for (int gear = 1; gear <= specs.gearRatios.length; gear++) {
      double targetRatio = specs.getRpmPerSpeedRatio(gear);
      double minRatio = targetRatio * (1.0 - tolerance);
      double maxRatio = targetRatio * (1.0 + tolerance);

      if (currentRatio >= minRatio && currentRatio <= maxRatio) {
        return gear.toString();
      }
    }

    // Hiçbir vites oranıyla uyuşmuyorsa (Debriyaja basılı, vites değiştiriliyor ya da boşta)
    return 'N';
  }

  /// Sürüş moduna, devire ve gaza göre en uygun vites tavsiyesini oluşturur
  TelemetryData calculateAdvice({
    required double rpm,
    required double speedKmh,
    required double throttlePercent,
    required double coolantTempCelsius,
    required double engineLoadPercent,
    required double manifoldPressureKpa,
  }) {
    String currentGearStr = detectCurrentGear(rpm, speedKmh);
    int? currentGearInt = int.tryParse(currentGearStr);

    ShiftAdvice advice = ShiftAdvice.maintain;
    String recGear = currentGearStr;
    bool isShiftLight = false;

    if (currentGearInt != null && currentGearInt > 0) {
      int maxGear = specs.gearRatios.length;

      // 1. Vites Büyütme (Shift Up) Eşik Devirleri
      double shiftUpThresholdRpm;
      switch (drivingMode) {
        case DrivingMode.eco:
          // Ekonomi modu: Düşük gazda 2000 devir, gaz arttıkça maks 2400 devir
          shiftUpThresholdRpm = 2000.0 + (throttlePercent * 5.0);
          break;
        case DrivingMode.comfort:
          // Günlük konfor modu: 2500 - 3200 devir bandı
          shiftUpThresholdRpm = 2500.0 + (throttlePercent * 8.0);
          break;
        case DrivingMode.sport:
          // Opel Insignia 1.6T (A16LET / B16SHT) Peak Power Devri
          if (throttlePercent > 70.0) {
            shiftUpThresholdRpm = 5800.0;
          } else {
            shiftUpThresholdRpm = 4200.0 + (throttlePercent * 15.0);
          }
          break;
      }

      // 2. Vites Küçültme (Shift Down / Boğulma Önleme) Eşik Devri
      const double shiftDownThresholdRpm = 1350.0;

      // Vites büyütme kontrolü
      if (rpm >= shiftUpThresholdRpm && currentGearInt < maxGear) {
        advice = ShiftAdvice.shiftUp;
        recGear = (currentGearInt + 1).toString();

        // Spor modunda veya yüksek devirde Shift Light aktif
        if (rpm >= 5700.0 || (drivingMode == DrivingMode.sport && rpm >= 5500.0)) {
          isShiftLight = true;
        }
      }
      // Vites küçültme kontrolü
      else if (rpm < shiftDownThresholdRpm && currentGearInt > 1 && speedKmh > 10.0) {
        advice = ShiftAdvice.shiftDown;
        recGear = (currentGearInt - 1).toString();
      }
    } else {
      // Araç boşta veya dururken tavsiye: Hıza göre kalkış veya uygun vites
      if (speedKmh < 10.0) {
        recGear = '1';
      } else if (speedKmh < 25.0) {
        recGear = '2';
      } else if (speedKmh < 45.0) {
        recGear = '3';
      } else if (speedKmh < 70.0) {
        recGear = '4';
      } else if (speedKmh < 100.0) {
        recGear = '5';
      } else {
        recGear = '6';
      }
    }

    return TelemetryData(
      rpm: rpm,
      speedKmh: speedKmh,
      throttlePercent: throttlePercent,
      coolantTempCelsius: coolantTempCelsius,
      engineLoadPercent: engineLoadPercent,
      manifoldPressureKpa: manifoldPressureKpa,
      currentGear: currentGearStr,
      recommendedGear: recGear,
      shiftAdvice: advice,
      isShiftLightActive: isShiftLight,
    );
  }
}
