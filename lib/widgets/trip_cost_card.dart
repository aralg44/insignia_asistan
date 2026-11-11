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

    final bool warmingUp = fuel.lpgMode && !tracker.isRunningOnLpg;
    final String activeFuelBadge = fuel.lpgMode
        ? (warmingUp ? 'ISINIYOR (${coolant.toStringAsFixed(0)}°C)' : 'LPG')
        : 'BENZİN';
    final Color badgeColor = warmingUp ? Colors.orangeAccent : Colors.tealAccent;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF141821),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Üst başlık: rozet + sağda fiyat durumu (taşma/çarpışma olmaz)
          Row(
            children: [
              const Icon(Icons.local_gas_station, size: 16, color: Colors.tealAccent),
              const SizedBox(width: 6),
              const Text(
                'SÜRÜŞ MALİYETİ',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: badgeColor.withOpacity(0.5)),
                ),
                child: Text(
                  activeFuelBadge,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: badgeColor,
                  ),
                ),
              ),
              const Spacer(),
              Flexible(
                child: InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () => FuelSettingsDialog.show(context),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Text(
                      fuel.priceStatus,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.amberAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white12, height: 18),

          // 3 ana metrik kutusu: eşit genişlik + FittedBox ile asla iç içe geçmez
          Row(
            children: [
              Expanded(
                child: _statBox(
                  'ANLIK TÜKETİM',
                  tracker.isFuelCutOff
                      ? '0.0 L/100'
                      : '${tracker.litersPer100Km.toStringAsFixed(1)} L/100',
                  tracker.isFuelCutOff ? Colors.greenAccent : Colors.cyanAccent,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _statBox(
                  'KM MALİYETİ',
                  '${tracker.tlPerKm.toStringAsFixed(2)} ₺/km',
                  Colors.amberAccent,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _statBox(
                  'TOPLAM TUTAR',
                  '${tracker.costTl.toStringAsFixed(2)} ₺',
                  Colors.greenAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Alt özet çubuğu
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFF0E1118),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _miniInfo(
                    Icons.route,
                    '${tracker.distanceKm.toStringAsFixed(2)} km',
                  ),
                ),
                Expanded(
                  child: _miniInfo(
                    Icons.opacity,
                    '${tracker.fuelLiters.toStringAsFixed(2)} L',
                  ),
                ),
                Expanded(
                  child: _miniInfo(
                    Icons.schedule,
                    formatDuration(tracker.activeSeconds.round()),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Aksiyon butonları
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.amberAccent,
                    side: BorderSide(color: Colors.amberAccent.withOpacity(0.6)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.history, size: 16),
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Geçmiş (${state.tripHistory.length})',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                  onPressed: () => TripHistorySheet.show(context),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1F8A4C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.save_outlined, size: 16),
                  label: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Bitir & Kaydet',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
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
              SizedBox(
                width: 38,
                height: 38,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  tooltip: 'Aktif Sürüşü Sıfırla',
                  icon: const Icon(Icons.refresh, size: 19, color: Colors.white54),
                  onPressed: () => state.resetCurrentTrip(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statBox(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1118),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 9.5,
              color: Colors.white54,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniInfo(IconData icon, String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 13, color: Colors.white38),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11.5,
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
