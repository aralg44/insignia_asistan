import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/car_specs.dart';
import '../providers/app_state_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0B0E14),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Araç & Asistan Ayarları', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('ŞANZIMAN VE MOTOR SEÇİMİ'),
          Card(
            color: const Color(0xFF161A22),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Column(
              children: [
                RadioListTile<GearboxType>(
                  activeColor: Colors.cyanAccent,
                  title: const Text('Opel Insignia 1.4T / 1.6T (M32 Manuel 6 İleri)', style: TextStyle(color: Colors.white, fontSize: 14)),
                  subtitle: const Text('Dişli Oranları: 3.82 / 2.16 / 1.48 / 1.07 / 0.88 / 0.74', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  value: GearboxType.m32Manual6,
                  groupValue: state.specs.gearboxType,
                  onChanged: (val) {
                    if (val != null) {
                      state.setCarSpecs(CarSpecs.insigniaM32Default());
                    }
                  },
                ),
                const Divider(color: Colors.white12, height: 1),
                RadioListTile<GearboxType>(
                  activeColor: Colors.cyanAccent,
                  title: const Text('Opel Insignia 2.0 CDTI (F40 Manuel 6 İleri)', style: TextStyle(color: Colors.white, fontSize: 14)),
                  subtitle: const Text('Dişli Oranları: 3.92 / 2.04 / 1.32 / 0.95 / 0.76 / 0.62', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  value: GearboxType.f40Manual6,
                  groupValue: state.specs.gearboxType,
                  onChanged: (val) {
                    if (val != null) {
                      state.setCarSpecs(CarSpecs.insigniaF40Diesel());
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          _buildSectionHeader('LASTİK VE JANT ÖLÇÜSÜ'),
          Card(
            color: const Color(0xFF161A22),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Mevcut Lastik:', style: TextStyle(color: Colors.white, fontSize: 15)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.cyanAccent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.cyanAccent.withOpacity(0.4)),
                    ),
                    child: Text(
                      state.specs.tireSize,
                      style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          _buildSectionHeader('UYARI VE BİLDİRİM SEÇENEKLERİ'),
          Card(
            color: const Color(0xFF161A22),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Column(
              children: [
                SwitchListTile(
                  activeColor: Colors.cyanAccent,
                  title: const Text('Sesli Vites Değiştirme Uyarısı', style: TextStyle(color: Colors.white, fontSize: 14)),
                  subtitle: const Text('Shift Light ve vites büyütme eşiğinde bip sesi', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  value: state.isSoundEnabled,
                  onChanged: (_) => state.toggleSound(),
                ),
                const Divider(color: Colors.white12, height: 1),
                SwitchListTile(
                  activeColor: Colors.cyanAccent,
                  title: const Text('Titreşimli Geri Bildirim', style: TextStyle(color: Colors.white, fontSize: 14)),
                  subtitle: const Text('Kritik devirde telefonu titret', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  value: state.isVibrationEnabled,
                  onChanged: (_) => state.toggleVibration(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          _buildSectionHeader('HAKKINDA'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF161A22),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Insignia Vites Asistanı & OBD Kokpit',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                ),
                SizedBox(height: 6),
                Text(
                  'Bu uygulama, Opel Insignia araçların CAN-bus veri hattından ELM327 adaptörü aracılığıyla RPM ve hız telemetrisini çekerek anlık vitesi matematiksel olarak tespit eder ve sürüş modunuza göre en verimli vites değişim noktasını bildirir.',
                  style: TextStyle(color: Colors.white60, fontSize: 13, height: 1.4),
                ),
                SizedBox(height: 8),
                Text(
                  'Sürüm: v1.0.0 (Release Build)',
                  style: TextStyle(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white38,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
