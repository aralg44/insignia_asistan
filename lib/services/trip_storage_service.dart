import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/fuel_settings.dart';
import '../models/trip_record.dart';

/// Yakıt ayarlarını, sürüş geçmişini ve aktif sürüş taslağını cihazda saklar.
///
/// Anahtarlar eski tek dosyalık sürümle aynıdır; daha önce kaydedilmiş
/// veriler okunmaya devam eder.
class TripStorageService {
  static const _kHistory = 'gecmis_surusler_v1';
  static const _kDraft = 'aktif_surus_taslak_v1';
  static const _kLpgPrice = 'lpg_fiyat';
  static const _kGasolinePrice = 'benzin_fiyat';
  static const _kLpgMode = 'lpg_modu';
  static const _kCity = 'secili_sehir';
  static const _kPriceStatus = 'son_guncelleme';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  // ---- Yakıt ayarları ----

  Future<FuelSettings> loadFuelSettings() async {
    final p = await _prefs;
    final d = FuelSettings.defaults();
    final city = p.getString(_kCity);
    return FuelSettings(
      lpgMode: p.getBool(_kLpgMode) ?? d.lpgMode,
      lpgPrice: p.getDouble(_kLpgPrice) ?? d.lpgPrice,
      gasolinePrice: p.getDouble(_kGasolinePrice) ?? d.gasolinePrice,
      city: FuelSettings.cities.contains(city) ? city! : d.city,
      priceStatus: p.getString(_kPriceStatus) ?? d.priceStatus,
    );
  }

  Future<void> saveFuelSettings(FuelSettings s) async {
    final p = await _prefs;
    await p.setBool(_kLpgMode, s.lpgMode);
    await p.setDouble(_kLpgPrice, s.lpgPrice);
    await p.setDouble(_kGasolinePrice, s.gasolinePrice);
    await p.setString(_kCity, s.city);
    await p.setString(_kPriceStatus, s.priceStatus);
  }

  // ---- Sürüş geçmişi ----

  Future<List<TripRecord>> loadHistory() async {
    final p = await _prefs;
    final out = <TripRecord>[];
    for (final raw in p.getStringList(_kHistory) ?? const <String>[]) {
      try {
        out.add(TripRecord.fromJson(jsonDecode(raw) as Map<String, dynamic>));
      } catch (_) {
        // Bozuk kayıt atlanır.
      }
    }
    return out;
  }

  Future<void> saveHistory(List<TripRecord> trips) async {
    final p = await _prefs;
    await p.setStringList(
        _kHistory, trips.map((t) => jsonEncode(t.toJson())).toList());
  }

  // ---- Aktif sürüş taslağı (uygulama aniden kapanırsa kurtarmak için) ----

  Future<void> saveDraft(TripRecord draft) async {
    final p = await _prefs;
    await p.setString(_kDraft, jsonEncode(draft.toJson()));
  }

  Future<TripRecord?> takeDraft() async {
    final p = await _prefs;
    final raw = p.getString(_kDraft);
    if (raw == null || raw.isEmpty) return null;
    await p.remove(_kDraft);
    try {
      return TripRecord.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearDraft() async {
    final p = await _prefs;
    await p.remove(_kDraft);
  }
}
