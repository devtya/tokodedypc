import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import '../../widgets/barcode_scanner_widget.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/produk.dart';
import '../../../domain/usecases/produk/get_all_produk.dart';
import '../../blocs/produk/produk_bloc.dart';
import '../../blocs/produk/produk_event.dart';
import '../../blocs/produk/produk_state.dart';
import '../../../core/di/injection.dart';
import '../../blocs/stok/stok_bloc.dart';
import '../../widgets/produk_log_dialog.dart';
import '../../widgets/sync_indicator.dart';
import 'produk_form_page.dart';
import 'stok_page.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';

String _formatRp(double val) {
  final intPart = val.toInt().toString();
  final formatted = intPart.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (m) => '.',
  );
  return 'Rp$formatted';
}

enum _StockFilter { all, lowStock, outOfStock, archived }

class ProdukPage extends StatefulWidget {
  const ProdukPage({super.key});

  @override
  State<ProdukPage> createState() => _ProdukPageState();
}

enum SidePanelMode { form, stok, riwayat }

class _ProdukPageState extends State<ProdukPage> {
  final _searchController = TextEditingController();
  List<Produk> _allProducts = [];
  List<Produk> _filteredProducts = [];
  String? _selectedKategori;
  _StockFilter _stockFilter = _StockFilter.all;
  bool _loadingProducts = true;

  int? _sortColumnIndex;
  bool _sortAscending = true;
  final Set<String> _selectedIds = {};

  bool _showSidePanel = false;
  SidePanelMode _sidePanelMode = SidePanelMode.form;
  Produk? _selectedProdukForEdit;

