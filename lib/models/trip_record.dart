/// Tamamlanmış (veya taslak olarak kurtarılmış) tek bir sürüşün özeti.
class TripRecord {
  final String id;
  final String dateStr;
  final double distanceKm;
  final double fuelLiters;
  final double totalCostTl;
  final String fuelType; // "LPG" veya "BENZİN"
  final double unitPriceTl;
  final int durationSeconds;
  final int maxSpeed;
  final int maxRpm;
  final double maxBoostBar;

  const TripRecord({
    required this.id,
    required this.dateStr,
    required this.distanceKm,
    required this.fuelLiters,
    required this.totalCostTl,
    required this.fuelType,
    required this.unitPriceTl,
    required this.durationSeconds,
    required this.maxSpeed,
    required this.maxRpm,
    required this.maxBoostBar,
  });

  double get avgLitersPer100Km =>
      distanceKm >= 0.05 ? (fuelLiters / distanceKm) * 100.0 : 0.0;

  double get avgTlPerKm => distanceKm >= 0.05 ? totalCostTl / distanceKm : 0.0;

  Map<String, dynamic> toJson() => {
        'id': id,
        'dateStr': dateStr,
        'distanceKm': distanceKm,
        'fuelLiters': fuelLiters,
        'totalCostTl': totalCostTl,
        'fuelType': fuelType,
        'unitPriceTl': unitPriceTl,
        'durationSeconds': durationSeconds,
        'maxSpeed': maxSpeed,
        'maxRpm': maxRpm,
        'maxBoostBar': maxBoostBar,
      };

  factory TripRecord.fromJson(Map<String, dynamic> json) => TripRecord(
        id: (json['id'] ?? DateTime.now().millisecondsSinceEpoch).toString(),
        dateStr: (json['dateStr'] ?? '').toString(),
        distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0.0,
        fuelLiters: (json['fuelLiters'] as num?)?.toDouble() ?? 0.0,
        totalCostTl: (json['totalCostTl'] as num?)?.toDouble() ?? 0.0,
        fuelType: (json['fuelType'] ?? 'LPG').toString(),
        unitPriceTl: (json['unitPriceTl'] as num?)?.toDouble() ?? 0.0,
        durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 0,
        maxSpeed: (json['maxSpeed'] as num?)?.toInt() ?? 0,
        maxRpm: (json['maxRpm'] as num?)?.toInt() ?? 0,
        maxBoostBar: (json['maxBoostBar'] as num?)?.toDouble() ?? 0.0,
      );
}

/// Tüm kayıtlı sürüşlerin toplamı.
class LifetimeTotals {
  final int tripCount;
  final double distanceKm;
  final double fuelLiters;
  final double costTl;
  final int durationSeconds;

  const LifetimeTotals({
    required this.tripCount,
    required this.distanceKm,
    required this.fuelLiters,
    required this.costTl,
    required this.durationSeconds,
  });

  factory LifetimeTotals.from(List<TripRecord> trips) {
    double km = 0, liters = 0, tl = 0;
    int seconds = 0;
    for (final t in trips) {
      km += t.distanceKm;
      liters += t.fuelLiters;
      tl += t.totalCostTl;
      seconds += t.durationSeconds;
    }
    return LifetimeTotals(
      tripCount: trips.length,
      distanceKm: km,
      fuelLiters: liters,
      costTl: tl,
      durationSeconds: seconds,
    );
  }

  double get avgLitersPer100Km =>
      distanceKm >= 0.05 ? (fuelLiters / distanceKm) * 100.0 : 0.0;

  double get avgTlPerKm => distanceKm >= 0.05 ? costTl / distanceKm : 0.0;
}
