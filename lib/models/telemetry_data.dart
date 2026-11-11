enum ShiftAdvice {
  maintain, // Vites uygun, değiştirme
  shiftUp,  // Vites büyüt
  shiftDown // Vites küçült
}

class TelemetryData {
  final double rpm;                // Motor Devri (d/d)
  final double speedKmh;           // Araç Hızı (km/h)
  final double throttlePercent;     // Gaz Kelebeği Açıklığı (%)
  final double coolantTempCelsius; // Soğutma Suyu Sıcaklığı (°C)
  final double engineLoadPercent;   // Motor Yükü (%)
  final double manifoldPressureKpa;// Emme Manifold Basıncı (kPa)

  // Vites Asistanı Hesaplama Çıktıları
  final String currentGear;        // "1", "2", "3", "4", "5", "6", "N" (Boşta/Debriyaj)
  final String recommendedGear;    // Tavsiye edilen vites
  final ShiftAdvice shiftAdvice;   // shiftUp, shiftDown, maintain
  final bool isShiftLightActive;   // Kırmızı vites at uyarısı (Shift Light)

  const TelemetryData({
    required this.rpm,
    required this.speedKmh,
    required this.throttlePercent,
    required this.coolantTempCelsius,
    required this.engineLoadPercent,
    required this.manifoldPressureKpa,
    required this.currentGear,
    required this.recommendedGear,
    required this.shiftAdvice,
    required this.isShiftLightActive,
  });

  factory TelemetryData.initial() {
    return const TelemetryData(
      rpm: 800.0,
      speedKmh: 0.0,
      throttlePercent: 0.0,
      coolantTempCelsius: 90.0,
      engineLoadPercent: 15.0,
      manifoldPressureKpa: 101.0,
      currentGear: 'N',
      recommendedGear: '1',
      shiftAdvice: ShiftAdvice.maintain,
      isShiftLightActive: false,
    );
  }

  TelemetryData copyWith({
    double? rpm,
    double? speedKmh,
    double? throttlePercent,
    double? coolantTempCelsius,
    double? engineLoadPercent,
    double? manifoldPressureKpa,
    String? currentGear,
    String? recommendedGear,
    ShiftAdvice? shiftAdvice,
    bool? isShiftLightActive,
  }) {
    return TelemetryData(
      rpm: rpm ?? this.rpm,
      speedKmh: speedKmh ?? this.speedKmh,
      throttlePercent: throttlePercent ?? this.throttlePercent,
      coolantTempCelsius: coolantTempCelsius ?? this.coolantTempCelsius,
      engineLoadPercent: engineLoadPercent ?? this.engineLoadPercent,
      manifoldPressureKpa: manifoldPressureKpa ?? this.manifoldPressureKpa,
      currentGear: currentGear ?? this.currentGear,
      recommendedGear: recommendedGear ?? this.recommendedGear,
      shiftAdvice: shiftAdvice ?? this.shiftAdvice,
      isShiftLightActive: isShiftLightActive ?? this.isShiftLightActive,
    );
  }
}
