import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/item_pembelian.dart';
import '../../../domain/entities/pembelian.dart';
import '../../../core/di/injection.dart';
import '../../blocs/pembelian/pembelian_bloc.dart';
import '../../blocs/pembelian/pembelian_event.dart';
import '../../blocs/pembelian/pembelian_state.dart';
import '../../blocs/purchase_order/purchase_order_bloc.dart';
import '../../blocs/produk/produk_bloc.dart';
import 'pembelian_form_page.dart';
import 'pending_pembelian_page.dart';
import 'purchase_order_page.dart';
import '../../../domain/repositories/pending_pembelian_repository.dart';
import '../../../data/models/receipt_data.dart';
import '../../../data/services/printer_service.dart';
import '../../../data/services/printer_settings.dart';
import 'share_receipt_page.dart';

class PembelianPage extends StatefulWidget {
  const PembelianPage({super.key});

  @override
  State<PembelianPage> createState() => _PembelianPageState();
}

class _PembelianPageState extends State<PembelianPage> {
  final _currency = NumberFormat.currency(locale: 'id', symbol: 'Rp', decimalDigits: 0);
  final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');
  final _searchController = TextEditingController();
  int _pendingCount = 0;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    context.read<PembelianBloc>().add(LoadPembelian());
    _loadPendingCount();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPendingCount() async {
    final pendingRepo = sl<PendingPembelianRepository>();
    final pendingList = await pendingRepo.getAllPending();
    if (mounted) setState(() => _pendingCount = pendingList.length);
  }

