import 'dart:math';

/// Opel Insignia Şanzıman Modelleri ve Dişli Oranları
enum GearboxType {
  m32Manual6, // Opel Insignia 1.4T & 1.6T 6 İleri Manuel
  f40Manual6, // Opel Insignia 2.0 CDTI 6 İleri Manuel
  automatic6, // Aisin AF40 6 İleri Otomatik
}

enum DrivingMode {
  eco,     // Düşük devirde yakıt ekonomisi vites tavsiyesi
  comfort, // Dengeli günlük kullanım
  sport,   // Yüksek devir / Maksimum tork ve beygir bandı (Shift Light)
}

class CarSpecs {
  final GearboxType gearboxType;
  final String tireSize; // Örn: "245/45R18"
  final double tireCircumferenceMeters; // Lastik yuvarlanma çevresi (metre)
  final double finalDriveRatio;
  final List<double> gearRatios; // 1., 2., 3., 4., 5., 6. vites oranları

  CarSpecs({
    required this.gearboxType,
    required this.tireSize,
    required this.tireCircumferenceMeters,
    required this.finalDriveRatio,
    required this.gearRatios,
  });

  /// Opel Insignia M32 Manuel 6 İleri Varsayılan Konfigürasyonu (1.4T / 1.6T)
  factory CarSpecs.insigniaM32Default() {
    return CarSpecs(
      gearboxType: GearboxType.m32Manual6,
      tireSize: '245/45R18',
      tireCircumferenceMeters: calculateTireCircumference(245, 45, 18),
      finalDriveRatio: 4.176,
      gearRatios: [
        3.818, // 1. Vites
        2.158, // 2. Vites
        1.475, // 3. Vites
        1.067, // 4. Vites
        0.875, // 5. Vites
        0.744, // 6. Vites
      ],
    );
  }

  /// Opel Insignia F40 Manuel 6 İleri (2.0 CDTI Dizel)
  factory CarSpecs.insigniaF40Diesel() {
    return CarSpecs(
      gearboxType: GearboxType.f40Manual6,
      tireSize: '225/55R17',
      tireCircumferenceMeters: calculateTireCircumference(225, 55, 17),
      finalDriveRatio: 3.895,
      gearRatios: [
        3.917, // 1. Vites
        2.040, // 2. Vites
        1.321, // 3. Vites
        0.954, // 4. Vites
        0.755, // 5. Vites
        0.623, // 6. Vites
      ],
    );
  }

  /// Lastik yuvarlanma çevresi hesaplayıcı (Genişlik / Yanak / Jant)
  static double calculateTireCircumference(int widthMm, int profilePercent, int rimInches) {
    double sidewallMm = widthMm * (profilePercent / 100.0);
    double rimMm = rimInches * 25.4;
    double diameterMm = (sidewallMm * 2) + rimMm;
    double circumferenceMeters = (diameterMm * pi) / 1000.0;
    return circumferenceMeters;
  }

  /// Belirli bir vites için teorik RPM / Hız (km/h) oranını hesaplar
  double getRpmPerSpeedRatio(int gearIndex) {
    if (gearIndex < 1 || gearIndex > gearRatios.length) return 0.0;
    double gearRatio = gearRatios[gearIndex - 1];
    double totalRatio = gearRatio * finalDriveRatio;
    
    // Hız (km/h) = (RPM * Çevre * 60) / (Toplam_Oran * 1000)
    // RPM / Hız = (Toplam_Oran * 1000) / (Çevre * 60)
    return (totalRatio * 1000.0) / (tireCircumferenceMeters * 60.0);
  }
}
