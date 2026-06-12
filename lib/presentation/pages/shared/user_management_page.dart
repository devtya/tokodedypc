import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/di/injection.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../domain/repositories/local_auth_repository.dart';
import '../../../core/theme/app_theme.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import 'invite_kasir_page.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final AuthRepository _authRepo = sl<AuthRepository>();
  final LocalAuthRepository _localAuthRepo = sl<LocalAuthRepository>();
  List<User> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await _authRepo.getAllUsers();
      setState(() {
        _users = users;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memuat pengguna: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showEditDialog(User user) {
    final namaCtrl = TextEditingController(text: user.nama ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(user.isOwner ? 'Edit Owner' : 'Edit Kasir'),
        content: TextField(
          controller: namaCtrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nama',
            prefixIcon: Icon(Icons.badge),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final nama = namaCtrl.text.trim();
              if (nama.isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Nama tidak boleh kosong')),
                );
                return;
              }

              try {
                await _authRepo.updateUser(user.copyWith(nama: nama));
                if (!mounted) return;

                if (ctx.mounted) Navigator.pop(ctx);

                _loadUsers();
                context.read<AuthBloc>().add(CheckAuthStatus());
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text('Gagal: $e')),
                  );
                }
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(User user) {
    if (user.isOwner) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Akun owner tidak dapat dihapus')),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Akun'),
        content: Text('Yakin ingin menghapus akun ${user.nama ?? user.email}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _authRepo.deleteUser(user.id!);
                _loadUsers();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal menghapus: $e')),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.warningRed),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _showResetPinDialog(User user) {
    final pinCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Reset PIN ${user.nama ?? "Kasir"}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Masukkan PIN baru untuk user ini.'),
            const SizedBox(height: 16),
            TextField(
              controller: pinCtrl,
              obscureText: true,
              maxLength: 6,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'PIN Baru (4-6 digit)',
                prefixIcon: Icon(Icons.pin),
              ),
            ),
            TextField(
              controller: confirmCtrl,
              obscureText: true,
              maxLength: 6,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Konfirmasi PIN',
                prefixIcon: Icon(Icons.pin),
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
            onPressed: () async {
              final pin = pinCtrl.text.trim();
              final confirm = confirmCtrl.text.trim();
              if (pin.isEmpty || confirm.isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('PIN tidak boleh kosong')),
                );
                return;
              }
              if (pin.length < 4 || pin.length > 6) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('PIN harus 4-6 digit')),
                );
                return;
              }
              if (pin != confirm) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('PIN tidak cocok')),
                );
                return;
              }
              try {
                await _localAuthRepo.removePin(user.id!);
                await _localAuthRepo.setPin(user.id!, pin);
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('PIN berhasil direset'),
                      backgroundColor: AppTheme.primaryGreen,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal: $e')),
                  );
                }
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Toolbar ─────────────────────────────────────────────────
        _buildToolbar(),
        // ── Content ─────────────────────────────────────────────────
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildTable(),
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
          Text(
            '${_users.length} pengguna',
            style: TextStyle(fontSize: 13, color: AppTheme.neutralGrey),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadUsers,
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () async {
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => const InviteKasirPage()),
              );
              if (result == true) _loadUsers();
            },
            icon: const Icon(Icons.person_add, size: 16),
            label: const Text('Undang Kasir'),
            style: ElevatedButton.styleFrom(visualDensity: VisualDensity.compact),
          ),
        ],
      ),
    );
  }

  Widget _buildTable() {
    if (_users.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline, size: 64, color: AppTheme.neutralGrey.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text('Belum ada pengguna', style: TextStyle(color: AppTheme.neutralGrey)),
          ],
        ),
      );
    }

    final currentUser = _authRepo.getCurrentUser();

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
            headingRowColor: WidgetStateProperty.all(Theme.of(context).colorScheme.surface),
            columns: const [
              DataColumn(label: Text('NAMA', style: TextStyle(fontWeight: FontWeight.w700))),
              DataColumn(label: Text('ROLE', style: TextStyle(fontWeight: FontWeight.w700))),
              DataColumn(label: Text('EMAIL', style: TextStyle(fontWeight: FontWeight.w700))),
              DataColumn(label: Text('AKSI', style: TextStyle(fontWeight: FontWeight.w700))),
            ],
            rows: _users.map((user) {
              return DataRow(
                cells: [
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: user.isOwner
                              ? AppTheme.primaryGreen
                              : AppTheme.neutralGrey.withValues(alpha: 0.3),
                          child: Icon(
                            user.isOwner ? Icons.admin_panel_settings : Icons.person,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          user.nama ?? 'Kasir',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: user.isOwner
                            ? AppTheme.primaryGreen.withValues(alpha: 0.12)
                            : AppTheme.neutralGrey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        user.role.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: user.isOwner ? AppTheme.primaryGreen : AppTheme.neutralGrey,
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      user.email ?? '-',
                      style: TextStyle(fontSize: 13, color: AppTheme.neutralGrey),
                    ),
                  ),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (currentUser?.isOwner == true && !user.isOwner)
                          IconButton(
                            icon: const Icon(Icons.pin, size: 18, color: Colors.orange),
                            tooltip: 'Reset PIN',
                            onPressed: () => _showResetPinDialog(user),
                            visualDensity: VisualDensity.compact,
                          ),
                        IconButton(
                          icon: const Icon(Icons.edit_rounded, size: 18, color: Colors.blue),
                          tooltip: 'Edit',
                          onPressed: () => _showEditDialog(user),
                          visualDensity: VisualDensity.compact,
                        ),
                        if (!user.isOwner)
                          IconButton(
                            icon: const Icon(Icons.delete_rounded, size: 18, color: AppTheme.warningRed),
                            tooltip: 'Hapus',
                            onPressed: () => _confirmDelete(user),
                            visualDensity: VisualDensity.compact,
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
}
