// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/services/printer_service.dart';
import '../../../data/services/printer_settings.dart';
import '../../../data/services/network_printer_service.dart';

class PrinterSettingsPage extends StatefulWidget {
  const PrinterSettingsPage({super.key});

  @override
  State<PrinterSettingsPage> createState() => _PrinterSettingsPageState();
}

class _PrinterSettingsPageState extends State<PrinterSettingsPage> {
  late PrinterSettings _settings;
  PrinterService? _printerService;

  final _urlController = TextEditingController();
  final _namaTokoController = TextEditingController();
  final _alamatTokoController = TextEditingController();

  bool _isLoading = false;
  String _status = '';
  bool _printerConnected = false;

  @override
  void initState() {
    super.initState();
    _settings = sl<PrinterSettings>();
    _initService();
    _urlController.text = _settings.url;
    _namaTokoController.text = _settings.namaToko;
    _alamatTokoController.text = _settings.alamatToko;
    _checkConnection();
  }

  void _initService() {
    _printerService = NetworkPrinterService(baseUrl: _settings.url);
  }

  Future<void> _checkConnection() async {
    setState(() => _isLoading = true);
    try {
      _printerConnected = await _printerService!.isConnected();
      _status = _printerConnected ? 'Printer terhubung' : 'Printer tidak terhubung';
    } catch (e) {
      _status = 'Error: $e';
      _printerConnected = false;
    }
    setState(() => _isLoading = false);
  }

  Future<void> _testPrint() async {
    setState(() => _isLoading = true);
    try {
      final success = await _printerService!.testPrint();
      _status = success ? 'Test print berhasil!' : 'Test print gagal';
    } catch (e) {
      _status = 'Error: $e';
    }
    setState(() => _isLoading = false);
  }

  void _setFontSize(String? value) {
    if (value != null) setState(() => _settings.fontSize = value);
  }

  void _saveSettings() {
    _settings.url = _urlController.text;
    _settings.namaToko = _namaTokoController.text;
    _settings.alamatToko = _alamatTokoController.text;
    _initService();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pengaturan disimpan')),
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    _namaTokoController.dispose();
    _alamatTokoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: const EdgeInsets.all(0),
      children: [
          Card(
            child: SwitchListTile(
              title: const Text('Aktifkan Printer'),
              subtitle: const Text('Print otomatis setelah transaksi'),
              value: _settings.enabled,
              onChanged: (v) {
                setState(() => _settings.enabled = v);
              },
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: SwitchListTile(
              title: const Text('Auto Print'),
              subtitle: const Text('Langsung print tanpa konfirmasi'),
              value: _settings.autoPrint,
              onChanged: (v) {
                setState(() => _settings.autoPrint = v);
              },
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ALAMAT PRINT SERVER',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.neutralGrey,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Gunakan print_server.py di PC yang terhubung ke printer thermal USB.',
                    style: TextStyle(fontSize: 12, color: AppTheme.neutralGrey),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _urlController,
                    decoration: const InputDecoration(
                      hintText: 'http://192.168.1.100:5000',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.dns),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'IP PC yang menjalankan print_server.py',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.neutralGrey,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'LEBAR KERTAS',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.neutralGrey,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  RadioListTile<int>(
                    title: const Text('58 mm'),
                    value: 58,
                    groupValue: _settings.lebarKertas,
                    onChanged: (v) {
                      setState(() => _settings.lebarKertas = v!);
                    },
                  ),
                  RadioListTile<int>(
                    title: const Text('80 mm'),
                    value: 80,
                    groupValue: _settings.lebarKertas,
                    onChanged: (v) {
                      setState(() => _settings.lebarKertas = v!);
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'UKURAN FONT',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.neutralGrey,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  RadioListTile<String>(
                    title: const Text('Kecil'),
                    value: 'kecil',
                    groupValue: _settings.fontSize,
                    onChanged: _setFontSize,
                  ),
                  RadioListTile<String>(
                    title: const Text('Normal'),
                    value: 'normal',
                    groupValue: _settings.fontSize,
                    onChanged: _setFontSize,
                  ),
                  RadioListTile<String>(
                    title: const Text('Besar'),
                    value: 'besar',
                    groupValue: _settings.fontSize,
                    onChanged: _setFontSize,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'INFO TOKO (UNTUK NOTA)',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.neutralGrey,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _namaTokoController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Toko',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _alamatTokoController,
                    decoration: const InputDecoration(
                      labelText: 'Alamat Toko (opsional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'STATUS',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.neutralGrey,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        _printerConnected
                            ? Icons.check_circle
                            : Icons.error_outline,
                        color: _printerConnected
                            ? AppTheme.primaryGreen
                            : AppTheme.warningRed,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _status,
                          style: TextStyle(
                            color: _printerConnected
                                ? AppTheme.primaryGreen
                                : AppTheme.warningRed,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isLoading ? null : _checkConnection,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.refresh, size: 18),
                          label: const Text('Cek Koneksi'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _testPrint,
                          icon: const Icon(Icons.print, size: 18),
                          label: const Text('Test Print'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveSettings,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Simpan Pengaturan'),
            ),
          ),
        ],
    );
  }
}
