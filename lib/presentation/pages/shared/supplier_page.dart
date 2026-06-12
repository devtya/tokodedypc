import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/supplier.dart';
import '../../blocs/supplier/supplier_bloc.dart';
import '../../blocs/supplier/supplier_event.dart';
import '../../blocs/supplier/supplier_state.dart';

class SupplierPage extends StatefulWidget {
  final bool isPicking;

  const SupplierPage({super.key, this.isPicking = false});

  @override
  State<SupplierPage> createState() => _SupplierPageState();
}

class _SupplierPageState extends State<SupplierPage> {
  final _searchController = TextEditingController();
  // Panel kanan: null = kosong, Supplier? = edit form, isNew = tambah form
  Supplier? _panelSupplier;
  bool _showPanel = false;

  @override
  void initState() {
    super.initState();
    context.read<SupplierBloc>().add(LoadSupplier());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openAddPanel() {
    setState(() {
      _panelSupplier = null;
      _showPanel = true;
    });
  }

  void _openEditPanel(Supplier supplier) {
    setState(() {
      _panelSupplier = supplier;
      _showPanel = true;
    });
  }

  void _closePanel() {
    setState(() {
      _showPanel = false;
      _panelSupplier = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SupplierBloc, SupplierState>(
      listener: (context, state) {
        if (state is SupplierOperationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
          _closePanel();
        }
        if (state is SupplierError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppTheme.warningRed,
            ),
          );
        }
      },
      builder: (context, state) {
        return Column(
          children: [
            // ── Toolbar ─────────────────────────────────────────────────
            _buildToolbar(),
            // ── Body (list + optional panel) ────────────────────────────
            Expanded(
              child: Row(
                children: [
                  // ── List area ─────────────────────────────────────────
                  Expanded(
                    flex: _showPanel ? 3 : 1,
                    child: _buildList(state),
                  ),
                  // ── Side panel: form tambah/edit ───────────────────────
                  if (_showPanel) ...[
                    VerticalDivider(width: 1, color: Colors.black12),
                    SizedBox(
                      width: 380,
                      child: _SupplierFormPanel(
                        supplier: _panelSupplier,
                        onClose: _closePanel,
                        onSaved: (supplier) {
                          if (_panelSupplier == null) {
                            context.read<SupplierBloc>().add(AddSupplierEvent(supplier));
                          } else {
                            context.read<SupplierBloc>().add(UpdateSupplierEvent(supplier));
                          }
                          if (widget.isPicking) {
                            Navigator.pop(context, supplier);
                          }
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
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
              onChanged: (value) {
                if (value.isEmpty) {
                  context.read<SupplierBloc>().add(LoadSupplier());
                } else {
                  context.read<SupplierBloc>().add(SearchSupplierEvent(value));
                }
              },
            ),
          ),
          const Spacer(),
          if (!widget.isPicking)
            ElevatedButton.icon(
              onPressed: _openAddPanel,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Tambah Supplier'),
              style: ElevatedButton.styleFrom(visualDensity: VisualDensity.compact),
            ),
        ],
      ),
    );
  }

  Widget _buildList(SupplierState state) {
    if (state is SupplierLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state is SupplierLoaded) {
      final list = state.supplierList;
      if (list.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.store_outlined, size: 64, color: AppTheme.neutralGrey.withValues(alpha: 0.3)),
              const SizedBox(height: 16),
              Text('Belum ada supplier', style: TextStyle(color: AppTheme.neutralGrey)),
              const SizedBox(height: 16),
              if (!widget.isPicking)
                ElevatedButton.icon(
                  onPressed: _openAddPanel,
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah Supplier'),
                ),
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
              dataRowMaxHeight: 60,
              headingRowColor:
                  WidgetStateProperty.all(Theme.of(context).colorScheme.surface),
              columns: [
                const DataColumn(
                  label: Text('NAMA', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
                const DataColumn(
                  label: Text('TELEPON', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
                const DataColumn(
                  label: Text('ALAMAT', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
                if (!widget.isPicking)
                  const DataColumn(
                    label: Text('AKSI', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
              ],
              rows: list.map((supplier) {
                return DataRow(
                  cells: [
                    DataCell(
                      Text(supplier.nama, style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    DataCell(
                      Text(supplier.telepon ?? '-', style: TextStyle(color: AppTheme.neutralGrey)),
                    ),
                    DataCell(
                      Text(
                        supplier.alamat ?? '-',
                        style: TextStyle(color: AppTheme.neutralGrey),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (!widget.isPicking)
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_rounded, size: 18),
                              color: AppTheme.accentGreen,
                              tooltip: 'Edit',
                              onPressed: () => _openEditPanel(supplier),
                              visualDensity: VisualDensity.compact,
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_rounded, size: 18),
                              color: AppTheme.warningRed,
                              tooltip: 'Hapus',
                              onPressed: () => _confirmDelete(supplier),
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                      )
                    else
                      DataCell(
                        TextButton(
                          onPressed: () => Navigator.pop(context, supplier),
                          child: const Text('Pilih'),
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
    return const SizedBox.shrink();
  }

  void _confirmDelete(Supplier supplier) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Supplier'),
        content: Text('Yakin ingin menghapus "${supplier.nama}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              context.read<SupplierBloc>().add(DeleteSupplierEvent(supplier.id!));
              Navigator.pop(ctx);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ─── Side Panel Form ─────────────────────────────────────────────────────────

class _SupplierFormPanel extends StatefulWidget {
  final Supplier? supplier;
  final VoidCallback onClose;
  final void Function(Supplier) onSaved;

  const _SupplierFormPanel({
    this.supplier,
    required this.onClose,
    required this.onSaved,
  });

  @override
  State<_SupplierFormPanel> createState() => _SupplierFormPanelState();
}

class _SupplierFormPanelState extends State<_SupplierFormPanel> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _namaController;
  late TextEditingController _teleponController;
  late TextEditingController _alamatController;

  bool get _isEditing => widget.supplier != null;

  @override
  void initState() {
    super.initState();
    _namaController = TextEditingController(text: widget.supplier?.nama ?? '');
    _teleponController = TextEditingController(text: widget.supplier?.telepon ?? '');
    _alamatController = TextEditingController(text: widget.supplier?.alamat ?? '');
  }

  @override
  void dispose() {
    _namaController.dispose();
    _teleponController.dispose();
    _alamatController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final supplier = Supplier(
      id: widget.supplier?.id,
      nama: _namaController.text.trim(),
      telepon: _teleponController.text.trim().isEmpty ? null : _teleponController.text.trim(),
      alamat: _alamatController.text.trim().isEmpty ? null : _alamatController.text.trim(),
    );

    widget.onSaved(supplier);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDark ? Theme.of(context).colorScheme.surface : const Color(0xFFF8FBF9),
      child: Column(
        children: [
          // Panel header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.black.withValues(alpha: 0.08))),
            ),
            child: Row(
              children: [
                Text(
                  _isEditing ? 'Edit Supplier' : 'Tambah Supplier',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: widget.onClose,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          // Form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _namaController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Nama Supplier *',
                        prefixIcon: Icon(Icons.store_rounded, size: 18),
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _teleponController,
                      decoration: const InputDecoration(
                        labelText: 'Telepon',
                        hintText: 'Opsional',
                        prefixIcon: Icon(Icons.phone_rounded, size: 18),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _alamatController,
                      decoration: const InputDecoration(
                        labelText: 'Alamat',
                        hintText: 'Opsional',
                        prefixIcon: Icon(Icons.location_on_rounded, size: 18),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 28),
                    ElevatedButton(
                      onPressed: _submit,
                      child: Text(_isEditing ? 'Simpan Perubahan' : 'Tambah Supplier'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: widget.onClose,
                      child: const Text('Batal'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
