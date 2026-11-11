import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/car_specs.dart';
import '../models/fuel_settings.dart';
import '../models/telemetry_data.dart';
import '../models/trip_record.dart';
import '../services/fuel_price_service.dart';
import '../services/gear_calculator_service.dart';
import '../services/mock_simulation_service.dart';
import '../services/obd_service.dart';
import '../services/trip_storage_service.dart';
import '../services/trip_tracker.dart';
import '../utils/formatters.dart';

class AppStateProvider with ChangeNotifier {
  late CarSpecs _specs;
  late GearCalculatorService _calculator;
  final ObdService _obdService = ObdService();
  final MockSimulationService _simulationService = MockSimulationService();
  final TripStorageService _storage = TripStorageService();
  final FuelPriceService _priceService = FuelPriceService();
  final TripTracker _tripTracker = TripTracker();

  TelemetryData _telemetry = TelemetryData.initial();
  DrivingMode _drivingMode = DrivingMode.sport;
  bool _isSimulationMode = false;
  bool _isSoundEnabled = true;
  bool _isVibrationEnabled = true;
  ObdConnectionStatus _connectionStatus = ObdConnectionStatus.disconnected;

  FuelSettings _fuelSettings = FuelSettings.defaults();
  bool _isFetchingFuelPrices = false;
  List<TripRecord> _tripHistory = [];
  DateTime _lastDraftSaveTime = DateTime.now();

  StreamSubscription? _obdDataSub;
  StreamSubscription? _simDataSub;
  StreamSubscription? _obdStatusSub;

  AppStateProvider() {
    _specs = CarSpecs.insigniaM32Default();
    _calculator = GearCalculatorService(specs: _specs, drivingMode: _drivingMode);

    _obdStatusSub = _obdService.statusStream.listen((status) async {
      final prevStatus = _connectionStatus;
      _connectionStatus = status;

      // Kontak kapandığında veya OBD bağlantısı koptuğunda aktif sürüşü otomatik kaydet
      if (prevStatus == ObdConnectionStatus.connected &&
          status == ObdConnectionStatus.disconnected) {
        _tripTracker.pauseClock();
        await finalizeCurrentTrip();
      } else if (status == ObdConnectionStatus.connected) {
        if (!_tripTracker.hasData) {
          _tripTracker.startedAt = DateTime.now();
        }
      }
      notifyListeners();
    });

    _obdDataSub = _obdService.dataStream.listen(_onRawDataReceived);
    _simDataSub = _simulationService.dataStream.listen(_onRawDataReceived);

    _initPersistence();
  }

  // Getters
  TelemetryData get telemetry => _telemetry;
  DrivingMode get drivingMode => _drivingMode;
  CarSpecs get specs => _specs;
  bool get isSimulationMode => _isSimulationMode;
  bool get isSoundEnabled => _isSoundEnabled;
  bool get isVibrationEnabled => _isVibrationEnabled;
  ObdConnectionStatus get connectionStatus => _connectionStatus;
  ObdService get obdService => _obdService;

  FuelSettings get fuelSettings => _fuelSettings;
  bool get isFetchingFuelPrices => _isFetchingFuelPrices;
  TripTracker get tripTracker => _tripTracker;
  List<TripRecord> get tripHistory => List.unmodifiable(_tripHistory);
  LifetimeTotals get lifetimeTotals => LifetimeTotals.from(_tripHistory);

  Future<void> _initPersistence() async {
    _fuelSettings = await _storage.loadFuelSettings();
    _tripHistory = await _storage.loadHistory();

    // Uygulama aniden kapandıysa yarım kalan taslak sürüşü kurtar
    final draft = await _storage.takeDraft();
    if (draft != null && (draft.distanceKm >= 0.05 || draft.fuelLiters >= 0.02)) {
      _tripHistory.insert(0, draft);
      await _storage.saveHistory(_tripHistory);
    }
    notifyListeners();

    await fetchLiveFuelPrices(_fuelSettings.city);
  }

  void _onRawDataReceived(ObdRawData raw) {
    _telemetry = _calculator.calculateAdvice(
      rpm: raw.rpm,
      speedKmh: raw.speed,
      throttlePercent: raw.throttle,
      coolantTempCelsius: raw.coolant,
      engineLoadPercent: raw.load,
      manifoldPressureKpa: raw.map,
    );

    final gearEngaged =
        _telemetry.currentGear != 'N' && _telemetry.currentGear != '0';

    _tripTracker.update(
      rpm: raw.rpm,
      speedKmh: raw.speed,
      loadPercent: raw.load,
      mapKpa: raw.map,
      coolantC: raw.coolant,
      mafGramsPerSec: raw.maf,
      gearEngaged: gearEngaged,
      fuel: _fuelSettings,
    );

    // Her 15 saniyede bir aktif sürüş taslağını yedekle
    final now = DateTime.now();
    if (now.difference(_lastDraftSaveTime).inSeconds >= 15 &&
        (_tripTracker.distanceKm >= 0.05 || _tripTracker.fuelLiters >= 0.02)) {
      _lastDraftSaveTime = now;
      final draft = _tripTracker.toRecord(
        id: 'draft_${_tripTracker.startedAt.millisecondsSinceEpoch}',
        fuel: _fuelSettings,
      );
      _storage.saveDraft(draft);
    }

    notifyListeners();
  }

