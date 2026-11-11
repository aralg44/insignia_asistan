import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../services/obd_service.dart';

class BluetoothDevicesScreen extends StatefulWidget {
  const BluetoothDevicesScreen({super.key});

  @override
  State<BluetoothDevicesScreen> createState() => _BluetoothDevicesScreenState();
}

class _BluetoothDevicesScreenState extends State<BluetoothDevicesScreen> {
  List<BluetoothDevice> _devices = [];
  bool _isLoading = true;
  String? _connectingAddress;

  @override
  void initState() {
    super.initState();
    _requestPermissionsAndLoadDevices();
  }

  Future<void> _requestPermissionsAndLoadDevices() async {
    setState(() => _isLoading = true);

    await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    try {
      List<BluetoothDevice> bonded =
          await FlutterBluetoothSerial.instance.getBondedDevices();
      setState(() {
        _devices = bonded;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0B0E14),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('OBD2 Cihazları', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _requestPermissionsAndLoadDevices,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
          : _devices.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _devices.length,
                  itemBuilder: (context, index) {
                    final device = _devices[index];
                    final isObd = (device.name ?? '').toLowerCase().contains('obd') ||
                        (device.name ?? '').toLowerCase().contains('elm') ||
                        (device.name ?? '').toLowerCase().contains('vgate');
                    final isConnecting = _connectingAddress == device.address &&
                        state.connectionStatus == ObdConnectionStatus.connecting;

                    return Card(
                      color: const Color(0xFF161A22),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: isObd ? Colors.cyanAccent.withOpacity(0.4) : Colors.white10,
                          width: isObd ? 1.5 : 1,
                        ),
                      ),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isObd ? Colors.cyanAccent.withOpacity(0.2) : Colors.white10,
                          child: Icon(
                            isObd ? Icons.directions_car : Icons.bluetooth,
                            color: isObd ? Colors.cyanAccent : Colors.white54,
                          ),
                        ),
                        title: Text(
                          device.name ?? 'Bilinmeyen Cihaz',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        subtitle: Text(
                          device.address,
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                        trailing: isConnecting
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.cyanAccent,
                                ),
                              )
                            : ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isObd ? Colors.cyanAccent : const Color(0xFF2A2E3D),
                                  foregroundColor: isObd ? Colors.black : Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: () async {
                                  setState(() => _connectingAddress = device.address);
                                  bool success = await state.connectToObd(device.address);
                                  if (mounted) {
                                    if (success) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('${device.name ?? "OBD"} bağlantısı kuruldu!'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                      Navigator.pop(context);
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Bağlantı başarısız oldu. Cihazı ve aracı kontrol edin.'),
                                          backgroundColor: Colors.redAccent,
                                        ),
                                      );
                                    }
                                  }
                                },
                                child: const Text('Bağlan'),
                              ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bluetooth_searching, size: 64, color: Colors.white30),
            const SizedBox(height: 16),
            const Text(
              'Eşleşmiş OBD Cihazı Bulunamadı',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            const Text(
              'Lütfen önce telefonunuzun Bluetooth ayarlarından ELM327 veya OBD2 adaptörünüzü eşleştirin (Genellikle PIN: 1234 veya 0000).',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white60, fontSize: 14),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Yeniden Tara'),
              onPressed: _requestPermissionsAndLoadDevices,
            ),
          ],
        ),
      ),
    );
  }
}
