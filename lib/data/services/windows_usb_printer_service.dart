import 'package:flutter_pos_printer_platform_image_3/flutter_pos_printer_platform_image_3.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

import '../models/receipt_data.dart';
import 'printer_service.dart';

class WindowsUsbPrinterService implements PrinterService {
  final String? printerName;

  WindowsUsbPrinterService({this.printerName});

  @override
  String get printerType => 'usb';

  @override
  Future<bool> isConnected() async {
    // There is no direct "is connected" for USB without trying to connect.
    // We'll just check if printerName is configured.
    return printerName != null && printerName!.isNotEmpty;
  }

  Future<List<int>> _generateEscPos(ReceiptData data) async {
    final profile = await CapabilityProfile.load();
    // 58mm = PaperSize.mm58, 80mm = PaperSize.mm80
    final paper = data.lebarKertas == 80 ? PaperSize.mm80 : PaperSize.mm58;
    final generator = Generator(paper, profile);
    List<int> bytes = [];

    // Header
    bytes += generator.text(data.namaToko,
        styles: const PosStyles(align: PosAlign.center, bold: true, width: PosTextSize.size2, height: PosTextSize.size2));
    if (data.alamatToko.isNotEmpty) {
      bytes += generator.text(data.alamatToko, styles: const PosStyles(align: PosAlign.center));
    }
    bytes += generator.emptyLines(1);

    // Info
    bytes += generator.text('Nota: ${data.transaksiId}');
    bytes += generator.text('Tgl : ${data.tanggal}');
    bytes += generator.text('Opr : ${data.kasir}');
    bytes += generator.emptyLines(1);
    bytes += generator.hr();

    // Items
    final is80mm = data.lebarKertas == 80;
    final kiri = is80mm ? 6 : 7;
    final kanan = is80mm ? 6 : 5;

    for (final item in data.items) {
      String qtyStr = '${item.jumlah} ${item.satuan ?? ''}';
      if (item.konversi != null && item.konversi! > 1) {
        qtyStr += ' (@${item.konversi})';
      }
      
      bytes += generator.text(item.nama, styles: const PosStyles(bold: true));
      
      final sub = (item.jumlah * item.harga) - item.diskon;
      bytes += generator.row([
        PosColumn(
            text: '$qtyStr x ${_formatRp(item.harga)}',
            width: kiri,
            styles: const PosStyles(align: PosAlign.left)),
        PosColumn(
            text: _formatRp(sub),
            width: kanan,
            styles: const PosStyles(align: PosAlign.right)),
      ]);
      
      if (item.diskon > 0) {
        bytes += generator.text('  Disc: -${_formatRp(item.diskon)}', styles: const PosStyles(align: PosAlign.left));
      }
    }

    bytes += generator.hr();

    // Totals
    bytes += generator.row([
      PosColumn(text: 'Subtotal', width: 6),
      PosColumn(text: _formatRp(data.subtotal), width: 6, styles: const PosStyles(align: PosAlign.right)),
    ]);

    if (data.totalDiskon > 0) {
      bytes += generator.row([
        PosColumn(text: 'Disc Item', width: 6),
        PosColumn(text: '-${_formatRp(data.totalDiskon)}', width: 6, styles: const PosStyles(align: PosAlign.right)),
      ]);
    }
    
    if (data.globalDiskon != null && data.globalDiskon! > 0) {
      bytes += generator.row([
        PosColumn(text: 'Disc Global', width: 6),
        PosColumn(text: '-${_formatRp(data.globalDiskon!)}', width: 6, styles: const PosStyles(align: PosAlign.right)),
      ]);
    }

    final finalTotal = data.subtotal - data.totalDiskon - (data.globalDiskon ?? 0);
    bytes += generator.row([
      PosColumn(text: 'TOTAL', width: 6, styles: const PosStyles(bold: true)),
      PosColumn(text: _formatRp(finalTotal), width: 6, styles: const PosStyles(align: PosAlign.right, bold: true)),
    ]);

    bytes += generator.row([
      PosColumn(text: 'Dibayar', width: 6),
      PosColumn(text: _formatRp(data.totalBayar), width: 6, styles: const PosStyles(align: PosAlign.right)),
    ]);

    bytes += generator.row([
      PosColumn(text: 'Kembali', width: 6),
      PosColumn(text: _formatRp(data.kembalian), width: 6, styles: const PosStyles(align: PosAlign.right)),
    ]);

    bytes += generator.emptyLines(1);
    bytes += generator.text('Terima Kasih Atas', styles: const PosStyles(align: PosAlign.center));
    bytes += generator.text('Kunjungan Anda', styles: const PosStyles(align: PosAlign.center));
    
    bytes += generator.emptyLines(3);
    bytes += generator.cut();
    bytes += generator.drawer();

    return bytes;
  }

  String _formatRp(num val) {
    final intPart = val.toInt().toString();
    return intPart.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (m) => '.',
    );
  }

  @override
  Future<bool> printReceipt(ReceiptData data) async {
    if (printerName == null || printerName!.isEmpty) throw Exception("Printer USB belum diatur.");
    
    final bytes = await _generateEscPos(data);
    return await _printBytes(bytes);
  }

  @override
  Future<bool> printPickingList(ReceiptData data) async {
    if (printerName == null || printerName!.isEmpty) throw Exception("Printer USB belum diatur.");
    
    final modifiedData = data.copyWith(
      namaToko: 'DAFTAR PENGAMBILAN\n\n${data.namaToko}',
      subtotal: 0,
      totalDiskon: 0,
      totalBayar: 0,
      kembalian: 0,
    );
    
    final bytes = await _generateEscPos(modifiedData);
    return await _printBytes(bytes);
  }

  @override
  Future<bool> testPrint() async {
    if (printerName == null || printerName!.isEmpty) throw Exception("Printer USB belum diatur.");
    
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);
    List<int> bytes = [];
    
    bytes += generator.text('Test Print USB Berhasil!', styles: const PosStyles(align: PosAlign.center, bold: true));
    bytes += generator.emptyLines(3);
    bytes += generator.cut();
    
    return await _printBytes(bytes);
  }

  @override
  Future<bool> openCashDrawer() async {
    if (printerName == null || printerName!.isEmpty) throw Exception("Printer USB belum diatur.");

    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);
    List<int> bytes = [];
    bytes += generator.drawer();
    return await _printBytes(bytes);
  }

  Future<bool> _printBytes(List<int> bytes) async {
    try {
      final printerManager = PrinterManager.instance;
      
      bool connected = await printerManager.connect(
        type: PrinterType.usb,
        model: UsbPrinterInput(name: printerName, productId: '', vendorId: ''),
      );
      
      if (!connected) return false;

      final success = await printerManager.send(type: PrinterType.usb, bytes: bytes);
      return success;
    } catch (e) {
      throw Exception('Gagal print USB: $e');
    }
  }
}
