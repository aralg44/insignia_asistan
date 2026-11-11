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

    return Scaffold(
      backgroundColor: const Color(0xFF0B0E14),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.speed, color: Colors.cyanAccent),
            const SizedBox(width: 8),
            const Text(
              'INSIGNIA OBD',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                fontSize: 18,
              ),
            ),
            const Spacer(),
            // Bağlantı Durum Rozeti
            _buildStatusBadge(state),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.local_gas_station, color: Colors.tealAccent),
            tooltip: 'Yakıt ve Şehir Ayarları',
            onPressed: () => FuelSettingsDialog.show(context),
          ),
          IconButton(
            icon: const Icon(Icons.history, color: Colors.amberAccent),
            tooltip: 'Geçmiş Sürüşler',
            onPressed: () => TripHistorySheet.show(context),
          ),
          IconButton(
            icon: const Icon(Icons.bluetooth, color: Colors.white70),
            tooltip: 'OBD Bağlantısı',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BluetoothDevicesScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.tune, color: Colors.white70),
            tooltip: 'Ayarlar',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              // Sürüş Modu Seçici
              _buildDrivingModeSelector(context, state),
              const SizedBox(height: 12),

              // Ana Takometre Kadranı
              TachometerGauge(
                rpm: telemetry.rpm,
                speedKmh: telemetry.speedKmh,
                currentGear: telemetry.currentGear,
                isShiftLight: telemetry.isShiftLightActive,
              ),
              const SizedBox(height: 16),

              // Vites Tavsiye Şeridi (Shift Banner)
              ShiftIndicatorBanner(
                advice: telemetry.shiftAdvice,
                recommendedGear: telemetry.recommendedGear,
                isShiftLight: telemetry.isShiftLightActive,
              ),
              const SizedBox(height: 20),

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
                  const SizedBox(width: 12),
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
              const SizedBox(height: 12),
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: TelemetryCard(
                      title: 'Boost / MAP',
                      value: (telemetry.manifoldPressureKpa / 100.0).toStringAsFixed(2),
                      unit: 'Bar',
                      icon: Icons.compress,
                      accentColor: Colors.greenAccent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Canlı Sürüş Maliyeti & Geçmiş Kartı
              const TripCostCard(),
              const SizedBox(height: 16),

              // Canlı Simülasyon Demo Butonu
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: state.isSimulationMode ? Colors.redAccent : Colors.white70,
                  side: BorderSide(
                    color: state.isSimulationMode ? Colors.redAccent : Colors.white24,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: Icon(state.isSimulationMode ? Icons.stop : Icons.play_arrow),
                label: Text(
                  state.isSimulationMode ? 'Simülasyonu Durdur' : 'Canlı Sürüş Simülasyonu (Demo)',
                ),
                onPressed: () => state.toggleSimulationMode(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(AppStateProvider state) {
    if (state.isSimulationMode) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blueAccent),
        ),
        child: const Text('DEMO', style: TextStyle(fontSize: 10, color: Colors.blueAccent, fontWeight: FontWeight.bold)),
      );
    }

    Color color;
    String label;
    switch (state.connectionStatus) {
      case ObdConnectionStatus.connected:
        color = Colors.greenAccent;
        label = 'OBD BAĞLI';
        break;
      case ObdConnectionStatus.connecting:
      case ObdConnectionStatus.initializing:
        color = Colors.amberAccent;
        label = 'BAĞLANILIYOR';
        break;
      case ObdConnectionStatus.error:
        color = Colors.redAccent;
        label = 'HATA';
        break;
      case ObdConnectionStatus.disconnected:
      default:
        color = Colors.white30;
        label = 'BAĞLANTI YOK';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildDrivingModeSelector(BuildContext context, AppStateProvider state) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF161A22),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _buildModeTab('EKO', DrivingMode.eco, state),
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
                ? (mode == DrivingMode.sport ? Colors.redAccent : Colors.cyanAccent.withOpacity(0.2))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : Colors.white54,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
