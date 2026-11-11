import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../utils/formatters.dart';
import 'fuel_settings_dialog.dart';
import 'trip_history_sheet.dart';

class TripCostCard extends StatelessWidget {
  const TripCostCard({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final tracker = state.tripTracker;
    final fuel = state.fuelSettings;
    final coolant = state.telemetry.coolantTempCelsius;

    final String activeFuelBadge = fuel.lpgMode
        ? (tracker.isRunningOnLpg ? 'LPG AKTİF' : 'BENZİN (ISINIYOR ${coolant.toStringAsFixed(0)}°C)')
        : 'BENZİN';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF161A22),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.local_gas_station, size: 16, color: Colors.tealAccent),
                  const SizedBox(width: 6),
                  Text(
                    'SÜRÜŞ MALİYETİ ($activeFuelBadge)',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.tealAccent,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => FuelSettingsDialog.show(context),
                child: Text(
                  fuel.priceStatus,
                  style: const TextStyle(fontSize: 11, color: Colors.amberAccent),
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white12, height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _statCol(
                'ANLIK TÜKETİM',
                tracker.isFuelCutOff
                    ? '0.0 L/100'
                    : '${tracker.litersPer100Km.toStringAsFixed(1)} L/100',
                tracker.isFuelCutOff ? Colors.greenAccent : Colors.white,
              ),
              _statCol(
                'ANLIK MALİYET',
                '${tracker.tlPerKm.toStringAsFixed(2)} ₺/km',
                Colors.amberAccent,
              ),
              _statCol(
                'TOPLAM TUTAR',
                '${tracker.costTl.toStringAsFixed(2)} ₺',
                Colors.greenAccent,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mesafe: ${tracker.distanceKm.toStringAsFixed(2)} km',
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
              Text(
                'Harcanan: ${tracker.fuelLiters.toStringAsFixed(2)} L',
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
              Text(
                'Süre: ${formatDuration(tracker.activeSeconds.round())}',
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.amberAccent,
                    side: const BorderSide(color: Colors.amberAccent),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  icon: const Icon(Icons.history, size: 16),
                  label: Text(
                    'Geçmiş (${state.tripHistory.length})',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () => TripHistorySheet.show(context),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  icon: const Icon(Icons.save, size: 16),
                  label: const Text(
                    'Bitir & Kaydet',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () async {
                    final saved = await state.finalizeCurrentTrip();
                    if (!context.mounted) return;
                    if (saved != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Sürüş kaydedildi: ${saved.distanceKm.toStringAsFixed(1)} km | ${saved.fuelLiters.toStringAsFixed(2)} L | ${saved.totalCostTl.toStringAsFixed(1)} ₺',
                          ),
                          backgroundColor: Colors.green.shade700,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Kaydedilecek kadar sürüş verisi henüz oluşmadı.'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                tooltip: 'Aktif Sürüşü Sıfırla',
                icon: const Icon(Icons.refresh, size: 20, color: Colors.white54),
                onPressed: () => state.resetCurrentTrip(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCol(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.white54, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}
