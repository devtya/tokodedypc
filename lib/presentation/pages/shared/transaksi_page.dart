import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_theme.dart';
import '../../blocs/transaksi/transaksi_bloc.dart';
import '../../blocs/transaksi/transaksi_event.dart';
import '../../blocs/transaksi/transaksi_state.dart';
import 'transaksi_detail_page.dart';

class TransaksiPage extends StatefulWidget {
  const TransaksiPage({super.key});

  @override
  State<TransaksiPage> createState() => _TransaksiPageState();
}

class _TransaksiPageState extends State<TransaksiPage> {
  final _currency = NumberFormat.currency(locale: 'id', symbol: 'Rp', decimalDigits: 0);
  final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    context.read<TransaksiBloc>().add(LoadTransaksi());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Toolbar / Header ──────────────────────────────────────
        _buildToolbar(),
        // ── Content ───────────────────────────────────────────────
        Expanded(
          child: BlocBuilder<TransaksiBloc, TransaksiState>(
            builder: (context, state) {
              return state.maybeWhen(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (message) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(message),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => context.read<TransaksiBloc>().add(LoadTransaksi()),
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                ),
                loaded: (transaksiList) {
                  final filtered = _searchQuery.isEmpty
                      ? transaksiList
                      : transaksiList
                          .where((t) =>
                              (t.id ?? '').toLowerCase().contains(_searchQuery) ||
                              t.status.toLowerCase().contains(_searchQuery))
                          .toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.receipt_long_outlined,
                              size: 64, color: AppTheme.neutralGrey.withValues(alpha: 0.3)),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isEmpty ? 'Belum ada transaksi' : 'Tidak ada hasil',
                            style: TextStyle(color: AppTheme.neutralGrey),
                          ),
                        ],
                      ),
                    );
                  }

                  return _buildTable(filtered);
                },
                orElse: () => const SizedBox(),
              );
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
            width: 280,
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Cari ID atau status...',
                prefixIcon: Icon(Icons.search, size: 18),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => context.read<TransaksiBloc>().add(LoadTransaksi()),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(List transaksiList) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header stats
          Row(
            children: [
              _StatChip(
                label: 'Total',
                value: '${transaksiList.length}',
                color: AppTheme.primaryGreen,
              ),
              const SizedBox(width: 8),
              _StatChip(
                label: 'Hutang',
                value: '${transaksiList.where((t) => t.status == 'hutang').length}',
                color: AppTheme.warningOrange,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Table
          Card(
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
                  DataColumn(label: Text('ID', style: TextStyle(fontWeight: FontWeight.w700))),
                  DataColumn(label: Text('TANGGAL', style: TextStyle(fontWeight: FontWeight.w700))),
                  DataColumn(label: Text('STATUS', style: TextStyle(fontWeight: FontWeight.w700))),
                  DataColumn(
                    label: Text('TOTAL', style: TextStyle(fontWeight: FontWeight.w700)),
                    numeric: true,
                  ),
                  DataColumn(label: Text('', style: TextStyle(fontWeight: FontWeight.w700))),
                ],
                rows: transaksiList.map((t) {
                  final isHutang = t.status == 'hutang';
                  return DataRow(
                    cells: [
                      DataCell(
                        Text(
                          '#${(t.id ?? '').toString().substring(0, 8)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          t.createdAt != null ? _dateFormat.format(t.createdAt!) : '-',
                          style: TextStyle(fontSize: 13, color: AppTheme.neutralGrey),
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isHutang
                                ? AppTheme.warningOrange.withValues(alpha: 0.12)
                                : AppTheme.primaryGreen.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isHutang ? 'Hutang' : 'Lunas',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isHutang ? AppTheme.warningOrange : AppTheme.primaryGreen,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          _currency.format(t.totalHarga),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataCell(
                        TextButton(
                          onPressed: () => _showDetail(t.id!),
                          child: const Text('Detail'),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDetail(String transaksiId) {
    showDialog(
      context: context,
      builder: (_) => BlocProvider(
        create: (_) => sl<TransaksiBloc>(),
        child: Dialog(
          insetPadding: const EdgeInsets.all(40),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            width: 560,
            height: 640,
            child: TransaksiDetailPage(transaksiId: transaksiId),
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: color)),
          const SizedBox(width: 6),
          Text(
            value,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}
