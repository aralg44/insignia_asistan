/// Yakıt türü, birim fiyatlar ve fiyat çekilecek şehir ayarları.
class FuelSettings {
  static const double defaultLpgPrice = 40.50;
  static const double defaultGasolinePrice = 77.00;
  static const String defaultCity = 'SAKARYA';

  static const List<String> cities = [
    'SAKARYA',
    'ISTANBUL',
    'KOCAELI',
    'ANKARA',
    'IZMIR',
    'BURSA',
    'DUZCE',
    'BOLU',
    'ESKISEHIR',
    'ANTALYA',
  ];

  /// LPG'li araç mı? (Motor soğukken araç yine benzinle çalışır.)
  final bool lpgMode;
  final double lpgPrice;
  final double gasolinePrice;
  final String city;

  /// Kullanıcıya gösterilen fiyat kaynağı / güncelleme durumu.
  final String priceStatus;

  const FuelSettings({
    required this.lpgMode,
    required this.lpgPrice,
    required this.gasolinePrice,
    required this.city,
    required this.priceStatus,
  });

  factory FuelSettings.defaults() => const FuelSettings(
        lpgMode: true,
        lpgPrice: defaultLpgPrice,
        gasolinePrice: defaultGasolinePrice,
        city: defaultCity,
        priceStatus: 'Varsayılan fiyat',
      );

  String get fuelLabel => lpgMode ? 'LPG' : 'BENZİN';

  FuelSettings copyWith({
    bool? lpgMode,
    double? lpgPrice,
    double? gasolinePrice,
    String? city,
    String? priceStatus,
  }) {
    return FuelSettings(
      lpgMode: lpgMode ?? this.lpgMode,
      lpgPrice: lpgPrice ?? this.lpgPrice,
      gasolinePrice: gasolinePrice ?? this.gasolinePrice,
      city: city ?? this.city,
      priceStatus: priceStatus ?? this.priceStatus,
    );
  }
}