  void _showAddChoiceDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pilih Metode Pembelian'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.shopping_cart, color: AppTheme.primaryGreen),
              title: const Text('Beli Langsung'),
              subtitle: const Text('Barang ready, langsung dibeli'),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              onTap: () {
                Navigator.pop(ctx);
                _navKey.currentState!.push(
                  MaterialPageRoute(
                    builder: (_) => MultiBlocProvider(
                      providers: [
                        BlocProvider.value(value: context.read<PembelianBloc>()),
                        BlocProvider.value(value: sl<ProdukBloc>()),
                      ],
                      child: const PembelianFormPage(),
                    ),
                  ),
                ).then((_) => _loadPendingCount());
              },
            ),
            const SizedBox(height: 4),
            ListTile(
              leading: const Icon(Icons.receipt_long, color: Colors.orange),
              title: const Text('Pesan ke Supplier (PO)'),
              subtitle: const Text('Barang kosong/indent, pesan dulu'),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              onTap: () {
                Navigator.pop(ctx);
                _navKey.currentState!.push(
                  MaterialPageRoute(
                    builder: (_) => MultiBlocProvider(
                      providers: [
                        BlocProvider(create: (_) => sl<PurchaseOrderBloc>()),
                        BlocProvider.value(value: sl<ProdukBloc>()),
                      ],
                      child: const PurchaseOrderPage(),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
        ],
      ),
    );
  }

  void _showDetailDialog(Pembelian p) {
    final bloc = context.read<PembelianBloc>();
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: Dialog(
          insetPadding: const EdgeInsets.all(40),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            width: 560,
            height: 640,
            child: _PembelianDetailWidget(
              pembelian: p,
              onEdit: (p) {
                Navigator.pop(context);
                _openEditForm(p);
              },
              onPrint: _printPembelian,
              onShare: _sharePembelian,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _printPembelian(Pembelian p, List<ItemPembelian> items) async {
    final messenger = ScaffoldMessenger.of(context);
    final settings = sl<PrinterSettings>();
    if (!settings.enabled) {
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Printer tidak aktif. Aktifkan di Pengaturan Printer.'),
            backgroundColor: AppTheme.warningRed,
          ),
        );
      }
      return;
    }
    try {
      final receiptItems = items.map((item) {
        final nama = item.namaProduk ?? 'Produk #${item.produkId}';
        final parts = nama.split(' - ');
        final unitName = parts.length > 1 ? parts.sublist(1).join(' - ') : null;
        return ReceiptItem(
          nama: parts[0],
          jumlah: item.jumlah,
          harga: item.hargaBeliSatuan,
          satuan: unitName,
          konversi: item.konversi,
        );
      }).toList();

      final now = DateTime.now();
      final tanggal = DateFormat('dd/MM/yyyy HH:mm').format(now);
      final receipt = ReceiptData(
        namaToko: p.namaSupplier ?? settings.namaToko,
        alamatToko: settings.alamatToko,
        transaksiId: p.id!,
        tanggal: tanggal,
        items: receiptItems,
        subtotal: p.totalHarga,
        totalBayar: p.totalHarga,
        metodePembayaran: '',
        lebarKertas: settings.lebarKertas,
        fontSize: settings.fontSize,
      );
      final printer = sl<PrinterService>();
      final success = await printer.printReceipt(receipt);
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(success ? 'Nota pembelian berhasil dicetak' : 'Gagal mencetak nota'),
            backgroundColor: success ? AppTheme.primaryGreen : AppTheme.warningRed,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Error print: $e'), backgroundColor: AppTheme.warningRed),
        );
      }
    }
  }

  Future<void> _sharePembelian(Pembelian p, List<ItemPembelian> items) async {
    final receiptItems = items.map((item) {
      final nama = item.namaProduk ?? 'Produk #${item.produkId}';
      final parts = nama.split(' - ');
      final unitName = parts.length > 1 ? parts.sublist(1).join(' - ') : null;
      return ReceiptItem(
        nama: parts[0],
        jumlah: item.jumlah,
        harga: item.hargaBeliSatuan,
        satuan: unitName,
        konversi: item.konversi,
      );
    }).toList();
    final now = p.createdAt ?? DateTime.now();
    final tanggal = DateFormat('dd/MM/yyyy HH:mm').format(now);
    final settings = sl<PrinterSettings>();
    final receipt = ReceiptData(
      namaToko: p.namaSupplier ?? settings.namaToko,
      alamatToko: settings.alamatToko,
      transaksiId: p.id!,
      tanggal: tanggal,
      items: receiptItems,
      subtotal: p.totalHarga,
      totalBayar: p.totalHarga,
      metodePembayaran: '',
      lebarKertas: settings.lebarKertas,
      fontSize: settings.fontSize,
    );
    if (mounted) {
      _navKey.currentState!.push(
        MaterialPageRoute(builder: (_) => ShareReceiptPage(receipt: receipt, showCompactItems: true)),
      );
    }
  }

  void _openEditForm(Pembelian p) {
    _navKey.currentState!.push(
      MaterialPageRoute(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: context.read<PembelianBloc>()),
            BlocProvider.value(value: sl<ProdukBloc>()),
          ],
          child: PembelianFormPage(existingPembelianId: p.id),
        ),
      ),
    ).then((_) {
      if (mounted) context.read<PembelianBloc>().add(LoadPembelian());
    });
  }

  final GlobalKey<NavigatorState> _navKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: _navKey,
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
          builder: (innerCtx) => _buildMain(innerCtx),
        );
      },
    );
  }

  Widget _buildMain(BuildContext context) {
    return Column(
      children: [
        // ── Toolbar ───────────────────────────────────────────────
        _buildToolbar(),
        // ── Content ───────────────────────────────────────────────
        Expanded(
          child: BlocBuilder<PembelianBloc, PembelianState>(
            builder: (context, state) {
              if (state is PembelianLoading) return const Center(child: CircularProgressIndicator());
              if (state is PembelianError) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(state.message),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => context.read<PembelianBloc>().add(LoadPembelian()),
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                );
              }
              if (state is PembelianLoaded) {
                if (state.list.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.shopping_bag_outlined,
                            size: 64, color: AppTheme.neutralGrey.withValues(alpha: 0.3)),
                        const SizedBox(height: 16),
                        Text('Belum ada pembelian', style: TextStyle(color: AppTheme.neutralGrey)),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _showAddChoiceDialog,
                          icon: const Icon(Icons.add),
                          label: const Text('Tambah Pembelian'),
                        ),
                      ],
                    ),
                  );
                }

                final filtered = _searchQuery.isEmpty
                    ? state.list
                    : state.list
                        .where((p) =>
                            (p.namaSupplier ?? '').toLowerCase().contains(_searchQuery))
                        .toList();

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Card(
                    child: SizedBox(
                      width: double.infinity,
                      child: DataTable(
                        columnSpacing: 20,
                        headingRowHeight: 44,
                        dataRowMinHeight: 52,
                        dataRowMaxHeight: 60,
                        headingRowColor: WidgetStateProperty.all(
                          Theme.of(context).colorScheme.surface,
                        ),
                        columns: const [
                          DataColumn(label: Text('SUPPLIER', style: TextStyle(fontWeight: FontWeight.w700))),
                          DataColumn(label: Text('TANGGAL', style: TextStyle(fontWeight: FontWeight.w700))),
                          DataColumn(
                            label: Text('TOTAL', style: TextStyle(fontWeight: FontWeight.w700)),
                            numeric: true,
                          ),
                          DataColumn(label: Text('AKSI', style: TextStyle(fontWeight: FontWeight.w700))),
                        ],
                        rows: filtered.map((p) {
                          return DataRow(
                            cells: [
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: AppTheme.lightGreen,
                                      child: const Icon(Icons.shopping_bag,
                                          color: AppTheme.primaryGreen, size: 16),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      p.namaSupplier ?? 'Supplier Tidak Diketahui',
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(
                                Text(
                                  p.createdAt != null ? _dateFormat.format(p.createdAt!) : '-',
                                  style: TextStyle(fontSize: 13, color: AppTheme.neutralGrey),
                                ),
                              ),
                              DataCell(
                                Text(
                                  _currency.format(p.totalHarga),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TextButton(
                                      onPressed: () => _showDetailDialog(p),
                                      child: const Text('Detail'),
                                    ),
                                    TextButton(
                                      onPressed: () => _openEditForm(p),
                                      child: const Text('Edit'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                );
              }
              return const SizedBox();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildToolbar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).colorScheme.surface : Colors.white,
        border: Border(
          bottom: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE5E7EB)),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 260,
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Cari supplier...',
                prefixIcon: Icon(Icons.search, size: 18),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
            ),
          ),
          const Spacer(),
          // Badge pending
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.pending_actions),
                tooltip: 'Pending Pembelian',
                onPressed: () async {
                  await _navKey.currentState!.push(
                    MaterialPageRoute(builder: (_) => const PendingPembelianPage()),
                  );
                  if (!mounted) return;
                  if (context.mounted) {
                    context.read<PembelianBloc>().add(LoadPembelian());
                  }
                  _loadPendingCount();
                },
              ),
              if (_pendingCount > 0)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: AppTheme.warningRed,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      _pendingCount > 9 ? '9+' : '$_pendingCount',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _showAddChoiceDialog,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Tambah'),
            style: ElevatedButton.styleFrom(visualDensity: VisualDensity.compact),
          ),
        ],
      ),
    );
  }
}

