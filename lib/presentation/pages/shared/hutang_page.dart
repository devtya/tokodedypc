import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_theme.dart';
import '../../blocs/hutang/hutang_bloc.dart';
import '../../blocs/hutang/hutang_event.dart';
import '../../blocs/hutang/hutang_state.dart';
import '../../blocs/transaksi/transaksi_bloc.dart';
import 'hutang_form_page.dart';
import 'transaksi_detail_page.dart';

class HutangPage extends StatefulWidget {
  const HutangPage({super.key});

  @override
  State<HutangPage> createState() => _HutangPageState();
}

class _HutangPageState extends State<HutangPage> {
  final _currency = NumberFormat.currency(locale: 'id', symbol: 'Rp', decimalDigits: 0);
  final _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    context.read<HutangBloc>().add(LoadHutang());
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
    return BlocConsumer<HutangBloc, HutangState>(
      listener: (context, state) {
        if (state is HutangSuccess) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.message)));
        }
        if (state is HutangError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppTheme.warningRed,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is HutangLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is HutangLoaded) {
          return Column(
            children: [
              // ── Toolbar ───────────────────────────────────────────
              _buildToolbar(state),
              // ── Summary bar ───────────────────────────────────────
              _buildSummaryBar(state),
              // ── List ─────────────────────────────────────────────
              Expanded(child: _buildTable(state)),
            ],
          );
        }
        return const SizedBox();
      },
    );
  }

  Widget _buildToolbar(HutangLoaded state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filters = ['semua', 'belum_lunas', 'lunas'];
    final labels = ['Semua', 'Belum Lunas', 'Lunas'];

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
          // Filter chips
          ...List.generate(filters.length, (i) {
            final active = state.filterStatus == filters[i];
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(labels[i]),
                selected: active,
                onSelected: (_) =>
                    context.read<HutangBloc>().add(FilterHutang(filters[i])),
                selectedColor: AppTheme.accentGreen.withValues(alpha: 0.2),
                checkmarkColor: AppTheme.primaryGreen,
                visualDensity: VisualDensity.compact,
              ),
            );
          }),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () => _navKey.currentState!.push(
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: context.read<HutangBloc>(),
                  child: const HutangFormPage(),
                ),
              ),
            ),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Tambah Hutang'),
            style: ElevatedButton.styleFrom(
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBar(HutangLoaded state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: _SummaryCard(
              icon: Icons.account_balance_wallet_rounded,
              label: 'Total Piutang',
              value: _currency.format(state.totalPiutang),
              color: AppTheme.primaryGreen,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _SummaryCard(
              icon: Icons.warning_rounded,
              label: 'Belum Lunas',
              value: _currency.format(state.totalBelumLunas),
              color: AppTheme.warningOrange,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _SummaryCard(
              icon: Icons.check_circle_rounded,
              label: 'Sudah Lunas',
              value: _currency.format(state.totalPiutang - state.totalBelumLunas),
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(HutangLoaded state) {
    final list = state.filteredList;

    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.account_balance_wallet_outlined,
                size: 64, color: AppTheme.neutralGrey.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text('Tidak ada data hutang', style: TextStyle(color: AppTheme.neutralGrey)),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Card(
        child: SizedBox(
          width: double.infinity,
          child: DataTable(
            columnSpacing: 20,
            headingRowHeight: 44,
            dataRowMinHeight: 52,
            dataRowMaxHeight: 70,
            headingRowColor: WidgetStateProperty.all(Theme.of(context).colorScheme.surface),
            columns: const [
              DataColumn(label: Text('PELANGGAN', style: TextStyle(fontWeight: FontWeight.w700))),
              DataColumn(
                label: Text('JUMLAH', style: TextStyle(fontWeight: FontWeight.w700)),
                numeric: true,
              ),
              DataColumn(label: Text('TANGGAL', style: TextStyle(fontWeight: FontWeight.w700))),
              DataColumn(label: Text('JATUH TEMPO', style: TextStyle(fontWeight: FontWeight.w700))),
              DataColumn(label: Text('STATUS', style: TextStyle(fontWeight: FontWeight.w700))),
              DataColumn(label: Text('', style: TextStyle(fontWeight: FontWeight.w700))),
            ],
            rows: list.map((h) {
              final isLunas = h.status == 'lunas';
              return DataRow(
                cells: [
                  DataCell(
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(h.namaPelanggan, style: const TextStyle(fontWeight: FontWeight.w600)),
                        if (h.transaksiId != null)
                          TextButton(
                            onPressed: () => _showTransaksiDetail(h.transaksiId!),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text('Lihat transaksi', style: TextStyle(fontSize: 11)),
                          ),
                      ],
                    ),
                  ),
                  DataCell(
                    Text(
                      _currency.format(h.jumlah),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataCell(
                    Text(
                      h.createdAt != null ? _dateFormat.format(h.createdAt!) : '-',
                      style: TextStyle(fontSize: 13, color: AppTheme.neutralGrey),
                    ),
                  ),
                  DataCell(
                    h.tanggalJatuhTempo != null
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.warning_amber, size: 14, color: AppTheme.warningOrange),
                              const SizedBox(width: 4),
                              Text(
                                _dateFormat.format(h.tanggalJatuhTempo!),
                                style: TextStyle(fontSize: 13, color: AppTheme.warningOrange),
                              ),
                            ],
                          )
                        : Text('-', style: TextStyle(color: AppTheme.neutralGrey)),
                  ),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isLunas
                            ? AppTheme.primaryGreen.withValues(alpha: 0.12)
                            : AppTheme.warningOrange.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isLunas ? 'Lunas' : 'Belum Lunas',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isLunas ? AppTheme.primaryGreen : AppTheme.warningOrange,
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    isLunas
                        ? Icon(Icons.check, color: AppTheme.primaryGreen, size: 20)
                        : TextButton(
                            onPressed: () => _confirmLunas(h.id!),
                            child: const Text('Tandai Lunas'),
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

  void _showTransaksiDetail(String transaksiId) {
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

  void _confirmLunas(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tandai Lunas'),
        content: const Text('Konfirmasi hutang ini sudah dibayar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<HutangBloc>().add(LunasHutang(id));
            },
            child: const Text('Ya, Lunas'),
          ),
        ],
      ),
    );
  }
}

// ─── Summary Card ─────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: AppTheme.neutralGrey)),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
