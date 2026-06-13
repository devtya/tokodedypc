// ignore_for_file: deprecated_member_use
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_pos_printer_platform_image_3/flutter_pos_printer_platform_image_3.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/services/printer_service.dart';
import '../../../data/services/printer_settings.dart';
import '../../../data/services/windows_usb_printer_service.dart';

class PrinterSettingsPage extends StatefulWidget {
  const PrinterSettingsPage({super.key});

  @override
  State<PrinterSettingsPage> createState() => _PrinterSettingsPageState();
}

class _PrinterSettingsPageState extends State<PrinterSettingsPage> {
  late PrinterSettings _settings;
  PrinterService? _printerService;

  final _namaTokoController = TextEditingController();
  final _alamatTokoController = TextEditingController();

  bool _isLoading = false;
  String _status = '';
  bool _printerConnected = false;
  
  List<PrinterDevice> _usbPrinters = [];
  PrinterDevice? _selectedUsbPrinter;
  StreamSubscription<PrinterDevice>? _printerSubscription;

  @override
  void initState() {
    super.initState();
    _settings = sl<PrinterSettings>();
    _initService();
    _namaTokoController.text = _settings.namaToko;
    _alamatTokoController.text = _settings.alamatToko;
    
    _scanPrinters();
  }

  void _initService() {
    _printerService = sl<PrinterService>();
  }

  Future<void> _scanPrinters() async {
    setState(() {
      _isLoading = true;
      _usbPrinters.clear();
      _status = 'Mencari printer USB...';
    });

    try {
      _printerSubscription?.cancel();
      _printerSubscription = PrinterManager.instance.discover(type: PrinterType.usb).listen((device) {
        if (!mounted) return;
        setState(() {
          if (!_usbPrinters.any((p) => p.name == device.name)) {
            _usbPrinters.add(device);
          }
          
          if (_settings.usbPrinterName != null && device.name == _settings.usbPrinterName) {
            _selectedUsbPrinter = device;
          }
        });
      });

      // Let it scan for a few seconds
      await Future.delayed(const Duration(seconds: 3));
      
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (_usbPrinters.isEmpty) {
          _status = 'Tidak ada printer USB yang ditemukan';
        } else {
          _status = 'Ditemukan ${_usbPrinters.length} printer. Silakan pilih.';
        }
      });
      
      if (_selectedUsbPrinter != null) {
        _checkConnection();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _status = 'Error mencari printer: $e';
      });
    }
  }

  Future<void> _checkConnection() async {
    if (_selectedUsbPrinter == null) {
      setState(() {
        _status = 'Belum ada printer yang dipilih';
        _printerConnected = false;
      });
      return;
    }

    setState(() => _isLoading = true);
    try {
      final printerManager = PrinterManager.instance;
      _printerConnected = await printerManager.connect(
        type: PrinterType.usb,
        model: UsbPrinterInput(
          name: _selectedUsbPrinter!.name, 
          productId: _selectedUsbPrinter!.productId, 
          vendorId: _selectedUsbPrinter!.vendorId
        ),
      );
      _status = _printerConnected ? 'Printer USB terhubung!' : 'Gagal menghubungkan printer';
    } catch (e) {
      _status = 'Error: $e';
      _printerConnected = false;
    }
    setState(() => _isLoading = false);
  }

  Future<void> _testPrint() async {
    if (_selectedUsbPrinter == null) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih printer USB terlebih dahulu')));
       return;
    }
    
    // Save temporarily to settings so DI works for test
    _settings.usbPrinterName = _selectedUsbPrinter!.name;
    updatePrinterService();
    _initService();

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
    _settings.usbPrinterName = _selectedUsbPrinter?.name;
    _settings.namaToko = _namaTokoController.text;
    _settings.alamatToko = _alamatTokoController.text;
    
    updatePrinterService();
    _initService();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pengaturan disimpan')),
    );
  }

  @override
  void dispose() {
    _printerSubscription?.cancel();
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
                    'PILIH PRINTER USB',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.neutralGrey,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pilih printer thermal kasir yang terhubung langsung ke PC.',
                    style: TextStyle(fontSize: 12, color: AppTheme.neutralGrey),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<PrinterDevice>(
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                          ),
                          hint: const Text('Pilih Printer'),
                          value: _selectedUsbPrinter,
                          items: _usbPrinters.map((device) {
                            return DropdownMenuItem(
                              value: device,
                              child: Text(device.name ?? 'Unknown Device'),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedUsbPrinter = val;
                            });
                            _checkConnection();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _isLoading ? null : _scanPrinters,
                        icon: const Icon(Icons.refresh),
                        tooltip: 'Scan ulang printer',
                      ),
                    ],
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
                              : const Icon(Icons.usb, size: 18),
                          label: const Text('Cek USB'),
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