  @override
  void initState() {
    super.initState();
    context.read<ProdukBloc>().add(LoadProduk());
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    try {
      final products = await sl<GetAllProduk>().call();
      
      // Memberikan jeda singkat agar animasi transisi menu bisa selesai dengan mulus
      // dan skeleton loading bisa terlihat sebelum merender ratusan baris tabel.
      await Future.delayed(const Duration(milliseconds: 300));

      if (mounted) {
        setState(() {
          _allProducts = products;
          _applyFilters();
          _loadingProducts = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingProducts = false);
    }
  }

  void _applyFilters() {
    final q = _searchController.text.toLowerCase();
    
    setState(() {
      _filteredProducts = _allProducts.where((p) {
        final matchQuery = q.isEmpty ||
            p.nama.toLowerCase().contains(q) ||
            (p.barcode?.toLowerCase().contains(q) ?? false);

        final matchKategori = _selectedKategori == null ||
            _selectedKategori == 'Semua' ||
            p.kategori == _selectedKategori;

        final stokMin = p.stokMinimum ?? 0;
        bool matchStock;
        switch (_stockFilter) {
          case _StockFilter.all:
            matchStock = !p.isArchived;
          case _StockFilter.lowStock:
            matchStock = !p.isArchived && p.stok > 0 && p.stok <= stokMin;
          case _StockFilter.outOfStock:
            matchStock = !p.isArchived && p.stok == 0;
          case _StockFilter.archived:
            matchStock = p.isArchived;
        }

        return matchQuery && matchKategori && matchStock;
      }).toList();

      _sortProducts();
      _selectedIds.clear();
    });
  }

  void _sortProducts() {
    if (_sortColumnIndex == null) return;
    setState(() {
      _filteredProducts.sort((a, b) {
        int result;
        switch (_sortColumnIndex) {
          case 0:
            result = a.nama.toLowerCase().compareTo(b.nama.toLowerCase());
          case 1:
            result = a.hargaJual.compareTo(b.hargaJual);
          case 2:
            result = a.hargaBeli.compareTo(b.hargaBeli);
          case 3:
            result = a.stok.compareTo(b.stok);
          default:
            return 0;
        }
        return _sortAscending ? result : -result;
      });
    });
  }

  void _onSort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
    });
    _sortProducts();
  }

  List<String> get _kategoriList {
    final set = <String>{};
    for (final p in _allProducts) {
      if (p.kategori != null && p.kategori!.isNotEmpty) {
        set.add(p.kategori!);
      }
    }
    final sorted = set.toList()..sort();
    return ['Semua', ...sorted];
  }

  Future<void> _openScanner() async {
    final barcode = await showBarcodeScannerDialog(context);
    if (barcode != null) {
      _searchController.text = barcode;
      _applyFilters();
    }
  }

  Color _stockColor(int stok, int? stokMin) {
    final min = stokMin ?? 0;
    if (stok == 0) return AppTheme.warningRed;
    if (stok <= min) return AppTheme.warningOrange;
    return AppTheme.primaryGreen;
  }

  String _stockLabel(int stok, int? stokMin, String? satuan) {
    final s = satuan ?? 'pcs';
    if (stok == 0) return 'Habis';
    final min = stokMin ?? 0;
    if (stok <= min) return 'Stok: $stok $s';
    return '$stok $s';
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final isAdmin = authState is Authenticated && authState.user.isOwner;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Daftar Produk'),
            actions: [
              const SyncIndicator(),
              if (isAdmin) ...[
                IconButton(
                  icon: const Icon(Icons.inventory_2_outlined),
                  tooltip: 'Stok Minimum Global',
                  onPressed: () => _openGlobalStockSettings(),
                ),
                if (_selectedIds.isEmpty)
                  IconButton(
                    icon: const Icon(Icons.add),
                    tooltip: 'Tambah Produk',
                    onPressed: () => _openForm(),
                  ),
              ],
            ],
          ),
          body: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    _buildSearchBar(),
                    _buildFilterRow(isAdmin),
                    Expanded(
                      child: BlocListener<ProdukBloc, ProdukState>(
                        listener: (context, state) {
                          state.maybeWhen(
                            operationSuccess: (message, newId) {
                              _loadProducts();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(message)),
                              );
                            },
                            error: (message) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(message),
                                  backgroundColor: AppTheme.warningRed,
                                ),
                              );
                            },
                            orElse: () {},
                          );
                        },
                        child: _buildDataTable(isAdmin),
                      ),
                    ),
                    if (_selectedIds.isNotEmpty) _buildBatchActionBar(),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                width: _showSidePanel ? MediaQuery.of(context).size.width * 0.38 : 0,
                decoration: BoxDecoration(
                  border: Border(left: BorderSide(color: Theme.of(context).dividerColor)),
                  boxShadow: [
                    if (_showSidePanel)
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(-5, 0),
                      ),
                  ],
                ),
                child: _showSidePanel
                    ? ClipRect(
                        child: _buildSidePanelContent(isAdmin),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Cari produk...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_searchController.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _applyFilters();
                  },
                ),
              IconButton(
                icon: const Icon(Icons.qr_code_scanner),
                onPressed: _openScanner,
              ),
            ],
          ),
        ),
        onChanged: (_) => _applyFilters(),
      ),
    );
  }

  Widget _buildFilterRow(bool isAdmin) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          SizedBox(
            width: 180,
            child: DropdownButtonFormField<String>(
              initialValue: _selectedKategori ?? 'Semua',
              decoration: const InputDecoration(
                labelText: 'Kategori',
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                isDense: true,
              ),
              items: _kategoriList.map((k) {
                return DropdownMenuItem(
                  value: k,
                  child: Text(k, style: const TextStyle(fontSize: 13)),
                );
              }).toList(),
              onChanged: (val) {
                setState(() => _selectedKategori = val == 'Semua' ? null : val);
                _applyFilters();
              },
            ),
          ),
          const SizedBox(width: 12),
          SegmentedButton<_StockFilter>(
            segments: const [
              ButtonSegment(value: _StockFilter.all, label: Text('Semua')),
              ButtonSegment(value: _StockFilter.lowStock, label: Text('Stok Tipis')),
              ButtonSegment(value: _StockFilter.outOfStock, label: Text('Habis')),
              ButtonSegment(value: _StockFilter.archived, label: Text('Arsip')),
            ],
            selected: {_stockFilter},
            onSelectionChanged: (val) {
              setState(() => _stockFilter = val.first);
              _applyFilters();
            },
            style: const ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const Spacer(),
          Text(
            '${_filteredProducts.length} produk',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable(bool isAdmin) {
    if (_loadingProducts) {
      return _buildSkeletonLoading(isAdmin);
    }

    if (_filteredProducts.isEmpty) {
      return Center(
        child: Text(
          _searchController.text.isNotEmpty
              ? 'Produk "${_searchController.text}" tidak ditemukan'
              : 'Belum ada produk',
          style: TextStyle(color: AppTheme.neutralGrey),
        ),
      );
    }

    return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
          sortColumnIndex: _sortColumnIndex,
          sortAscending: _sortAscending,
          columnSpacing: 20,
          dataRowMinHeight: 44,
          dataRowMaxHeight: 48,
          headingRowHeight: 44,
          showCheckboxColumn: isAdmin,
          onSelectAll: isAdmin
              ? (val) {
                  setState(() {
                    if (val == true) {
                      _selectedIds
                          .addAll(_filteredProducts.map((p) => p.id!));
                    } else {
                      _selectedIds.clear();
                    }
                  });
                }
              : null,
          columns: [
            DataColumn(
              label: const Text('Nama', style: TextStyle(fontWeight: FontWeight.w600)),
              onSort: _onSort,
            ),
            DataColumn(
              label: const Text('Harga Jual', style: TextStyle(fontWeight: FontWeight.w600)),
              numeric: true,
              onSort: _onSort,
            ),
            if (!_showSidePanel)
              DataColumn(
                label: const Text('Harga Beli', style: TextStyle(fontWeight: FontWeight.w600)),
                numeric: true,
                onSort: _onSort,
              ),
            DataColumn(
              label: const Text('Stok', style: TextStyle(fontWeight: FontWeight.w600)),
              numeric: true,
              onSort: _onSort,
            ),

            if (!_showSidePanel)
              const DataColumn(label: Text('Terakhir Update', style: TextStyle(fontWeight: FontWeight.w600))),
            const DataColumn(label: Text('Aksi', style: TextStyle(fontWeight: FontWeight.w600))),
          ],
          rows: _filteredProducts.map((produk) {
            final isSelected = _selectedIds.contains(produk.id);
            return DataRow(
              selected: isSelected,
              onSelectChanged: isAdmin
                  ? (val) {
                      setState(() {
                        if (val == true) {
                          _selectedIds.add(produk.id!);
                        } else {
                          _selectedIds.remove(produk.id);
                        }
                      });
                    }
                  : null,
              cells: [
                DataCell(
                  Text(
                    produk.nama,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      decoration:
                          produk.isArchived ? TextDecoration.lineThrough : null,
                      color: produk.isArchived ? AppTheme.neutralGrey : null,
                    ),
                  ),
                  onTap: isAdmin ? () => _openForm(produk: produk) : null,
                ),
                DataCell(
                  Text(
                    _formatRp(produk.hargaJual),
                    style: const TextStyle(
                      color: AppTheme.primaryGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: isAdmin ? () => _openForm(produk: produk) : null,
                ),
                if (!_showSidePanel)
                  DataCell(
                    Text(_formatRp(produk.hargaBeli)),
                    onTap: isAdmin ? () => _openForm(produk: produk) : null,
                  ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _stockColor(produk.stok, produk.stokMinimum)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _stockLabel(produk.stok, produk.stokMinimum, produk.satuan),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _stockColor(produk.stok, produk.stokMinimum),
                      ),
                    ),
                  ),
                  onTap: isAdmin ? () => _openForm(produk: produk) : null,
                ),
                if (!_showSidePanel)
                  DataCell(
                    Text(
                      produk.updatedAt != null 
                          ? DateFormat('dd MMM yyyy, HH:mm').format(produk.updatedAt!) 
                          : '-',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    onTap: isAdmin ? () => _openForm(produk: produk) : null,
                  ),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _iconBtn(Icons.inventory_2_outlined, 'Stok', () => _openStok(produk)),
                      _iconBtn(Icons.info_outline, 'Riwayat', () => _showProdukLog(produk, isAdmin)),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSkeletonLoading(bool isAdmin) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey.shade800 : Colors.grey.shade300;
    final highlightColor = isDark ? Colors.grey.shade700 : Colors.grey.shade100;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: DataTable(
          columnSpacing: 20,
          dataRowMinHeight: 44,
          dataRowMaxHeight: 48,
          headingRowHeight: 44,
          showCheckboxColumn: isAdmin,
          columns: [
            const DataColumn(label: Text('Nama', style: TextStyle(fontWeight: FontWeight.w600))),
            const DataColumn(label: Text('Harga Jual', style: TextStyle(fontWeight: FontWeight.w600)), numeric: true),
            if (!_showSidePanel)
              const DataColumn(label: Text('Harga Beli', style: TextStyle(fontWeight: FontWeight.w600)), numeric: true),
            const DataColumn(label: Text('Stok', style: TextStyle(fontWeight: FontWeight.w600)), numeric: true),
            if (!_showSidePanel)
              const DataColumn(label: Text('Terakhir Update', style: TextStyle(fontWeight: FontWeight.w600))),
            const DataColumn(label: Text('Aksi', style: TextStyle(fontWeight: FontWeight.w600))),
          ],
          rows: List.generate(
            10,
            (index) => DataRow(
              cells: [
                DataCell(Container(width: 180, height: 16, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)))),
                DataCell(Container(width: 80, height: 16, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)))),
                if (!_showSidePanel)
                  DataCell(Container(width: 80, height: 16, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)))),
                DataCell(Container(width: 50, height: 16, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)))),
                if (!_showSidePanel)
                  DataCell(Container(width: 120, height: 16, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)))),
                DataCell(Container(width: 70, height: 16, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon, String tooltip, VoidCallback onPressed) {
    return IconButton(
      icon: Icon(icon, size: 18),
      tooltip: tooltip,
      onPressed: onPressed,
      padding: const EdgeInsets.all(4),
      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildBatchActionBar() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            '${_selectedIds.length} dipilih',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: () {
              for (final id in _selectedIds.toList()) {
                context.read<ProdukBloc>().add(ArchiveProdukEvent(id, true));
              }
              setState(() => _selectedIds.clear());
            },
            icon: const Icon(Icons.archive, size: 18),
            label: const Text('Arsipkan'),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: _showBatchDeleteConfirm,
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text('Hapus'),
            style: TextButton.styleFrom(foregroundColor: AppTheme.warningRed),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => setState(() => _selectedIds.clear()),
            child: const Text('Batal'),
          ),
        ],
      ),
    );
  }

  void _showBatchDeleteConfirm() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Produk'),
        content: Text(
          'Hapus ${_selectedIds.length} produk permanen? Tindakan ini tidak bisa dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              for (final id in _selectedIds.toList()) {
                context.read<ProdukBloc>().add(DeleteProdukEvent(id));
              }
              setState(() => _selectedIds.clear());
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.warningRed),
            child: const Text('Hapus Semua'),
          ),
        ],
      ),
    );
  }

  void _openForm({Produk? produk}) {
    setState(() {
      _selectedProdukForEdit = produk;
      _sidePanelMode = SidePanelMode.form;
      _showSidePanel = true;
    });
  }

  void _openStok(Produk produk) {
    setState(() {
      _selectedProdukForEdit = produk;
      _sidePanelMode = SidePanelMode.stok;
      _showSidePanel = true;
    });
  }

  void _showProdukLog(Produk produk, bool isAdmin) {
    setState(() {
      _selectedProdukForEdit = produk;
      _sidePanelMode = SidePanelMode.riwayat;
      _showSidePanel = true;
    });
  }

  Widget _buildSidePanelContent(bool isAdmin) {
    if (_sidePanelMode == SidePanelMode.form) {
      return BlocProvider.value(
        value: context.read<ProdukBloc>(),
        child: ProdukFormPage(
          key: ValueKey('form_${_selectedProdukForEdit?.id ?? 'new'}'),
          produk: _selectedProdukForEdit,
          isSidePanel: true,
          onCloseSidePanel: () {
            setState(() {
              _showSidePanel = false;
              _selectedProdukForEdit = null;
            });
          },
        ),
      );
    } else if (_sidePanelMode == SidePanelMode.stok && _selectedProdukForEdit != null) {
      return BlocProvider.value(
        value: sl<StokBloc>(),
        child: StokPage(
          key: ValueKey('stok_${_selectedProdukForEdit!.id}'),
          produk: _selectedProdukForEdit!,
          isSidePanel: true,
          onCloseSidePanel: () {
            setState(() {
              _showSidePanel = false;
              _selectedProdukForEdit = null;
            });
          },
        ),
      );
    } else if (_sidePanelMode == SidePanelMode.riwayat && _selectedProdukForEdit != null) {
      return ProdukLogDialog(
        key: ValueKey('riwayat_${_selectedProdukForEdit!.id}'),
        produk: _selectedProdukForEdit!,
        isAdmin: isAdmin,
        isSidePanel: true,
        onCloseSidePanel: () {
          setState(() {
            _showSidePanel = false;
            _selectedProdukForEdit = null;
          });
        },
        onEditTap: isAdmin ? () => _openForm(produk: _selectedProdukForEdit) : null,
      );
    }
    return const SizedBox.shrink();
  }

  void _openGlobalStockSettings() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Stok Minimum Global'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Batas peringatan stok tipis untuk semua produk',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: TextEditingController(text: '0'),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Jumlah Stok',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (ctx.mounted && mounted) {
                Navigator.pop(ctx);
                setState(() {});
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}
