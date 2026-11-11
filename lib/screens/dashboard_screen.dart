import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/car_specs.dart';
import '../models/telemetry_data.dart';
import '../providers/app_state_provider.dart';
import '../services/obd_service.dart';
import '../widgets/shift_indicator_banner.dart';
import '../widgets/tachometer_gauge.dart';
import '../widgets/telemetry_card.dart';
import '../widgets/fuel_settings_dialog.dart';
import '../widgets/trip_cost_card.dart';
import '../widgets/trip_history_sheet.dart';
import 'bluetooth_devices_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final telemetry = state.telemetry;
    final boostBar = (telemetry.manifoldPressureKpa - 100.0) / 100.0;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0E14),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 14,
        title: Row(
          children: [
            const Icon(Icons.speed, color: Colors.cyanAccent, size: 20),
            const SizedBox(width: 6),
            const Flexible(
              child: Text(
                'INSIGNIA OBD',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _buildStatusBadge(state),
          ],
        ),
        actions: [
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.local_gas_station, color: Colors.tealAccent, size: 21),
            tooltip: 'Yakıt ve Şehir Ayarları',
            onPressed: () => FuelSettingsDialog.show(context),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.history, color: Colors.amberAccent, size: 21),
            tooltip: 'Geçmiş Sürüşler',
            onPressed: () => TripHistorySheet.show(context),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.bluetooth, color: Colors.white70, size: 21),
            tooltip: 'OBD Bağlantısı',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BluetoothDevicesScreen()),
              );
            },
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.tune, color: Colors.white70, size: 21),
            tooltip: 'Ayarlar',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Column(
            children: [
              // Sürüş Modu Seçici
              _buildDrivingModeSelector(context, state),
              const SizedBox(height: 10),

              // Ana Takometre Kadranı
              TachometerGauge(
                rpm: telemetry.rpm,
                speedKmh: telemetry.speedKmh,
                currentGear: telemetry.currentGear,
                isShiftLight: telemetry.isShiftLightActive,
              ),
              const SizedBox(height: 12),

              // Vites Tavsiye Şeridi (Shift Banner)
              ShiftIndicatorBanner(
                advice: telemetry.shiftAdvice,
                recommendedGear: telemetry.recommendedGear,
                isShiftLight: telemetry.isShiftLightActive,
              ),
              const SizedBox(height: 14),

              // 4'lü Canlı Telemetri Kartları
              Row(
                children: [
                  Expanded(
                    child: TelemetryCard(
                      title: 'Motor Isısı',
                      value: telemetry.coolantTempCelsius.toStringAsFixed(0),
                      unit: '°C',
                      icon: Icons.thermostat,
                      accentColor: telemetry.coolantTempCelsius > 105
                          ? Colors.redAccent
                          : Colors.orangeAccent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TelemetryCard(
                      title: 'Gaz Kelebeği',
                      value: telemetry.throttlePercent.toStringAsFixed(0),
                      unit: '%',
                      icon: Icons.electric_bolt,
                      accentColor: Colors.cyanAccent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TelemetryCard(
                      title: 'Motor Yükü',
                      value: telemetry.engineLoadPercent.toStringAsFixed(0),
                      unit: '%',
                      icon: Icons.pie_chart,
                      accentColor: Colors.purpleAccent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TelemetryCard(
                      title: 'Turbo / Vakum',
                      value: '${boostBar >= 0 ? '+' : ''}${boostBar.toStringAsFixed(2)}',
                      unit: 'Bar',
                      icon: Icons.compress,
                      accentColor: boostBar > 0.3 ? Colors.amberAccent : Colors.greenAccent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Canlı Sürüş Maliyeti & Geçmiş Kartı
              const TripCostCard(),
              const SizedBox(height: 12),

              // Canlı Simülasyon Demo Butonu
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: state.isSimulationMode ? Colors.redAccent : Colors.white70,
                    side: BorderSide(
                      color: state.isSimulationMode ? Colors.redAccent : Colors.white24,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: Icon(state.isSimulationMode ? Icons.stop : Icons.play_arrow, size: 18),
                  label: Text(
                    state.isSimulationMode ? 'Simülasyonu Durdur' : 'Canlı Sürüş Simülasyonu (Demo)',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  onPressed: () => state.toggleSimulationMode(),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(AppStateProvider state) {
    if (state.isSimulationMode) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.2),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.blueAccent),
        ),
        child: const Text(
          'DEMO',
          style: TextStyle(fontSize: 9.5, color: Colors.blueAccent, fontWeight: FontWeight.bold),
        ),
      );
    }

    Color color;
    String label;
    switch (state.connectionStatus) {
      case ObdConnectionStatus.connected:
        color = Colors.greenAccent;
        label = 'BAĞLI';
        break;
      case ObdConnectionStatus.connecting:
      case ObdConnectionStatus.initializing:
        color = Colors.amberAccent;
        label = 'BAĞLANIYOR';
        break;
      case ObdConnectionStatus.error:
        color = Colors.redAccent;
        label = 'HATA';
        break;
      case ObdConnectionStatus.disconnected:
      default:
        color = Colors.white38;
        label = 'ÇEVRİMDIŞI';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 9.5, color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildDrivingModeSelector(BuildContext context, AppStateProvider state) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF141821),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          _buildModeTab('EKONOMİ', DrivingMode.eco, state),
          _buildModeTab('KONFOR', DrivingMode.comfort, state),
          _buildModeTab('SPORT', DrivingMode.sport, state),
        ],
      ),
    );
  }

  Widget _buildModeTab(String label, DrivingMode mode, AppStateProvider state) {
    bool isSelected = state.drivingMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => state.setDrivingMode(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? (mode == DrivingMode.sport
                    ? Colors.redAccent.withOpacity(0.85)
                    : Colors.cyanAccent.withOpacity(0.22))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white : Colors.white54,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
