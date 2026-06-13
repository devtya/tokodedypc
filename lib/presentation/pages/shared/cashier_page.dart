import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/pending_order.dart';
import '../../../domain/repositories/pending_order_repository.dart';
import '../../../domain/usecases/produk/get_all_produk.dart';
import '../../../domain/usecases/produk/search_produk.dart';
import '../../../domain/entities/produk.dart';
import '../../../domain/usecases/transaksi/buat_transaksi.dart';
import '../../../data/services/printer_service.dart';
import '../../../data/services/printer_settings.dart';
import '../../../data/services/receipt_generator.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/cashier/cashier_bloc.dart';
import '../../blocs/cashier/cashier_event.dart';
import '../../blocs/cashier/cashier_state.dart';
import '../../utils/dialog_utils.dart';
import 'printer_settings_page.dart';
import 'share_receipt_page.dart';

class CashierPage extends StatefulWidget {
  const CashierPage({super.key});

  @override
  State<CashierPage> createState() => _CashierPageState();
}

class _CashierPageState extends State<CashierPage> {
  final _currency = NumberFormat.currency(
    locale: 'id',
    symbol: 'Rp',
    decimalDigits: 0,
  );
  final _bayarController = TextEditingController();
  final _searchController = TextEditingController();
  final ScrollController _cartScrollController = ScrollController();

  // State for inline product search
  List<Produk> _products = [];
  bool _loadingProducts = true;
  int? _flashIndex;

  // Store last transaction data for printing
  List<CartItem>? _lastCartItems;
  double _lastTotalBayar = 0;
  double _lastKembalian = 0;
  final bool _isPrinting = false;
  bool _isProcessing = false;

  // Printer connection state
  bool _printerConnected = false;

