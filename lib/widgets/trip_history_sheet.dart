import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../utils/formatters.dart';

class TripHistorySheet extends StatelessWidget {
  const TripHistorySheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF11141C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const TripHistorySheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final history = state.tripHistory;
    final totals = state.lifetimeTotals;
    final tracker = state.tripTracker;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) => Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık satırı
            Row(
              children: [
                const Icon(Icons.history, color: Colors.amberAccent, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'GEÇMİŞ SÜRÜŞLER & MALİYET ÖZETİ',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                ),
                if (history.isNotEmpty)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Tüm Geçmişi Sil',
                    icon: const Icon(Icons.delete_sweep, color: Colors.redAccent, size: 20),
                    onPressed: () => state.clearAllTrips(),
                  ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Aktif sürüş devam ediyorsa hızlı kaydetme satırı
            if (tracker.hasData)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.teal.shade900.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.tealAccent.withOpacity(0.45)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'AKTİF SÜRÜŞ DEVAM EDİYOR',
                            style: TextStyle(
                              color: Colors.tealAccent,
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '${tracker.distanceKm.toStringAsFixed(2)} km • ${tracker.fuelLiters.toStringAsFixed(2)} L • ${tracker.costTl.toStringAsFixed(2)} ₺',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      icon: const Icon(Icons.save, size: 15),
                      label: const Text(
                        'KAYDET',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () async {
                        final saved = await state.finalizeCurrentTrip();
                        if (saved != null && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Sürüş kaydedildi: ${saved.distanceKm.toStringAsFixed(1)} km | ${saved.fuelLiters.toStringAsFixed(2)} L | ${saved.totalCostTl.toStringAsFixed(1)} ₺',
                              ),
                              backgroundColor: Colors.green.shade700,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),

            // Tüm Zamanlar Genel Toplam Kartı
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E2636), Color(0xFF141822)],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.amberAccent.withOpacity(0.35)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'TÜM ZAMANLAR TOPLAMI (${totals.tripCount} Sürüş)',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.amberAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Süre: ${formatDuration(totals.durationSeconds)}',
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white24, height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _summaryItem(
                          'TOPLAM YOL',
                          '${totals.distanceKm.toStringAsFixed(1)} km',
                          Colors.white,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _summaryItem(
                          'HARCANAN YAKIT',
                          '${totals.fuelLiters.toStringAsFixed(2)} L',
                          Colors.cyanAccent,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _summaryItem(
                          'TOPLAM TUTAR',
                          '${totals.costTl.toStringAsFixed(2)} ₺',
                          Colors.greenAccent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Ort. Tüketim: ${totals.avgLitersPer100Km.toStringAsFixed(1)} L/100km',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Ort: ${totals.avgTlPerKm.toStringAsFixed(2)} ₺/km',
                        style: const TextStyle(
                          color: Colors.amberAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            Expanded(
              child: history.isEmpty
                  ? const Center(
                      child: Text(
                        'Henüz kaydedilmiş sürüş bulunmuyor.\nOBD bağlantısı kesildiğinde veya "Bitir & Kaydet"\nbutonuna bastığınızda sürüşleriniz burada listelenir.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white54, fontSize: 13),
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: history.length,
                      itemBuilder: (context, index) {
                        final item = history[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF171B24),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 13, color: Colors.white70),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      item.dateStr,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: item.fuelType == 'LPG'
                                          ? Colors.green.shade900
                                          : Colors.blue.shade900,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${item.fuelType} (${item.unitPriceTl.toStringAsFixed(2)} ₺)',
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  InkWell(
                                    onTap: () => state.deleteTripAt(index),
                                    child: const Icon(Icons.delete_outline, size: 18, color: Colors.white54),
                                  ),
                                ],
                              ),
                              const Divider(color: Colors.white12, height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: _summaryItem(
                                      'MESAFE',
                                      '${item.distanceKm.toStringAsFixed(2)} km',
                                      Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: _summaryItem(
                                      'YAKIT (${item.avgLitersPer100Km.toStringAsFixed(1)} L)',
                                      '${item.fuelLiters.toStringAsFixed(2)} L',
                                      Colors.cyanAccent,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: _summaryItem(
                                      'TUTAR (${item.avgTlPerKm.toStringAsFixed(2)} ₺/km)',
                                      '${item.totalCostTl.toStringAsFixed(2)} ₺',
                                      Colors.amberAccent,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 12,
                                runSpacing: 4,
                                children: [
                                  Text(
                                    '⏱ ${formatDuration(item.durationSeconds)}',
                                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                                  ),
                                  Text(
                                    '🚀 ${item.maxSpeed} km/s',
                                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                                  ),
                                  Text(
                                    '🔥 ${item.maxBoostBar >= 0 ? '+' : ''}${item.maxBoostBar.toStringAsFixed(2)} bar',
                                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                                  ),
                                  Text(
                                    '⚙️ ${item.maxRpm} d/d',
                                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white54, fontSize: 9.5, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }
}