// ─── Detail Widget (dalam Dialog) ─────────────────────────────────────────────

class _PembelianDetailWidget extends StatelessWidget {
  final Pembelian pembelian;
  final void Function(Pembelian) onEdit;
  final Future<void> Function(Pembelian, List<ItemPembelian>) onPrint;
  final Future<void> Function(Pembelian, List<ItemPembelian>) onShare;

  const _PembelianDetailWidget({
    required this.pembelian,
    required this.onEdit,
    required this.onPrint,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'id', symbol: 'Rp', decimalDigits: 0);
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: FutureBuilder<List<ItemPembelian>>(
        future: context.read<PembelianBloc>().repository.getItemsByPembelianId(pembelian.id!),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data ?? [];

          return Column(
            children: [
              // Header Custom
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                ),
                child: Row(
                  children: [
                    Text(
                      'Detail Pembelian #${pembelian.id}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(context),
                      splashRadius: 20,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Info header
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    pembelian.namaSupplier ?? 'Supplier Tidak Diketahui',
                                    style: const TextStyle(
                                      fontSize: 16, fontWeight: FontWeight.w700,
                                      color: AppTheme.primaryGreen,
                                    ),
                                  ),
                                  if (pembelian.createdAt != null)
                                    Text(
                                      dateFormat.format(pembelian.createdAt!),
                                      style: TextStyle(fontSize: 12, color: AppTheme.neutralGrey),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text('Item', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      if (items.isEmpty)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: Text('Tidak ada item')),
                          ),
                        )
                      else
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
                                    currency.format(item.subtotal),
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      // Total
                      Card(
                        color: AppTheme.lightGreen,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total Pembelian',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                              Text(
                                currency.format(pembelian.totalHarga),
                                style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Action buttons
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => onEdit(pembelian),
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Edit'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => onShare(pembelian, items),
                        icon: const Icon(Icons.share, size: 16),
                        label: const Text('Share'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => onPrint(pembelian, items),
                        icon: const Icon(Icons.print, size: 16),
                        label: const Text('Cetak'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