  bool get _isKasir {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) return authState.user.isKasir;
    return false;
  }

  @override
  void initState() {
    super.initState();
    context.read<CashierBloc>().add(InitCashier());
    _checkPrinterConnection();
    _loadProducts();
  }

  @override
  void dispose() {
    _cartScrollController.dispose();
    _searchController.dispose();
    _bayarController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    if (!mounted) return;
    setState(() => _loadingProducts = true);
    try {
      final getAllProduk = sl<GetAllProduk>();
      final products = await getAllProduk();
      final activeProducts = products.where((p) => !p.isArchived).toList();
      if (mounted) {
        setState(() {
          _products = activeProducts;
          _loadingProducts = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingProducts = false);
    }
  }

  Future<void> _searchProducts(String query) async {
    if (!mounted) return;
    setState(() => _loadingProducts = true);
    try {
      List<Produk> results;
      if (query.isEmpty) {
        final getAllProduk = sl<GetAllProduk>();
        final all = await getAllProduk();
        results = all.where((p) => !p.isArchived).toList();
      } else {
        final searchProduk = sl<SearchProduk>();
        final searched = await searchProduk(query);
        results = searched.where((p) => !p.isArchived).toList();
      }
      if (mounted) {
        setState(() {
          _products = results;
          _loadingProducts = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingProducts = false);
    }
  }

  void _pilihProduk(Produk produk) {
    DialogUtils.showPilihSatuanDialog(
      context: context,
      produk: produk,
      isPembelian: false,
      onSelected: (id, namaProduk, satuanName, harga, satuanId, konversi) {
        DialogUtils.showQuantityDialog(
          context: context,
          namaProduk: '$namaProduk - $satuanName',
          onSubmitted: (qty) {
            context.read<CashierBloc>().add(
                  AddToCart(
                    produkId: id,
                    namaProduk: '$namaProduk - $satuanName',
                    hargaJual: harga,
                    hargaPokok: _isKasir ? 0.0 : produk.hargaBeli,
                    jumlah: qty,
                    satuan: satuanId,
                    konversi: konversi,
                  ),
                );
          },
        );
      },
    );
  }

  Future<void> _showBayarConfirmation(CashierReady data) async {
    if (_isProcessing) return;
    
    await _checkPrinterConnection();
    if (!mounted) return;
    
    double localBayar = data.totalSetelahDiskon;
    final bayarCtrl = TextEditingController(text: localBayar.toStringAsFixed(0));
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            double kembali = localBayar - data.totalSetelahDiskon;
            return AlertDialog(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Konfirmasi Pembayaran'),
                  Tooltip(
                    message: _printerConnected ? 'Printer Terhubung' : 'Printer Tidak Terhubung',
                    child: Icon(
                      Icons.print,
                      color: _printerConnected ? AppTheme.primaryGreen : AppTheme.warningRed,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _infoRow('Total', _currency.format(data.totalSetelahDiskon)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: bayarCtrl,
                      keyboardType: TextInputType.number,
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: 'Jumlah Bayar',
                        prefixText: 'Rp ',
                        suffixIcon: TextButton(
                          onPressed: () {
                            setDialogState(() {
                              localBayar = data.totalSetelahDiskon;
                              bayarCtrl.text = localBayar.toStringAsFixed(0);
                              bayarCtrl.selection = TextSelection.collapsed(offset: bayarCtrl.text.length);
                            });
                          },
                          child: const Text('Uang Pas'),
                        ),
                      ),
                      onChanged: (val) {
                        setDialogState(() {
                          localBayar = double.tryParse(val) ?? 0;
                        });
                      },
                      onSubmitted: (_) {
                        if (kembali >= 0) {
                          if (mounted) {
                            context.read<CashierBloc>().add(UpdateJumlahBayar(localBayar));
                          }
                          Navigator.pop(ctx, true);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [10000.0, 20000.0, 50000.0, 100000.0].map((amount) {
                        return OutlinedButton(
                          onPressed: () {
                            setDialogState(() {
                              localBayar = amount;
                              bayarCtrl.text = amount.toStringAsFixed(0);
                              bayarCtrl.selection = TextSelection.collapsed(offset: bayarCtrl.text.length);
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            minimumSize: Size.zero,
                          ),
                          child: Text(_currency.format(amount)),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          kembali < 0 ? 'Kurang:' : 'Kembalian:',
                          style: const TextStyle(fontSize: 16),
                        ),
                        Text(
                          _currency.format(kembali < 0 ? -kembali : kembali),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: kembali < 0 ? AppTheme.warningRed : AppTheme.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: kembali < 0
                      ? null
                      : () {
                          if (mounted) {
                            context.read<CashierBloc>().add(UpdateJumlahBayar(localBayar));
                          }
                          Navigator.pop(ctx, true);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Proses Bayar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed == true) {
      setState(() => _isProcessing = true);
      _lastCartItems = List.from(data.cart);
      _lastTotalBayar = localBayar;
      _lastKembalian = localBayar - data.totalSetelahDiskon;
      if (mounted) {
        context.read<CashierBloc>().add(BayarCashier());
      }
    }
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }



  Future<void> _checkPrinterConnection() async {
    try {
      final settings = sl<PrinterSettings>();
      if (settings.enabled) {
        final printer = sl<PrinterService>();
        _printerConnected = await printer.isConnected();
      } else {
        _printerConnected = false;
      }
    } catch (_) {
      _printerConnected = false;
    }
    if (mounted) setState(() {});
  }

  void _showPrinterBottomSheet() {
    _checkPrinterConnection();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Printer Thermal',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(
                    Icons.print,
                    color: _printerConnected
                        ? AppTheme.primaryGreen
                        : AppTheme.warningRed,
                  ),
                ],
              ),
              const Divider(),
              Row(
                children: [
                  Icon(
                    Icons.circle,
                    size: 10,
                    color: _printerConnected
                        ? AppTheme.primaryGreen
                        : AppTheme.warningRed,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _printerConnected ? 'Terhubung' : 'Tidak terhubung',
                    style: TextStyle(
                      color: _printerConnected
                          ? AppTheme.primaryGreen
                          : AppTheme.warningRed,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Printer menggunakan koneksi Network (HTTP) ke print_server.py.',
                style: TextStyle(fontSize: 13, color: AppTheme.neutralGrey),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const PrinterSettingsPage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.settings),
                  label: const Text('Pengaturan Printer'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Tutup'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }





  void _showDiskonDialog(int index, CartItem item) {
    final valueController = TextEditingController();
    int tipe = item.diskonTipe;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Diskon - ${item.namaProduk}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 0, label: Text('Tidak')),
                  ButtonSegment(value: 1, label: Text('%')),
                  ButtonSegment(value: 2, label: Text('Rp')),
                ],
                selected: {tipe},
                onSelectionChanged: (v) => setDialogState(() => tipe = v.first),
              ),
              const SizedBox(height: 12),
              if (tipe > 0)
                TextField(
                  controller: valueController,
                  decoration: InputDecoration(
                    labelText: tipe == 1 ? 'Persen (%)' : 'Nominal (Rp)',
                    hintText: tipe == 1 ? '10' : '5000',
                  ),
                  keyboardType: TextInputType.number,
                  onSubmitted: (_) {
                    final value = double.tryParse(valueController.text) ?? 0;
                    context.read<CashierBloc>().add(
                      SetDiskonItem(index, tipe, value),
                    );
                    Navigator.pop(ctx);
                  },
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                final value = double.tryParse(valueController.text) ?? 0;
                context.read<CashierBloc>().add(
                  SetDiskonItem(index, tipe, value),
                );
                Navigator.pop(ctx);
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void _showGlobalDiskonDialog(CashierReady data) {
    final valueController = TextEditingController();
    int tipe = data.globalDiskonTipe;
    if (data.globalDiskonValue > 0) {
      valueController.text = tipe == 1 
          ? data.globalDiskonValue.toStringAsFixed(0) 
          : data.globalDiskonValue.toStringAsFixed(0);
    }
    
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Diskon Global'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 0, label: Text('Tidak')),
                  ButtonSegment(value: 1, label: Text('%')),
                  ButtonSegment(value: 2, label: Text('Rp')),
                ],
                selected: {tipe},
                onSelectionChanged: (v) => setDialogState(() => tipe = v.first),
              ),
              const SizedBox(height: 12),
              if (tipe > 0)
                TextField(
                  controller: valueController,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: tipe == 1 ? 'Persen (%)' : 'Nominal (Rp)',
                    hintText: tipe == 1 ? '10' : '5000',
                  ),
                  keyboardType: TextInputType.number,
                  onSubmitted: (_) {
                    final value = double.tryParse(valueController.text) ?? 0;
                    context.read<CashierBloc>().add(
                      SetGlobalDiskon(tipe, value),
                    );
                    Navigator.pop(ctx);
                  },
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                final value = double.tryParse(valueController.text) ?? 0;
                context.read<CashierBloc>().add(
                  SetGlobalDiskon(tipe, value),
                );
                Navigator.pop(ctx);
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditJumlahDialog(int index, String namaProduk, int currentJumlah) {
    final controller = TextEditingController(text: currentJumlah.toString());
    controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: controller.text.length,
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Ubah Jumlah - $namaProduk'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Jumlah',
            hintText: 'Masukkan jumlah barang',
          ),
          onSubmitted: (value) {
            final newJumlah = int.tryParse(value) ?? 1;
            if (newJumlah > 0) {
              context.read<CashierBloc>().add(
                UpdateJumlahCart(index, newJumlah),
              );
            }
            Navigator.pop(ctx);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              final newJumlah = int.tryParse(controller.text) ?? 1;
              if (newJumlah > 0) {
                context.read<CashierBloc>().add(
                  UpdateJumlahCart(index, newJumlah),
                );
              }
              Navigator.pop(ctx);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showHutangDialog() {
    final namaController = TextEditingController();
    // Capture current cart data
    final state = context.read<CashierBloc>().state;
    if (state is CashierReady) {
      _lastCartItems = List.from(state.cart);
      _lastTotalBayar = state.totalSetelahDiskon;
      _lastKembalian = 0;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bayar Hutang'),
        content: TextField(
          controller: namaController,
          decoration: const InputDecoration(
            labelText: 'Nama Pelanggan',
            hintText: 'Masukkan nama pelanggan',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<CashierBloc>().add(
                BayarHutangCashier(namaController.text),
              );
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _savePending({bool exitAfterSave = false}) {
    final namaController = TextEditingController();
    final catatanController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Simpan Pending'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: namaController,
              decoration: const InputDecoration(labelText: 'Nama Pelanggan *'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: catatanController,
              decoration: const InputDecoration(labelText: 'Catatan'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              if (namaController.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              final cashierState = context.read<CashierBloc>().state;
              if (cashierState is! CashierReady) return;
              if (cashierState.cart.isEmpty) return;
              final repo = sl<PendingOrderRepository>();
              final pendingId = await repo.addPending(
                PendingOrder(
                                    namaPelanggan: namaController.text.trim(),
                  catatan: catatanController.text.trim().isEmpty
                      ? null
                      : catatanController.text.trim(),
                ),
              );
              for (final item in cashierState.cart) {
                await repo.addItem(
                  pendingId,
                  CartItemData(
                    produkId: item.produkId,
                    namaProduk: item.namaProduk,
                    hargaJual: item.hargaJual,
                    jumlah: item.jumlah,
                    diskonTipe: item.diskonTipe,
                    diskonValue: item.diskonValue,
                    subtotal: item.subtotal,
                  ),
                );
              }
              if (!mounted) return;
              context.read<CashierBloc>().add(InitCashier());
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Pending disimpan untuk ${namaController.text.trim()}',
                  ),
                ),
              );
              if (exitAfterSave) Navigator.pop(context);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
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
    return BlocConsumer<CashierBloc, CashierState>(
      listener: (context, state) async {
        setState(() => _isProcessing = false);
        if (state is CashierSuccess) {
          _bayarController.clear();
          await _checkPrinterConnection();

          final settings = sl<PrinterSettings>();
          final generator = ReceiptGenerator(
            namaToko: settings.namaToko,
            alamatToko: settings.alamatToko,
            kasir: '', 
          );
          final receipt = generator.fromTransaction(
            transaksiId: state.transaksiId,
            cartItems: _lastCartItems ?? [],
            totalBayar: _lastTotalBayar,
            kembalian: _lastKembalian,
          );

          if (context.mounted) {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ShareReceiptPage(receipt: receipt),
              ),
            );
          }

          _lastCartItems = null;
          if (context.mounted) {
            context.read<CashierBloc>().add(InitCashier());
          }
        } else if (state is CashierReady && state.highlightedIndex != null) {
          final idx = state.highlightedIndex!;
          _scrollToIndex(idx);
          setState(() => _flashIndex = idx);
          Future.delayed(const Duration(milliseconds: 1500), () {
            if (mounted && _flashIndex == idx) {
              setState(() => _flashIndex = null);
            }
          });
        } else if (state is CashierError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppTheme.warningRed,
            ),
          );
        }
      },
      builder: (context, state) {
        final data = _resolveCashierData(state);
        return Scaffold(
          // No AppBar — kita sudah punya TopBar di shell desktop
          body: Row(
            children: [
              // ══ PANEL KIRI: Cari Produk ══════════════════════════════
              Container(
                width: 420,
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white12
                          : const Color(0xFFE5E7EB),
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    // Search Bar
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'Cari atau scan produk... (Ctrl+F)',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    _searchProducts('');
                                  },
                                )
                              : null,
                          isDense: true,
                        ),
                        onChanged: (value) {
                          setState(() {});
                          _searchProducts(value);
                        },
                        onSubmitted: (value) {
                          if (value.isNotEmpty) {
                            final exactMatch = _products.where((p) => p.barcode == value).toList();
                            if (exactMatch.isNotEmpty) {
                              _pilihProduk(exactMatch.first);
                              _searchController.clear();
                              _searchProducts('');
                            } else if (_products.length == 1) {
                              _pilihProduk(_products.first);
                              _searchController.clear();
                              _searchProducts('');
                            }
                          }
                        },
                      ),
                    ),

                    // Pending Orders
                    _buildPendingSection(),

                    // Product List
                    Expanded(
                      child: _loadingProducts
                          ? const Center(child: CircularProgressIndicator())
                          : _products.isEmpty
                              ? const Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.search_off_rounded, size: 64, color: Colors.black12),
                                      SizedBox(height: 16),
                                      Text(
                                        'Produk tidak ditemukan',
                                        style: TextStyle(color: Colors.grey, fontSize: 14),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  padding: EdgeInsets.zero,
                                  itemCount: _products.length,
                                  itemBuilder: (context, index) {
                                    final produk = _products[index];
                                    final stokOk = produk.stok > 0;
                                    return ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: stokOk
                                            ? AppTheme.primaryGreen.withValues(alpha: 0.15)
                                            : AppTheme.neutralGrey.withValues(alpha: 0.15),
                                        child: Text(
                                          '${produk.stok}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: stokOk
                                                ? AppTheme.primaryGreen
                                                : AppTheme.neutralGrey,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      title: Text(
                                        produk.nama,
                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                      subtitle: Text(
                                        '${_currency.format(produk.hargaJual)} / ${produk.satuan}',
                                        style: TextStyle(color: AppTheme.neutralGrey, fontSize: 13),
                                      ),
                                      trailing: IconButton(
                                        icon: const Icon(
                                          Icons.add_circle,
                                          color: AppTheme.primaryGreen,
                                        ),
                                        onPressed: () => _pilihProduk(produk),
                                      ),
                                      onTap: () => _pilihProduk(produk),
                                    );
                                  },
                                ),
                    ),

                    // Info printer
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.print_rounded,
                            size: 14,
                            color: _printerConnected ? AppTheme.primaryGreen : AppTheme.neutralGrey,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _printerConnected ? 'Printer terhubung' : 'Printer tidak terhubung',
                            style: TextStyle(
                              fontSize: 12,
                              color: _printerConnected ? AppTheme.primaryGreen : AppTheme.neutralGrey,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: _showPrinterBottomSheet,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              minimumSize: Size.zero,
                            ),
                            child: const Text('Pengaturan', style: TextStyle(fontSize: 11)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ══ PANEL KANAN: Keranjang + Bayar ═══════════════════════
              Expanded(
                child: Column(
                  children: [
                    // Header Keranjang
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white12
                                : const Color(0xFFE5E7EB),
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.shopping_cart_rounded, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Keranjang (${data.cart.length} item)',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                          ),
                          const Spacer(),
                          if (data.cart.isNotEmpty)
                            TextButton.icon(
                              onPressed: () => context.read<CashierBloc>().add(InitCashier()),
                              icon: const Icon(Icons.delete_sweep_rounded, size: 16),
                              label: const Text('Kosongkan', style: TextStyle(fontSize: 12)),
                              style: TextButton.styleFrom(
                                foregroundColor: AppTheme.warningRed,
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                              ),
                            ),
                          TextButton.icon(
                            onPressed: data.cart.isEmpty ? null : _savePending,
                            icon: const Icon(Icons.pause_circle_outline_rounded, size: 16),
                            label: const Text('Pending', style: TextStyle(fontSize: 12)),
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.warningOrange,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Cart List
                    Expanded(child: _buildCartList(data)),

                    // Bottom Panel Bayar
                    _buildBottomPanel(data),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPendingSection() {
    // Placeholder — akan diisi dengan pending orders dari repository
    return const SizedBox.shrink();
  }

  void _scrollToIndex(int index) {
    if (!_cartScrollController.hasClients) return;
    // Estimate height of a cart item card (roughly 85 pixels)
    final offset = index * 85.0;
    _cartScrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  CashierReady _resolveCashierData(CashierState state) {
    if (state is CashierReady) return state;
    if (state is CashierError) {
      return CashierReady(cart: state.cart, jumlahBayar: state.jumlahBayar);
    }
    return const CashierReady();
  }

  Widget _buildCartList(CashierReady data) {
    if (data.cart.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.black12),
            SizedBox(height: 16),
            Text('Keranjang kosong', style: TextStyle(color: Colors.grey, fontSize: 15)),
            SizedBox(height: 8),
            Text(
              'Cari atau scan produk di panel kiri',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      controller: _cartScrollController,
      padding: const EdgeInsets.all(12),
      itemCount: data.cart.length,
      itemBuilder: (context, index) {
        final item = data.cart[index];
        final hasDiskon = item.diskonTipe != 0;
        final isFlashing = index == _flashIndex;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          margin: const EdgeInsets.only(bottom: 6),
          decoration: BoxDecoration(
            color: isFlashing 
                ? AppTheme.primaryGreen.withValues(alpha: 0.1) 
                : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isFlashing
                  ? AppTheme.primaryGreen
                  : (Theme.of(context).brightness == Brightness.dark
                      ? Colors.white12
                      : const Color(0xFFE5E7EB)),
              width: isFlashing ? 2 : 1,
            ),
            boxShadow: isFlashing
                ? [
                    BoxShadow(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    )
                  ]
                : [],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                // Nama + harga
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.namaProduk,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            _currency.format(item.hargaJual),
                            style: TextStyle(color: AppTheme.primaryGreen, fontSize: 12),
                          ),
                          if (hasDiskon) ...
                            [
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppTheme.warningRed.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Diskon ${item.diskonTipe == 1 ? "${item.diskonValue.toStringAsFixed(0)}%" : _currency.format(item.diskonValue)}',
                                  style: TextStyle(fontSize: 10, color: AppTheme.warningRed, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Qty controls
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, size: 20),
                      onPressed: () => context.read<CashierBloc>().add(UpdateJumlahCart(index, item.jumlah - 1)),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: () => _showEditJumlahDialog(index, item.namaProduk, item.jumlah),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.border),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${item.jumlah}',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, size: 20),
                      onPressed: () => context.read<CashierBloc>().add(UpdateJumlahCart(index, item.jumlah + 1)),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),

                const SizedBox(width: 12),

                // Subtotal
                SizedBox(
                  width: 90,
                  child: Text(
                    _currency.format(item.subtotal),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    textAlign: TextAlign.right,
                  ),
                ),

                const SizedBox(width: 4),

                // Actions
                IconButton(
                  icon: const Icon(Icons.discount_rounded, size: 18),
                  tooltip: hasDiskon ? 'Ubah Diskon' : 'Tambah Diskon',
                  color: hasDiskon ? AppTheme.warningRed : AppTheme.neutralGrey,
                  onPressed: () => _showDiskonDialog(index, item),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  tooltip: 'Hapus',
                  color: AppTheme.warningRed,
                  onPressed: () => context.read<CashierBloc>().add(RemoveFromCart(index)),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomPanel(CashierReady data) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).colorScheme.surfaceContainer : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white12 : const Color(0xFFE5E7EB),
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Total row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('Total', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => _showGlobalDiskonDialog(data),
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Icon(
                        Icons.discount_rounded,
                        size: 18,
                        color: data.globalDiskonValue > 0 ? AppTheme.warningRed : AppTheme.neutralGrey,
                      ),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (data.totalDiskon > 0)
                    Text(
                      _currency.format(data.total),
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.neutralGrey,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  Text(
                    _currency.format(data.totalSetelahDiskon),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryGreen,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (data.totalDiskon > 0 || data.globalDiskonValue > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.warningRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Diskon Item: ${_currency.format(data.totalDiskon)}',
                      style: TextStyle(fontSize: 11, color: AppTheme.warningRed, fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (data.globalDiskonValue > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.warningRed.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Diskon Global: ${_currency.format(data.total - data.totalDiskon - data.totalSetelahDiskon)}',
                        style: TextStyle(fontSize: 11, color: AppTheme.warningRed, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          const SizedBox(height: 16),
          // Action buttons
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: data.cart.isEmpty ? null : _showHutangDialog,
                icon: const Icon(Icons.book_rounded, size: 18),
                label: const Text('Catat Hutang'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: data.cart.isEmpty ? null : () => _showBayarConfirmation(data),
                  icon: _isPrinting
                      ? const SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.payments_rounded, size: 20),
                  label: Text(
                    _isPrinting ? 'Memproses...' : 'Bayar Sekarang',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


