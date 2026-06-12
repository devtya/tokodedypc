import 'package:injectable/injectable.dart';

import '../models/receipt_data.dart';
import 'printer_service.dart';

@lazySingleton
class BluetoothPrinterService implements PrinterService {
  BluetoothPrinterService();

  @override
  String get printerType => 'bluetooth';

  static Future<List<Map<String, String>>> getBondedDevices() async {
    return [];
  }

  Future<bool> autoConnect() async => false;

  Future<bool> connect(dynamic device) async => false;

  Future<void> disconnect() async {}

  @override
  Future<bool> isConnected() async => false;

  @override
  Future<bool> testPrint() async {
    throw Exception('Bluetooth printing tidak didukung di Windows. Gunakan Network (HTTP) printer.');
  }

  @override
  Future<bool> printReceipt(ReceiptData data) async {
    throw Exception('Bluetooth printing tidak didukung di Windows. Gunakan Network (HTTP) printer.');
  }

  @override
  Future<bool> printPickingList(ReceiptData data) async {
    throw Exception('Bluetooth printing tidak didukung di Windows. Gunakan Network (HTTP) printer.');
  }
}
