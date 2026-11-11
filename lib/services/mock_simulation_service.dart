import 'dart:async';
import 'obd_service.dart';

/// Araca bağlı olmadan evde veya geliştirme aşamasında test için Canlı Sürüş Simülatörü
class MockSimulationService {
  Timer? _timer;
  final StreamController<ObdRawData> _dataController =
      StreamController<ObdRawData>.broadcast();

  Stream<ObdRawData> get dataStream => _dataController.stream;

  bool _isRunning = false;
  int _currentGear = 1;
  double _rpm = 900.0;
  double _speed = 0.0;
  double _throttle = 85.0; // Spor sürüş modu için yüksek gaz
  double _coolant = 92.0;
  bool _isShifting = false;

  void start() {
    if (_isRunning) return;
    _isRunning = true;
    _currentGear = 1;
    _rpm = 1200.0;
    _speed = 5.0;
    _throttle = 90.0;

    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      _tick();
    });
  }

  void stop() {
    _isRunning = false;
    _timer?.cancel();
    _timer = null;
  }

  void _tick() {
    if (_isShifting) {
      // Debriyaj basılı, devir düşüyor
      _rpm -= 150.0;
      if (_rpm <= 3200.0) {
        _isShifting = false;
        _currentGear++;
        if (_currentGear > 6) {
          _currentGear = 1;
          _speed = 5.0;
          _rpm = 1200.0;
        }
      }
    } else {
      // Gazlanıyor
      _rpm += 45.0;
      _speed += (1.8 / _currentGear);

      // 6000 devire ulaşıldığında vites yükseltme simülasyonu
      if (_rpm >= 6100.0) {
        _isShifting = true;
      }
    }

    _dataController.add(ObdRawData(
      rpm: _rpm,
      speed: _speed,
      throttle: _throttle,
      coolant: _coolant,
      load: 75.0,
      map: 160.0, // 1.6 Bar Turbo Boost
    ));
  }

  void dispose() {
    stop();
    _dataController.close();
  }
}
