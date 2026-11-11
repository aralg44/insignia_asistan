import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/car_specs.dart';
import '../models/telemetry_data.dart';
import '../services/gear_calculator_service.dart';
import '../services/mock_simulation_service.dart';
import '../services/obd_service.dart';

class AppStateProvider with ChangeNotifier {
  late CarSpecs _specs;
  late GearCalculatorService _calculator;
  final ObdService _obdService = ObdService();
  final MockSimulationService _simulationService = MockSimulationService();

  TelemetryData _telemetry = TelemetryData.initial();
  DrivingMode _drivingMode = DrivingMode.sport;
  bool _isSimulationMode = false;
  bool _isSoundEnabled = true;
  bool _isVibrationEnabled = true;
  ObdConnectionStatus _connectionStatus = ObdConnectionStatus.disconnected;

  StreamSubscription? _obdDataSub;
  StreamSubscription? _simDataSub;
  StreamSubscription? _obdStatusSub;

  AppStateProvider() {
    _specs = CarSpecs.insigniaM32Default();
    _calculator = GearCalculatorService(specs: _specs, drivingMode: _drivingMode);

    _obdStatusSub = _obdService.statusStream.listen((status) {
      _connectionStatus = status;
      notifyListeners();
    });

    _obdDataSub = _obdService.dataStream.listen(_onRawDataReceived);
    _simDataSub = _simulationService.dataStream.listen(_onRawDataReceived);
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

  void _onRawDataReceived(ObdRawData raw) {
    _telemetry = _calculator.calculateAdvice(
      rpm: raw.rpm,
      speedKmh: raw.speed,
      throttlePercent: raw.throttle,
      coolantTempCelsius: raw.coolant,
      engineLoadPercent: raw.load,
      manifoldPressureKpa: raw.map,
    );
    notifyListeners();
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
      _simulationService.start();
    } else {
      _simulationService.stop();
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
