import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  WakelockPlus.enable();
  runApp(const InsigniaApp());
}

class InsigniaApp extends StatelessWidget {
  const InsigniaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Insignia 1.6T Asistan',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0D0D0F),
      ),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FlutterTts _tts = FlutterTts();
  BluetoothConnection? _connection;
  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _selectedDevice;
  bool _isConnected = false;
  bool _isConnecting = false;
  bool _sesAktif = true;
  bool _ekonomiModu = true;

  // Yakıt ve Şehir Ayarları
  bool _lpgModu = true;
  double _lpgFiyati = 25.50;
  double _benzinFiyati = 44.00;
  String _seciliSehir = "SAKARYA";
  String _fiyatGuncellemeDurumu = "Kaydedilen fiyat";
  bool _fiyatCekiliyor = false;

  final List<String> _sehirListesi = [
    "SAKARYA", "ISTANBUL", "KOCAELI", "ANKARA", "IZMIR", "BURSA", "DUZCE", "BOLU", "ESKISEHIR", "ANTALYA"
  ];

  // Canlı OBD2 Telemetri Verileri
  int _rpm = 0;
  int _speed = 0;
  int _load = 0;
  int _mapKpa = 100;
  int _coolantTemp = 80;
  double _mafGrams = 0.0;
  int _currentGear = 0;
  String _arizaKodlari = "Yok";

  // Maliyet Metrikleri
  double _anlikLitreSaat = 0.0;
  double _anlikLitre100Km = 0.0;
  double _anlikTlKm = 0.0;
  double _toplamYolculukTl = 0.0;
  double _toplamYolculukKm = 0.0;
  bool _cutOffAktif = false;
  bool _zenginKarisimAktif = false;
  DateTime _lastCalcTime = DateTime.now();

  // Durum ve Ses Filtresi
  String _bannerText = "OBD2 CİHAZI SEÇİN";
  Color _bannerColor = const Color(0xFF2C2C2E);
  String? _lastProposedSpeech;
  int _stabilityCounter = 0;
  DateTime _lastSpokenTime = DateTime.now().subtract(const Duration(seconds: 15));

  // M32 WR Şanzıman Oranları
  final Map<int, List<double>> _m32Gears = {
    1: [115.0, 155.0, 4.273],
    2: [64.0,  83.0,  2.353],
    3: [40.0,  52.0,  1.475],
    4: [29.5,  37.0,  1.067],
    5: [24.8,  29.3,  0.875],
    6: [20.5,  24.7,  0.744],
  };

  @override
  void initState() {
    super.initState();
    _initAppSettings();
    _initTts();
    _initBluetooth();
  }

  Future<void> _initAppSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _lpgFiyati = prefs.getDouble('lpg_fiyat') ?? 25.50;
      _benzinFiyati = prefs.getDouble('benzin_fiyat') ?? 44.00;
      _lpgModu = prefs.getBool('lpg_modu') ?? true;
      _seciliSehir = prefs.getString('secili_sehir') ?? "SAKARYA";
      _fiyatGuncellemeDurumu = prefs.getString('son_guncelleme') ?? "Varsayılan fiyat";
    });
    await _fetchLiveFuelPrices(_seciliSehir);
  }

  Future<void> _savePrices(double lpg, double benzin, bool isLpg, String sehir, String durum) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('lpg_fiyat', lpg);
    await prefs.setDouble('benzin_fiyat', benzin);
    await prefs.setBool('lpg_modu', isLpg);
    await prefs.setString('secili_sehir', sehir);
    await prefs.setString('son_guncelleme', durum);
    setState(() {
      _lpgFiyati = lpg;
      _benzinFiyati = benzin;
      _lpgModu = isLpg;
      _seciliSehir = sehir;
      _fiyatGuncellemeDurumu = durum;
    });
  }

  Future<bool> _fetchLiveFuelPrices(String city) async {
    setState(() {
      _fiyatCekiliyor = true;
      _fiyatGuncellemeDurumu = "İnternetten çekiliyor...";
    });

    try {
      final url1 = Uri.parse("https://www.tppd.com.tr/tr/akaryakit-fiyatlari?il=${city.toLowerCase()}");
      final res1 = await http.get(url1, headers: {
        "User-Agent": "Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 Chrome/124.0.0.0 Mobile"
      }).timeout(const Duration(seconds: 6));

      if (res1.statusCode == 200) {
        final parsed = _extractPricesFromHtml(res1.body);
        if (parsed != null) {
          String saat = "${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}";
          await _savePrices(parsed['lpg']!, parsed['benzin']!, _lpgModu, city, "Canlı ($city $saat)");
          setState(() => _fiyatCekiliyor = false);
          return true;
        }
      }
    } catch (_) {}

    setState(() {
      _fiyatCekiliyor = false;
      _fiyatGuncellemeDurumu = "Çevrimdışı (Kayıtlı)";
    });
    return false;
  }

  Map<String, double>? _extractPricesFromHtml(String html) {
    final regex = RegExp(r'(\d{2}[.,]\d{2})');
    final matches = regex.allMatches(html);
    List<double> benzins = [];
    List<double> lpgs = [];
    for (final m in matches) {
      double? val = double.tryParse(m.group(1)!.replaceAll(',', '.'));
      if (val != null) {
        if (val >= 36.0 && val <= 65.0) benzins.add(val);
        else if (val >= 18.0 && val <= 35.5) lpgs.add(val);
      }
    }
    if (benzins.isNotEmpty && lpgs.isNotEmpty) return {'benzin': benzins.first, 'lpg': lpgs.first};
    return null;
  }

  Future<void> _initTts() async {
    await _tts.setLanguage("tr-TR");
    await _tts.setSpeechRate(0.52);
    await _tts.setPitch(1.0);
  }

  Future<void> _speak(String text) async {
    if (!_sesAktif) return;
    await _tts.speak(text);
  }

  Future<void> _initBluetooth() async {
    await [Permission.bluetooth, Permission.bluetoothConnect, Permission.bluetoothScan, Permission.location].request();
    List<BluetoothDevice> bonded = await FlutterBluetoothSerial.instance.getBondedDevices();
    setState(() {
      _devices = bonded;
      if (_devices.isNotEmpty) {
        _selectedDevice = _devices.firstWhere(
          (d) => (d.name ?? "").toUpperCase().contains("OBD") || (d.name ?? "").toUpperCase().contains("ELM"),
          orElse: () => _devices.first,
        );
      }
    });
  }

  Future<void> _connectOBD() async {
    if (_selectedDevice == null) return;
    setState(() {
      _isConnecting = true;
      _bannerText = "ELM327 BAĞLANIYOR...";
      _bannerColor = Colors.amber.shade800;
    });

    try {
      _connection = await BluetoothConnection.toAddress(_selectedDevice!.address);
      setState(() {
        _isConnected = true;
        _isConnecting = false;
        _lastCalcTime = DateTime.now();
        _bannerText = "BAĞLANDI - A16LET HAZIR";
        _bannerColor = Colors.green.shade700;
      });
      _speak("Insignia asistanı bağlandı");
      _startObdLoop();
    } catch (e) {
      setState(() {
        _isConnected = false;
        _isConnecting = false;
        _bannerText = "BAĞLANTI HATASI!";
        _bannerColor = Colors.red.shade800;
      });
    }
  }

  String _rxBuffer = "";

  Future<String> _sendObdCommand(String cmd) async {
    if (_connection == null || !_connection!.isConnected) return "";
    _rxBuffer = "";
    _connection!.output.add(Uint8List.fromList(utf8.encode("$cmd\r")));
    await _connection!.output.allSent;

    int elapsed = 0;
    while (!(_rxBuffer.contains(">")) && elapsed < 320) {
      await Future.delayed(const Duration(milliseconds: 20));
      elapsed += 20;
    }
    return _rxBuffer.replaceAll("\r", " ").replaceAll("\n", " ").replaceAll(">", "").trim();
  }

  // DTC ARIZA KODU OKUMA (Mod 03)
  Future<void> _readDtcCodes() async {
    if (!_isConnected) return;
    String yanit = await _sendObdCommand("03");
    setState(() {
      if (yanit.contains("43") && !yanit.contains("NODATA")) {
        _arizaKodlari = "Kayıtlı Arıza Var (Detay: $yanit)";
      } else {
        _arizaKodlari = "Arıza Yok / Temiz";
      }
    });
  }

  // DTC ARIZA KODU SİLME (Mod 04)
  Future<void> _clearDtcCodes() async {
    if (!_isConnected) return;
    await _sendObdCommand("04");
    setState(() => _arizaKodlari = "Arızalar Silindi");
    _speak("Arıza lambası sıfırlandı");
  }

  void _startObdLoop() async {
    _connection!.input!.listen((Uint8List data) {
      _rxBuffer += ascii.decode(data, allowInvalid: true);
    }).onDone(() {
      setState(() {
        _isConnected = false;
        _bannerText = "OBD BAĞLANTISI KOPTU";
        _bannerColor = Colors.red.shade900;
      });
    });

    for (String initCmd in ["ATZ", "ATE0", "ATL0", "ATS1", "ATH0", "ATSP0"]) {
      await _sendObdCommand(initCmd);
      await Future.delayed(const Duration(milliseconds: 70));
    }

    int loopCount = 0;
    while (_isConnected) {
      _parsePid(await _sendObdCommand("010C"), "0C", (a, b) => _rpm = ((a * 256) + b) ~/ 4);
      _parsePid(await _sendObdCommand("010D"), "0D", (a, _) => _speed = a);
      _parsePid(await _sendObdCommand("0104"), "04", (a, _) => _load = (a * 100) ~/ 255);
      _parsePid(await _sendObdCommand("010B"), "0B", (a, _) => _mapKpa = a);
      _parsePid(await _sendObdCommand("0110"), "10", (a, b) => _mafGrams = ((a * 256) + b) / 100.0);

      if (loopCount % 20 == 0) {
        _parsePid(await _sendObdCommand("0105"), "05", (a, _) => _coolantTemp = a - 40);
        if (loopCount % 60 == 0) await _readDtcCodes(); // Her 60 döngüde bir arızaları kontrol et
      }
      loopCount++;

      _calculateFuelAndCost();
      _evaluateShiftLogic();
      if (mounted) setState(() {});
    }
  }

  void _parsePid(String response, String expectedPid, Function(int a, int b) onParsed) {
    List<String> parts = response.split(RegExp(r'\s+'));
    int idx = parts.indexOf("41");
    if (idx != -1 && parts.length > idx + 2 && parts[idx + 1] == expectedPid) {
      int? a = int.tryParse(parts[idx + 2], radix: 16);
      int b = (parts.length > idx + 3) ? (int.tryParse(parts[idx + 3], radix: 16) ?? 0) : 0;
      if (a != null) onParsed(a, b);
    }
  }

  void _calculateFuelAndCost() {
    DateTime now = DateTime.now();
    double dtHours = now.difference(_lastCalcTime).inMilliseconds / 3600000.0;
    _lastCalcTime = now;

    double boostBar = (_mapKpa - 100) / 100.0;

    if (_speed > 15 && _currentGear > 0 && _rpm > 1400 && _load < 18 && _mapKpa < 38) {
      _cutOffAktif = true;
      _zenginKarisimAktif = false;
      _anlikLitreSaat = 0.0;
      _anlikLitre100Km = 0.0;
      _anlikTlKm = 0.0;
      if (dtHours > 0 && dtHours < 0.01) _toplamYolculukKm += _speed * dtHours;
      return;
    }
    _cutOffAktif = false;

    double effectiveMaf = _mafGrams;
    if (effectiveMaf <= 0.1 && _rpm > 500) effectiveMaf = (_rpm * _mapKpa * 0.00095);

    double afr = 14.7;
    if (boostBar > 0.35 || _load > 70 || _rpm > 4500) {
      afr = 11.8;
      _zenginKarisimAktif = true;
    } else {
      _zenginKarisimAktif = false;
    }

    double benzinLitreSaat = (effectiveMaf * 3600.0) / (afr * 745.0);
    bool suAnLpgde = _lpgModu && (_coolantTemp >= 40);
    double aktifBirimFiyat = suAnLpgde ? _lpgFiyati : _benzinFiyati;
    double lpgHacimCarpani = suAnLpgde ? 1.18 : 1.0;

    _anlikLitreSaat = benzinLitreSaat * lpgHacimCarpani;

    if (_speed >= 5) {
      _anlikLitre100Km = (_anlikLitreSaat / _speed) * 100.0;
      _anlikTlKm = (_anlikLitre100Km / 100.0) * aktifBirimFiyat;
    } else {
      _anlikLitre100Km = 0.0;
      _anlikTlKm = _anlikLitreSaat * aktifBirimFiyat;
    }

    if (dtHours > 0 && dtHours < 0.01) {
      double harcananLitre = _anlikLitreSaat * dtHours;
      _toplamYolculukTl += harcananLitre * aktifBirimFiyat;
      _toplamYolculukKm += _speed * dtHours;
    }
  }

  int _detectGear(int rpm, int speed) {
    if (speed < 5 || rpm < 950) return 0;
    double ratio = rpm / speed;
    for (var entry in _m32Gears.entries) {
      if (ratio >= entry.value[0] && ratio <= entry.value[1]) return entry.key;
    }
    return 0;
  }

  int _nextGearRpm(int gear, int rpm) {
    if (gear <= 0 || gear >= 6) return rpm;
    return (rpm * (_m32Gears[gear + 1]![2] / _m32Gears[gear]![2])).round();
  }

  void _evaluateShiftLogic() {
    _currentGear = _detectGear(_rpm, _speed);
    if (_currentGear == 0) {
      _bannerText = _speed < 5 ? "DURUYOR / RÖLANTİ" : "DEBRİYAJ / VİTES GEÇİŞİ";
      _bannerColor = const Color(0xFF3A3A3C);
      _stabilityCounter = 0;
      return;
    }

    if (_cutOffAktif) {
      _bannerText = "● KOMPRESYON (CUT-OFF: 0.00 TL/km)";
      _bannerColor = Colors.teal.shade700;
      _stabilityCounter = 0;
      return;
    }

    double boostBar = (_mapKpa - 100) / 100.0;
    String? speechCmd;

    if (_coolantTemp > 0 && _coolantTemp < 70 && _rpm > 2800) {
      _bannerText = "MOTOR SOĞUK (${_coolantTemp}°C) - VİTES BÜYÜT!";
      _bannerColor = Colors.blue.shade800;
      speechCmd = "Motor henüz soğuk, vitesi yükselt";
    } else if (_currentGear == 6 && _speed < 82 && _load > 35) {
      _bannerText = "▼ HIZ DÜŞÜK! 5. VİTESE DÜŞ";
      _bannerColor = const Color(0xFFFF3B30);
      speechCmd = "Hız düşük, beşinci vitese düş";
    } else if (_currentGear >= 3 && _rpm < 1550 && (_load > 55 || boostBar > 0.15)) {
      _bannerText = "▼ MOTOR ZORLANIYOR! ${_currentGear - 1}. VİTESE DÜŞ";
      _bannerColor = const Color(0xFFFF3B30);
      speechCmd = "Motor zorlanıyor, ${_currentGear - 1}. vitese düş";
    } else if (_currentGear >= 2 && _rpm < 1250 && _load > 30) {
      _bannerText = "▼ DEVİR ÇOK DÜŞTÜ! VİTES KÜÇÜLT";
      _bannerColor = const Color(0xFFFF3B30);
      speechCmd = "Devir çok düştü, vitesi küçült";
    } else if (_currentGear < 6) {
      int nextRpm = _nextGearRpm(_currentGear, _rpm);
      if (_ekonomiModu) {
        if (nextRpm >= 1620) {
          if (_load <= 45 && boostBar <= 0.25 && _rpm >= 2300) {
            _bannerText = "▲ EKONOMİ: ${_currentGear + 1}. VİTESE GEÇ";
            _bannerColor = const Color(0xFFFF9500);
            speechCmd = "Vitesi yükselt, ${_currentGear + 1}e geç";
          } else if (_load > 45 && _load <= 72 && _rpm >= 2700) {
            _bannerText = "▲ ${_currentGear + 1}. VİTESE GEÇ";
            _bannerColor = const Color(0xFFFF9500);
            speechCmd = "Vitesi yükselt";
          } else if (_load > 72 && _rpm >= 5800) {
            _bannerText = "▲ MAKSİMUM GÜÇ! VİTES AT";
            _bannerColor = const Color(0xFFFF2D55);
            speechCmd = "Vitesi yükselt";
          }
        }
      } else {
        if (_rpm >= 5850) {
          _bannerText = "▲ 5850 RPM! VİTES YÜKSELT";
          _bannerColor = const Color(0xFFFF2D55);
          speechCmd = "Vitesi yükselt";
        }
      }
    }

    if (speechCmd == null) {
      if (_zenginKarisimAktif) {
        _bannerText = "🔥 ZENGİN KARIŞIM (AFR 11.8 - YÜKSEK TÜKETİM)";
        _bannerColor = Colors.deepOrange.shade800;
      } else if (_rpm >= 1600 && _rpm <= 2250 && boostBar <= 0.30) {
        _bannerText = "● İDEAL EKONOMİ (LAMBDA 1.0)";
        _bannerColor = const Color(0xFF34C759);
      } else {
        _bannerText = "● NORMAL SEYİR (${_currentGear}. VİTES)";
        _bannerColor = const Color(0xFF0A84FF);
      }
    }

    if (speechCmd != null && speechCmd == _lastProposedSpeech) {
      _stabilityCounter++;
      if (_stabilityCounter >= 5 && DateTime.now().difference(_lastSpokenTime).inSeconds >= 8) {
        _speak(speechCmd);
        _lastSpokenTime = DateTime.now();
        _stabilityCounter = 0;
      }
    } else {
      _lastProposedSpeech = speechCmd;
      _stabilityCounter = 0;
    }
  }

  void _showPriceAndDtcDialog() {
    final lpgCtrl = TextEditingController(text: _lpgFiyati.toStringAsFixed(2));
    final benzinCtrl = TextEditingController(text: _benzinFiyati.toStringAsFixed(2));
    bool tempIsLpg = _lpgModu;
    String tempSehir = _seciliSehir;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1C1C1E),
          title: const Text("Yakıt, Şehir ve Arıza Menüsü"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(tempIsLpg ? "Aktif Yakıt: LPG (Otogaz)" : "Aktif Yakıt: Benzin"),
                  subtitle: Text(_fiyatGuncellemeDurumu, style: const TextStyle(color: Colors.amberAccent, fontSize: 12)),
                  value: tempIsLpg,
                  activeColor: Colors.greenAccent,
                  onChanged: (val) => setDialogState(() => tempIsLpg = val),
                ),
                const Divider(color: Colors.white24),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: tempSehir,
                        decoration: const InputDecoration(labelText: "Şehir Seçin", border: OutlineInputBorder()),
                        items: _sehirListesi.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                        onChanged: (val) {
                          if (val != null) setDialogState(() => tempSehir = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.shade700,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      ),
                      icon: const Icon(Icons.cloud_download, size: 18),
                      label: const Text("ÇEK"),
                      onPressed: () async {
                        bool ok = await _fetchLiveFuelPrices(tempSehir);
                        if (ok) {
                          setDialogState(() {
                            lpgCtrl.text = _lpgFiyati.toStringAsFixed(2);
                            benzinCtrl.text = _benzinFiyati.toStringAsFixed(2);
                          });
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: lpgCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: "LPG Fiyatı (TL)", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: benzinCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: "Benzin Fiyatı (TL)", border: OutlineInputBorder()),
                ),
                const Divider(color: Colors.white24, height: 20),
                // ARIZA KODU BÖLÜMÜ
                Text("Motor Arıza Durumu: $_arizaKodlari", style: const TextStyle(color: Colors.orangeAccent, fontSize: 12)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey.shade800),
                      icon: const Icon(Icons.search, size: 16),
                      label: const Text("KONTROL ET"),
                      onPressed: () => _readDtcCodes(),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade800),
                      icon: const Icon(Icons.delete_forever, size: 16),
                      label: const Text("ARIZAYI SİL"),
                      onPressed: () {
                        _clearDtcCodes();
                        Navigator.pop(ctx);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _toplamYolculukTl = 0.0;
                  _toplamYolculukKm = 0.0;
                });
                Navigator.pop(ctx);
              },
              child: const Text("SAYACI SIFIRLA", style: TextStyle(color: Colors.redAccent)),
            ),
            ElevatedButton(
              onPressed: () {
                double lpg = double.tryParse(lpgCtrl.text.replaceAll(',', '.')) ?? _lpgFiyati;
                double benzin = double.tryParse(benzinCtrl.text.replaceAll(',', '.')) ?? _benzinFiyati;
                _savePrices(lpg, benzin, tempIsLpg, tempSehir, "Güncel");
                Navigator.pop(ctx);
              },
              child: const Text("KAYDET"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double boostBar = (_mapKpa - 100) / 100.0;
    bool suAnLpgde = _lpgModu && (_coolantTemp >= 40);
    String aktifYakitEtiketi = _lpgModu
        ? (suAnLpgde ? "LPG (${_lpgFiyati.toStringAsFixed(2)} ₺)" : "SOĞUK: BENZİNDE")
        : "BENZİN (${_benzinFiyati.toStringAsFixed(2)} ₺)";

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1C1E),
        title: const Text("INSIGNIA 1.6T ASİSTAN", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        actions: [
          TextButton.icon(
            onPressed: _showPriceAndDtcDialog,
            icon: _fiyatCekiliyor
                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.amberAccent))
                : const Icon(Icons.local_gas_station, color: Colors.amberAccent, size: 18),
            label: Text(
              "${_lpgModu ? 'LPG' : 'BENZİN'} ($_seciliSehir)",
              style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 11),
            ),
          ),
          IconButton(
            icon: Icon(_sesAktif ? Icons.volume_up : Icons.volume_off, color: _sesAktif ? Colors.greenAccent : Colors.grey),
            onPressed: () => setState(() => _sesAktif = !_sesAktif),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<BluetoothDevice>(
                      isExpanded: true,
                      hint: const Text("Eşleşmiş OBD2 Seçin"),
                      value: _selectedDevice,
                      items: _devices.map((d) => DropdownMenuItem(value: d, child: Text(d.name ?? d.address))).toList(),
                      onChanged: _isConnected ? null : (val) => setState(() => _selectedDevice = val),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isConnected ? Colors.red.shade700 : Colors.blue.shade700,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onPressed: _isConnecting ? null : (_isConnected ? () => _connection?.close() : _connectOBD),
                  child: Text(_isConnected ? "KES" : "BAĞLAN", style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 6),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(color: _bannerColor, borderRadius: BorderRadius.circular(10)),
              child: Text(
                _bannerText,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.5),
              ),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C1C1E),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white12, width: 1.5),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("AKTİF VİTES", style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                          Text(
                            _currentGear == 0 ? "N" : "$_currentGear",
                            style: const TextStyle(fontSize: 78, fontWeight: FontWeight.w900, color: Colors.white),
                          ),
                          if (_currentGear > 0 && _currentGear < 6)
                            Text(
                              "${_currentGear + 1}. Vites: ${_nextGearRpm(_currentGear, _rpm)} d/d",
                              style: const TextStyle(color: Colors.amberAccent, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  Expanded(
                    flex: 6,
                    child: GestureDetector(
                      onTap: _showPriceAndDtcDialog,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C1C1E),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _cutOffAktif ? Colors.tealAccent : (_zenginKarisimAktif ? Colors.deepOrange : Colors.white12),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Text(aktifYakitEtiketi, style: const TextStyle(color: Colors.amberAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                            Text(
                              _speed >= 5 ? "${_anlikTlKm.toStringAsFixed(2)} ₺" : "${_anlikTlKm.toStringAsFixed(1)} ₺",
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: _cutOffAktif ? Colors.greenAccent : (_zenginKarisimAktif ? Colors.redAccent : Colors.white),
                              ),
                            ),
                            Text(
                              _speed >= 5 ? "TL / Kilometre ($_fiyatGuncellemeDurumu)" : "TL / Saat (Rölanti)",
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white54, fontSize: 9),
                            ),
                            const Divider(color: Colors.white12, height: 8),
                            Text(
                              _speed >= 5 ? "${_anlikLitre100Km.toStringAsFixed(1)} L / 100km" : "${_anlikLitreSaat.toStringAsFixed(2)} L / saat",
                              style: const TextStyle(color: Colors.cyanAccent, fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              "Yolculuk: ${_toplamYolculukTl.toStringAsFixed(1)} ₺ (${_toplamYolculukKm.toStringAsFixed(1)} km)",
                              style: const TextStyle(color: Colors.white70, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                _metricCard("DEVİR", "$_rpm", "d/dak", _rpm > 2400 && _ekonomiModu ? Colors.orangeAccent : Colors.white),
                const SizedBox(width: 8),
                _metricCard("HIZ", "$_speed", "km/s", Colors.white),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _metricCard("TURBO (MAP)", "${boostBar >= 0 ? '+' : ''}${boostBar.toStringAsFixed(2)}", "bar", boostBar > 0.35 ? Colors.redAccent : Colors.greenAccent),
                const SizedBox(width: 8),
                _metricCard("MOTOR YÜKÜ", "%$_load", "Su: ${_coolantTemp}°C", Colors.cyanAccent),
              ],
            ),
            const SizedBox(height: 8),

            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text("Şehir İçi Ekonomi"), icon: Icon(Icons.eco)),
                ButtonSegment(value: false, label: Text("Performans (5850 RPM)"), icon: Icon(Icons.speed)),
              ],
              selected: {_ekonomiModu},
              onSelectionChanged: (val) => setState(() => _ekonomiModu = val.first),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricCard(String title, String value, String unit, Color valColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(color: const Color(0xFF1C1C1E), borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Text(title, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(color: valColor, fontSize: 22, fontWeight: FontWeight.w900)),
            Text(unit, style: const TextStyle(color: Colors.white54, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
