import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

enum ObdConnectionStatus {
  disconnected,
  connecting,
  initializing,
  connected,
  error,
}

class ObdRawData {
  final double rpm;
  final double speed;
  final double throttle;
  final double coolant;
  final double load;
  final double map;

  ObdRawData({
    required this.rpm,
    required this.speed,
    required this.throttle,
    required this.coolant,
    required this.load,
    required this.map,
  });
}

class ObdService {
  BluetoothConnection? _connection;
  ObdConnectionStatus _status = ObdConnectionStatus.disconnected;
  final StreamController<ObdConnectionStatus> _statusController =
      StreamController<ObdConnectionStatus>.broadcast();
  final StreamController<ObdRawData> _dataController =
      StreamController<ObdRawData>.broadcast();

  bool _isPolling = false;
  String _buffer = '';

  // En son okunan canlı değerler
  double _lastRpm = 800.0;
  double _lastSpeed = 0.0;
  double _lastThrottle = 0.0;
  double _lastCoolant = 90.0;
  double _lastLoad = 15.0;
  double _lastMap = 101.0;

  Stream<ObdConnectionStatus> get statusStream => _statusController.stream;
  Stream<ObdRawData> get dataStream => _dataController.stream;
  ObdConnectionStatus get status => _status;

  /// Belirtilen Bluetooth MAC adresine sahip ELM327 cihazına bağlanır
  Future<bool> connect(String address) async {
    try {
      _setStatus(ObdConnectionStatus.connecting);
      _connection = await BluetoothConnection.toAddress(address);
      _setStatus(ObdConnectionStatus.initializing);

      // Gelen veri dinleyicisi
      _connection!.input!.listen(_onDataReceived, onDone: () {
        disconnect();
      }, onError: (error) {
        disconnect();
      });

      // ELM327 Başlatma AT Komutları
      await _initializeElm327();
      _setStatus(ObdConnectionStatus.connected);

      // Canlı PID okuma döngüsünü başlat
      _startPolling();
      return true;
    } catch (e) {
      _setStatus(ObdConnectionStatus.error);
      return false;
    }
  }

  void _setStatus(ObdConnectionStatus newStatus) {
    _status = newStatus;
    _statusController.add(_status);
  }

  /// ELM327 çipini Insignia CAN-bus iletişimine hazırlar
  Future<void> _initializeElm327() async {
    const initCommands = [
      'ATZ',   // Reset
      'ATE0',  // Echo kapat (hız için)
      'ATL0',  // Linefeed kapat
      'ATS0',  // Boşlukları kaldır
      'ATH0',  // Headerları kapat
      'ATSP0', // Otomatik CAN protokolü bulma
    ];

    for (var cmd in initCommands) {
      await sendCommand(cmd);
      await Future.delayed(const Duration(milliseconds: 150));
    }
  }

  Future<void> sendCommand(String cmd) async {
    if (_connection != null && _connection!.isConnected) {
      _connection!.output.add(Uint8List.fromList(utf8.encode('$cmd\r')));
      await _connection!.output.allSent;
    }
  }

  void _onDataReceived(Uint8List data) {
    String chunk = utf8.decode(data);
    _buffer += chunk;

    if (_buffer.contains('>')) {
      List<String> responses = _buffer.split('>');
      for (int i = 0; i < responses.length - 1; i++) {
        _parseResponse(responses[i].trim());
      }
      _buffer = responses.last;
    }
  }

  /// Gelen OBD2 PID yanıtlarını sayısal telemetriye dönüştürür
  void _parseResponse(String raw) {
    String clean = raw.replaceAll(' ', '').replaceAll('\r', '').replaceAll('\n', '').toUpperCase();

    // 010C -> Motor Devri (RPM) -> 410C AABB
    if (clean.contains('410C')) {
      int idx = clean.indexOf('410C') + 4;
      if (clean.length >= idx + 4) {
        String hexVal = clean.substring(idx, idx + 4);
        int? rawVal = int.tryParse(hexVal, radix: 16);
        if (rawVal != null) {
          _lastRpm = rawVal / 4.0;
        }
      }
    }
    // 010D -> Araç Hızı (Speed km/h) -> 410D AA
    else if (clean.contains('410D')) {
      int idx = clean.indexOf('410D') + 4;
      if (clean.length >= idx + 2) {
        String hexVal = clean.substring(idx, idx + 2);
        int? rawVal = int.tryParse(hexVal, radix: 16);
        if (rawVal != null) {
          _lastSpeed = rawVal.toDouble();
        }
      }
    }
    // 0111 -> Gaz Kelebeği Yüzdesi (%) -> 4111 AA
    else if (clean.contains('4111')) {
      int idx = clean.indexOf('4111') + 4;
      if (clean.length >= idx + 2) {
        String hexVal = clean.substring(idx, idx + 2);
        int? rawVal = int.tryParse(hexVal, radix: 16);
        if (rawVal != null) {
          _lastThrottle = (rawVal * 100.0) / 255.0;
        }
      }
    }
    // 0105 -> Motor Sıcaklığı (°C) -> 4105 AA
    else if (clean.contains('4105')) {
      int idx = clean.indexOf('4105') + 4;
      if (clean.length >= idx + 2) {
        String hexVal = clean.substring(idx, idx + 2);
        int? rawVal = int.tryParse(hexVal, radix: 16);
        if (rawVal != null) {
          _lastCoolant = rawVal - 40.0;
        }
      }
    }
    // 0104 -> Motor Yükü (%) -> 4104 AA
    else if (clean.contains('4104')) {
      int idx = clean.indexOf('4104') + 4;
      if (clean.length >= idx + 2) {
        String hexVal = clean.substring(idx, idx + 2);
        int? rawVal = int.tryParse(hexVal, radix: 16);
        if (rawVal != null) {
          _lastLoad = (rawVal * 100.0) / 255.0;
        }
      }
    }

    // Güncel veriyi stream'e fırlat
    _dataController.add(ObdRawData(
      rpm: _lastRpm,
      speed: _lastSpeed,
      throttle: _lastThrottle,
      coolant: _lastCoolant,
      load: _lastLoad,
      map: _lastMap,
    ));
  }

  /// Gerçek zamanlı telemetri PID döngüsü
  void _startPolling() async {
    _isPolling = true;
    while (_isPolling && _connection != null && _connection!.isConnected) {
      await sendCommand('010C'); // RPM (Öncelikli)
      await Future.delayed(const Duration(milliseconds: 40));

      await sendCommand('010D'); // Hız (Öncelikli)
      await Future.delayed(const Duration(milliseconds: 40));

      await sendCommand('0111'); // Gaz
      await Future.delayed(const Duration(milliseconds: 40));

      // Yardımcı parametreler (Sıcaklık ve yük daha seyrek sorgulanır)
      await sendCommand('0105');
      await Future.delayed(const Duration(milliseconds: 60));
    }
  }

  void disconnect() {
    _isPolling = false;
    _connection?.dispose();
    _connection = null;
    _setStatus(ObdConnectionStatus.disconnected);
  }

  void dispose() {
    disconnect();
    _statusController.close();
    _dataController.close();
  }
}
