import 'package:http/http.dart' as http;

class FetchedFuelPrices {
  final double gasoline;
  final double lpg;
  final String source; // "PO" veya "doviz.com"

  const FetchedFuelPrices({
    required this.gasoline,
    required this.lpg,
    required this.source,
  });
}

/// İl bazlı güncel benzin ve LPG pompa fiyatlarını internetten çeker.
///
/// 1. kaynak Petrol Ofisi, ulaşılamazsa doviz.com yedek olarak denenir.
class FuelPriceService {
  static const _headers = {
    'User-Agent':
        'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 Chrome/124.0.0.0 Mobile',
  };
  static const _timeout = Duration(seconds: 8);

  final http.Client _client;

  FuelPriceService({http.Client? client}) : _client = client ?? http.Client();

  /// Fiyatlar alınamazsa `null` döner.
  Future<FetchedFuelPrices?> fetch(String city) async {
    final slug = city.toLowerCase();

    // 1. Kaynak: Petrol Ofisi il bazlı akaryakıt fiyatları
    try {
      final res = await _client
          .get(
            Uri.parse(
                'https://www.petrolofisi.com.tr/akaryakit-fiyatlari/$slug-akaryakit-fiyatlari'),
            headers: _headers,
          )
          .timeout(_timeout);
      if (res.statusCode == 200) {
        final parsed = parsePetrolOfisi(res.body);
        if (parsed != null) return parsed;
      }
    } catch (_) {}

    // 2. Yedek kaynak: doviz.com il bazlı akaryakıt fiyatları
    try {
      final res = await _client
          .get(
            Uri.parse('https://www.doviz.com/akaryakit-fiyatlari/$slug'),
            headers: _headers,
          )
          .timeout(_timeout);
      if (res.statusCode == 200) {
        final parsed = parseFallback(res.body);
        if (parsed != null) return parsed;
      }
    } catch (_) {}

    return null;
  }

  /// Petrol Ofisi tablosunun ilk ilçe satırından vergili fiyatları okur.
  /// Sütun sırası: Kurşunsuz 95, Diesel, ..., PO/gaz Otogaz (son sütun).
  static FetchedFuelPrices? parsePetrolOfisi(String html) {
    final row = RegExp(r'<tr\s+class="price-row[^>]*>(.*?)</tr>', dotAll: true)
        .firstMatch(html);
    if (row == null) return null;
    final prices = RegExp(r'<span\s+class="with-tax">\s*([\d.,]+)\s*</span>')
        .allMatches(row.group(1)!)
        .map((m) => double.tryParse(m.group(1)!.replaceAll(',', '.')))
        .whereType<double>()
        .where((v) => v > 5.0)
        .toList();
    if (prices.length < 2) return null;
    return FetchedFuelPrices(
        gasoline: prices.first, lpg: prices.last, source: 'PO');
  }

  /// Sayfadaki fiyat benzeri sayıları makul aralıklara göre ayırır.
  static FetchedFuelPrices? parseFallback(String html) {
    final gasoline = <double>[];
    final lpg = <double>[];
    for (final m in RegExp(r'(\d{2,3}[.,]\d{2})').allMatches(html)) {
      final v = double.tryParse(m.group(1)!.replaceAll(',', '.'));
      if (v == null) continue;
      if (v >= 60.0 && v <= 110.0) {
        gasoline.add(v);
      } else if (v >= 30.0 && v <= 59.9) {
        lpg.add(v);
      }
    }
    if (gasoline.isEmpty || lpg.isEmpty) return null;
    return FetchedFuelPrices(
        gasoline: gasoline.first, lpg: lpg.first, source: 'doviz.com');
  }
}