  /// Aktif sürüşü geçmişe kaydeder ve sıfırlar.
  Future<TripRecord?> finalizeCurrentTrip() async {
    if (!_tripTracker.hasData) return null;

    final record = _tripTracker.toRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      fuel: _fuelSettings,
    );
    _tripHistory.insert(0, record);
    _tripTracker.reset();
    await _storage.saveHistory(_tripHistory);
    await _storage.clearDraft();
    notifyListeners();
    return record;
  }

  /// Aktif sürüşü kaydetmeden sıfırlar.
  Future<void> resetCurrentTrip() async {
    _tripTracker.reset();
    await _storage.clearDraft();
    notifyListeners();
  }

  Future<void> deleteTripAt(int index) async {
    if (index < 0 || index >= _tripHistory.length) return;
    _tripHistory.removeAt(index);
    await _storage.saveHistory(_tripHistory);
    notifyListeners();
  }

  Future<void> clearAllTrips() async {
    _tripHistory.clear();
    await _storage.saveHistory(_tripHistory);
    notifyListeners();
  }

  Future<void> updateFuelSettings({
    required bool lpgMode,
    required double lpgPrice,
    required double gasolinePrice,
    required String city,
    String status = 'Manuel Ayar',
  }) async {
    _fuelSettings = _fuelSettings.copyWith(
      lpgMode: lpgMode,
      lpgPrice: lpgPrice,
      gasolinePrice: gasolinePrice,
      city: city,
      priceStatus: status,
    );
    await _storage.saveFuelSettings(_fuelSettings);
    notifyListeners();
  }

  Future<bool> fetchLiveFuelPrices(String city) async {
    _isFetchingFuelPrices = true;
    _fuelSettings = _fuelSettings.copyWith(
      city: city,
      priceStatus: 'İnternetten çekiliyor...',
    );
    notifyListeners();

    final fetched = await _priceService.fetch(city);
    _isFetchingFuelPrices = false;

    if (fetched != null) {
      final clock = formatClock(DateTime.now());
      final label = fetched.source == 'PO'
          ? 'Canlı PO ($city $clock)'
          : 'Canlı ($city $clock)';
      _fuelSettings = _fuelSettings.copyWith(
        lpgPrice: fetched.lpg,
        gasolinePrice: fetched.gasoline,
        city: city,
        priceStatus: label,
      );
      await _storage.saveFuelSettings(_fuelSettings);
      notifyListeners();
      return true;
    } else {
      _fuelSettings = _fuelSettings.copyWith(
        city: city,
        priceStatus: 'Çevrimdışı (Kayıtlı)',
      );
      notifyListeners();
      return false;
    }
  }

  void setDrivingMode(DrivingMode mode) {
    _drivingMode = mode;
    _calculator.drivingMode = mode;
    notifyListeners();
  }

  void setCarSpecs(CarSpecs specs) {
    _specs = specs;
    _calculator = GearCalculatorService(specs: _specs, drivingMode: _drivingMode);
    notifyListeners();
  }

  void toggleSimulationMode() {
    _isSimulationMode = !_isSimulationMode;
    if (_isSimulationMode) {
      _obdService.disconnect();
      if (!_tripTracker.hasData) {
        _tripTracker.startedAt = DateTime.now();
      }
      _simulationService.start();
    } else {
      _simulationService.stop();
      _tripTracker.pauseClock();
      _telemetry = TelemetryData.initial();
    }
    notifyListeners();
  }

  void toggleSound() {
    _isSoundEnabled = !_isSoundEnabled;
    notifyListeners();
  }

  void toggleVibration() {
    _isVibrationEnabled = !_isVibrationEnabled;
    notifyListeners();
  }

  Future<bool> connectToObd(String address) async {
    if (_isSimulationMode) {
      _simulationService.stop();
      _isSimulationMode = false;
    }
    return await _obdService.connect(address);
  }

  void disconnectObd() {
    _obdService.disconnect();
  }

  @override
  void dispose() {
    _obdDataSub?.cancel();
    _simDataSub?.cancel();
    _obdStatusSub?.cancel();
    _obdService.dispose();
    _simulationService.dispose();
    super.dispose();
  }
}
