import '../models/fuel_settings.dart';
import '../models/trip_record.dart';
import '../utils/formatters.dart';

/// Canlı OBD verisinden anlık tüketim / maliyet hesaplar ve aktif sürüşün
/// mesafe, yakıt, tutar ve maksimum değerlerini biriktirir.
///
/// Hesap modeli (A16LET):
/// - Yakıt kesme (decel cut-off) algılanınca tüketim 0 kabul edilir.
/// - MAF yoksa RPM × MAP üzerinden tahmini hava debisi kullanılır.
/// - Boost > 0.35 bar, yük > %70 veya > 4500 d/d iken zengin karışım (AFR 11.8).
/// - LPG modunda motor ısısı 40°C altındayken araç benzinle çalışır;
///   LPG'de hacimsel tüketim benzine göre ~%18 fazladır.
class TripTracker {
  static const double _stoichAfr = 14.7;
  static const double _richAfr = 11.8;
  static const double _gasolineDensityGPerL = 745.0;
  static const double _lpgVolumeFactor = 1.18;
  static const double _lpgMinCoolantC = 40.0;

  // Aktif sürüş birikimleri
  double distanceKm = 0.0;
  double fuelLiters = 0.0;
  double costTl = 0.0;
  double activeSeconds = 0.0;
  int maxSpeed = 0;
  int maxRpm = 0;
  double maxBoostBar = 0.0;
  DateTime startedAt = DateTime.now();

  // Anlık değerler
  double litersPerHour = 0.0;
  double litersPer100Km = 0.0;
  double tlPerKm = 0.0;
  bool isFuelCutOff = false;
  bool isRichMixture = false;
  bool isRunningOnLpg = false;

  DateTime? _lastUpdate;

  bool get hasData => distanceKm >= 0.02 || fuelLiters >= 0.01;

  /// Bağlantı koptuğunda çağrılır; yeniden bağlanınca aradaki süre
  /// sürüşe eklenmez.
  void pauseClock() => _lastUpdate = null;

  void update({
    required double rpm,
    required double speedKmh,
    required double loadPercent,
    required double mapKpa,
    required double coolantC,
    required double mafGramsPerSec,
    required bool gearEngaged,
    required FuelSettings fuel,
    DateTime? now,
  }) {
    final t = now ?? DateTime.now();
    final last = _lastUpdate;
    _lastUpdate = t;
    final dtSeconds = last == null ? 0.0 : t.difference(last).inMilliseconds / 1000.0;
    // 36 sn'den uzun boşluklar (bağlantı takılması vb.) birikime eklenmez.
    final validDt = dtSeconds > 0 && dtSeconds < 36.0;
    final dtHours = dtSeconds / 3600.0;

    final boostBar = (mapKpa - 100.0) / 100.0;

    if (speedKmh.round() > maxSpeed) maxSpeed = speedKmh.round();
    if (rpm.round() > maxRpm) maxRpm = rpm.round();
    if (boostBar > maxBoostBar) maxBoostBar = boostBar;

    if (validDt && (rpm > 400 || speedKmh > 0)) activeSeconds += dtSeconds;
    if (validDt) distanceKm += speedKmh * dtHours;

    isRunningOnLpg = fuel.lpgMode && coolantC >= _lpgMinCoolantC;
    final unitPrice = isRunningOnLpg ? fuel.lpgPrice : fuel.gasolinePrice;

    // Yakıt kesme: vitesteyken gaz bırakılmış motor freni
    if (speedKmh > 15 && gearEngaged && rpm > 1400 && loadPercent < 18 && mapKpa < 38) {
      isFuelCutOff = true;
      isRichMixture = false;
      litersPerHour = 0.0;
      litersPer100Km = 0.0;
      tlPerKm = 0.0;
      return;
    }
    isFuelCutOff = false;

    var maf = mafGramsPerSec;
    if (maf <= 0.1 && rpm > 500) maf = rpm * mapKpa * 0.00095;

    isRichMixture = boostBar > 0.35 || loadPercent > 70 || rpm > 4500;
    final afr = isRichMixture ? _richAfr : _stoichAfr;

    final gasolineLph = (maf * 3600.0) / (afr * _gasolineDensityGPerL);
    litersPerHour = gasolineLph * (isRunningOnLpg ? _lpgVolumeFactor : 1.0);

    if (speedKmh >= 5) {
      litersPer100Km = (litersPerHour / speedKmh) * 100.0;
      tlPerKm = (litersPer100Km / 100.0) * unitPrice;
    } else {
      // Dururken km başı anlamsız; saatlik TL gösterilir.
      litersPer100Km = 0.0;
      tlPerKm = litersPerHour * unitPrice;
    }

    if (validDt) {
      final liters = litersPerHour * dtHours;
      fuelLiters += liters;
      costTl += liters * unitPrice;
    }
  }

  TripRecord toRecord({required String id, required FuelSettings fuel}) {
    return TripRecord(
      id: id,
      dateStr: formatDateTime(startedAt),
      distanceKm: distanceKm,
      fuelLiters: fuelLiters,
      totalCostTl: costTl,
      fuelType: fuel.fuelLabel,
      unitPriceTl: fuel.lpgMode ? fuel.lpgPrice : fuel.gasolinePrice,
      durationSeconds: activeSeconds.round(),
      maxSpeed: maxSpeed,
      maxRpm: maxRpm,
      maxBoostBar: maxBoostBar,
    );
  }

  void reset() {
    distanceKm = 0.0;
    fuelLiters = 0.0;
    costTl = 0.0;
    activeSeconds = 0.0;
    maxSpeed = 0;
    maxRpm = 0;
    maxBoostBar = 0.0;
    litersPerHour = 0.0;
    litersPer100Km = 0.0;
    tlPerKm = 0.0;
    isFuelCutOff = false;
    isRichMixture = false;
    startedAt = DateTime.now();
    _lastUpdate = null;
  }
}
