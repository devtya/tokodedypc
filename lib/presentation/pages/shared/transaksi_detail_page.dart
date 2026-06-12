import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/receipt_data.dart';
import '../../../data/services/printer_service.dart';
import '../../../data/services/printer_settings.dart';
import '../../blocs/transaksi/transaksi_bloc.dart';
import '../../blocs/transaksi/transaksi_event.dart';
import '../../blocs/transaksi/transaksi_state.dart';
import 'share_receipt_page.dart';

/// Widget yang bisa ditampilkan baik sebagai Scaffold page maupun
/// sebagai konten di dalam Dialog (isDialog = true).
class TransaksiDetailPage extends StatefulWidget {
  final String transaksiId;

  const TransaksiDetailPage({super.key, required this.transaksiId});

  @override
  State<TransaksiDetailPage> createState() => _TransaksiDetailPageState();
}

class _TransaksiDetailPageState extends State<TransaksiDetailPage> {
  final _currency = NumberFormat.currency(locale: 'id', symbol: 'Rp', decimalDigits: 0);
  final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');
  bool _isPrinting = false;

  @override
  void initState() {
    super.initState();
    context.read<TransaksiBloc>().add(LoadTransaksiDetail(widget.transaksiId));
  }

  Future<void> _printReceipt() async {
    final state = context.read<TransaksiBloc>().state;
    final t = state.maybeWhen(detailLoaded: (transaksi) => transaksi, orElse: () => null);
    if (t == null) return;

    final messenger = ScaffoldMessenger.of(context);
    final settings = sl<PrinterSettings>();
    if (!settings.enabled) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Printer tidak aktif. Aktifkan di Pengaturan Printer.'),
          backgroundColor: AppTheme.warningRed,
        ),
      );
      return;
    }

    setState(() => _isPrinting = true);
    try {
      final items = t.items ?? [];
      final receiptItems = items
          .map((item) => ReceiptItem(
                nama: item.namaProduk ?? 'Produk #${item.produkId}',
                jumlah: item.jumlah,
                harga: item.hargaSatuan,
              ))
          .toList();

      final tanggal = DateFormat('dd/MM/yyyy HH:mm').format(t.createdAt ?? DateTime.now());
      final receipt = ReceiptData(
        namaToko: settings.namaToko,
        alamatToko: settings.alamatToko,
        transaksiId: t.id ?? widget.transaksiId,
        tanggal: tanggal,
        items: receiptItems,
        subtotal: t.totalHarga,
        totalBayar: t.jumlahBayar,
        kembalian: t.kembalian,
        lebarKertas: settings.lebarKertas,
        fontSize: settings.fontSize,
      );

      final printer = sl<PrinterService>();
      final success = await printer.printReceipt(receipt);
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(success ? 'Nota berhasil dicetak' : 'Gagal mencetak nota'),
            backgroundColor: success ? AppTheme.primaryGreen : AppTheme.warningRed,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Error print: $e'),
            backgroundColor: AppTheme.warningRed,
          ),
        );
      }
    }
    if (mounted) setState(() => _isPrinting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Transparent AppBar — berfungsi sebagai titlebar saat dalam Dialog
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 16,
        title: Text(
          'Transaksi #${widget.transaksiId.toString().substring(0, 8)}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: _isPrinting
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.print_rounded, size: 20),
            tooltip: 'Cetak Nota',
            onPressed: _isPrinting ? null : _printReceipt,
          ),
          BlocBuilder<TransaksiBloc, TransaksiState>(
            builder: (context, state) {
              return state.maybeWhen(
                detailLoaded: (t) => IconButton(
                  icon: const Icon(Icons.share_rounded, size: 20),
                  tooltip: 'Bagikan Nota',
                  onPressed: () {
                    final items = t.items ?? [];
                    final settings = sl<PrinterSettings>();
                    final receiptItems = items
                        .map((item) => ReceiptItem(
                              nama: item.namaProduk ?? 'Produk #${item.produkId}',
                              jumlah: item.jumlah,
                              harga: item.hargaSatuan,
                            ))
                        .toList();
                    final tanggal = DateFormat('dd/MM/yyyy HH:mm')
                        .format(t.createdAt ?? DateTime.now());
                    final receipt = ReceiptData(
                      namaToko: settings.namaToko,
                      alamatToko: settings.alamatToko,
                      transaksiId: t.id ?? widget.transaksiId,
                      tanggal: tanggal,
                      items: receiptItems,
                      subtotal: t.totalHarga,
                      totalBayar: t.jumlahBayar,
                      kembalian: t.kembalian,
                      lebarKertas: settings.lebarKertas,
                      fontSize: settings.fontSize,
                    );
                    showDialog(
                      context: context,
                      builder: (_) => Dialog(
                        clipBehavior: Clip.antiAlias,
                        child: SizedBox(
                          width: 450,
                          height: 650,
                          child: ShareReceiptPage(receipt: receipt),
                        ),
                      ),
                    );
                  },
                ),
                orElse: () => const SizedBox(),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            tooltip: 'Tutup',
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: BlocBuilder<TransaksiBloc, TransaksiState>(
        builder: (context, state) {
          return state.maybeWhen(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (message) => Center(child: Text(message)),
            detailLoaded: (t) {
              final items = t.items ?? [];
              final isHutang = t.status == 'hutang';

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status + tanggal row
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Status:', style: TextStyle(fontWeight: FontWeight.w600)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: isHutang
                                        ? AppTheme.warningOrange.withValues(alpha: 0.12)
                                        : AppTheme.primaryGreen.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    isHutang ? 'Hutang' : 'Lunas',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isHutang ? AppTheme.warningOrange : AppTheme.primaryGreen,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Tanggal:'),
                                Text(
                                  t.createdAt != null ? _dateFormat.format(t.createdAt!) : '-',
                                  style: TextStyle(color: AppTheme.neutralGrey),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Item Pembelian', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    ...items.map(
                      (item) => Card(
                        margin: const EdgeInsets.only(bottom: 4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.namaProduk ?? 'Produk #${item.produkId}',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                              Text('${item.jumlah}× ', style: TextStyle(color: AppTheme.neutralGrey)),
                              Text(
                                _currency.format(item.subtotal),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Total summary
                    Card(
                      color: AppTheme.lightGreen,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _summaryRow('Total', _currency.format(t.totalHarga), isBold: false),
                            const SizedBox(height: 8),
                            _summaryRow('Dibayar', _currency.format(t.jumlahBayar), isBold: false),
                            const Divider(),
                            _summaryRow('Kembali', _currency.format(t.kembalian), isBold: true),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
            orElse: () => const SizedBox(),
          );
        },
      ),
    );
  }

  Widget _summaryRow(String label, String value, {required bool isBold}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 15, fontWeight: isBold ? FontWeight.w700 : FontWeight.normal)),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.bold,
            color: isBold ? AppTheme.primaryGreen : null,
          ),
        ),
      ],
    );
  }
}
