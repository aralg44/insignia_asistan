import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/fuel_settings.dart';
import '../providers/app_state_provider.dart';

class FuelSettingsDialog extends StatefulWidget {
  const FuelSettingsDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const FuelSettingsDialog(),
    );
  }

  @override
  State<FuelSettingsDialog> createState() => _FuelSettingsDialogState();
}

class _FuelSettingsDialogState extends State<FuelSettingsDialog> {
  late TextEditingController _lpgCtrl;
  late TextEditingController _gasolineCtrl;
  late bool _lpgMode;
  late String _city;

  @override
  void initState() {
    super.initState();
    final fuel = context.read<AppStateProvider>().fuelSettings;
    _lpgCtrl = TextEditingController(text: fuel.lpgPrice.toStringAsFixed(2));
    _gasolineCtrl = TextEditingController(text: fuel.gasolinePrice.toStringAsFixed(2));
    _lpgMode = fuel.lpgMode;
    _city = fuel.city;
  }

  @override
  void dispose() {
    _lpgCtrl.dispose();
    _gasolineCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();

    return AlertDialog(
      backgroundColor: const Color(0xFF161A22),
      title: const Text('Yakıt ve Şehir Ayarları'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_lpgMode ? 'Aktif Yakıt: LPG' : 'Aktif Yakıt: Benzin'),
              subtitle: Text(
                state.fuelSettings.priceStatus,
                style: const TextStyle(color: Colors.amberAccent, fontSize: 12),
              ),
              value: _lpgMode,
              activeColor: Colors.greenAccent,
              onChanged: (val) => setState(() => _lpgMode = val),
            ),
            const Divider(color: Colors.white24),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _city,
                    decoration: const InputDecoration(
                      labelText: 'Şehir',
                      border: OutlineInputBorder(),
                    ),
                    items: FuelSettings.cities
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _city = val);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade700,
                  ),
                  icon: state.isFetchingFuelPrices
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.cloud_download, size: 16),
                  label: const Text('ÇEK'),
                  onPressed: state.isFetchingFuelPrices
                      ? null
                      : () async {
                          final ok = await state.fetchLiveFuelPrices(_city);
                          if (ok && mounted) {
                            setState(() {
                              _lpgCtrl.text = state.fuelSettings.lpgPrice.toStringAsFixed(2);
                              _gasolineCtrl.text = state.fuelSettings.gasolinePrice.toStringAsFixed(2);
                            });
                          }
                        },
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _lpgCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'LPG Litre Fiyatı (TL)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _gasolineCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Benzin Litre Fiyatı (TL)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, foregroundColor: Colors.black),
          onPressed: () {
            final lpg = double.tryParse(_lpgCtrl.text.replaceAll(',', '.')) ?? state.fuelSettings.lpgPrice;
            final gasoline = double.tryParse(_gasolineCtrl.text.replaceAll(',', '.')) ?? state.fuelSettings.gasolinePrice;
            state.updateFuelSettings(
              lpgMode: _lpgMode,
              lpgPrice: lpg,
              gasolinePrice: gasoline,
              city: _city,
            );
            Navigator.pop(context);
          },
          child: const Text('Kaydet', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
