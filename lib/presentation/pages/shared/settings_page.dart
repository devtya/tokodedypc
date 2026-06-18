import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/di/injection.dart';
import '../../../core/services/update_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/services/supabase_sync_service.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/theme/theme_cubit.dart';
import '../../blocs/sync/sync_bloc.dart';
import 'login_page.dart';
import 'pin_settings_page.dart';
import 'printer_settings_page.dart';
import 'user_management_page.dart';
import '../../../domain/repositories/produk_repository.dart';

enum _SettingsSection { tampilan, printer, pengguna, pin, sync, tentang }

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _updateService = sl<UpdateService>();
  final _syncService = sl<SupabaseSyncService>();
  String _appVersion = '';
  bool _checkingUpdate = false;
  _SettingsSection _activeSection = _SettingsSection.tampilan;
  int _pendingQueueCount = 0;

  @override
  void initState() {
    super.initState();
    _loadVersion();
    _loadPendingQueueCount();
  }

  Future<void> _loadPendingQueueCount() async {
    try {
      final count = await _syncService.pendingQueueCount;
      if (mounted) setState(() => _pendingQueueCount = count);
    } catch (_) {}
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) setState(() => _appVersion = info.version);
    } catch (_) {}
  }

  Future<void> _checkUpdate() async {
    setState(() => _checkingUpdate = true);
    try {
      final update = await _updateService.checkForUpdate();
      if (!mounted) return;
      setState(() => _checkingUpdate = false);

      if (update == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aplikasi sudah versi terbaru')),
        );
        return;
      }

      final install = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Update Tersedia'),
          content: Container(
            constraints: const BoxConstraints(maxHeight: 400),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Versi baru: ${update.version}'),
                  if (update.notes != null && update.notes!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Text('Catatan rilis:', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(update.notes!, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Nanti')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Update')),
          ],
        ),
      );

      if (install == true) {
        final progressController = StreamController<double>();

        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => PopScope(
            canPop: false,
            child: AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Mengunduh Pembaruan'),
              content: StreamBuilder<double>(
                stream: progressController.stream,
                initialData: 0.0,
                builder: (context, snapshot) {
                  final pct = ((snapshot.data ?? 0.0) * 100).toInt();
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      LinearProgressIndicator(
                        value: snapshot.data,
                        backgroundColor: Colors.grey[200],
                        valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                        minHeight: 8,
                      ),
                      const SizedBox(height: 16),
                      Text('$pct% selesai',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      const Text(
                        'Harap jangan tutup aplikasi selama proses unduh berlangsung.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );

        try {
          final path = await _updateService.downloadUpdate(
            update.url,
            assetName: update.assetName,
            onProgress: (progress) {
              progressController.add(progress);
            },
          );

          progressController.close();
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Download selesai, membuka installer...')),
            );
          }
          await _updateService.installUpdate(path);
        } catch (err) {
          progressController.close();
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Gagal mengunduh pembaruan: $err')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _checkingUpdate = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memeriksa update: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navItems = [
      (_SettingsSection.tampilan, Icons.palette_rounded, 'Tampilan', null),
      (_SettingsSection.printer, Icons.print_rounded, 'Printer', null),
      (_SettingsSection.pengguna, Icons.people_rounded, 'Pengguna', null),
      (_SettingsSection.pin, Icons.lock_rounded, 'PIN & Keamanan', null),
      (_SettingsSection.sync, Icons.cloud_sync_rounded, 'Sinkronisasi',
          _pendingQueueCount > 0 ? _pendingQueueCount.toString() : null),
      (_SettingsSection.tentang, Icons.info_rounded, 'Tentang Aplikasi', null),
    ];

    return Row(
      children: [
        // ── Kolom Kiri: Nav ─────────────────────────────────────────────
        Container(
          width: 220,
          color: isDark ? const Color(0xFF1B1E1C) : const Color(0xFFF3F7F4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Text(
                  'PENGATURAN',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: AppTheme.neutralGrey,
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  children: navItems.map((item) {
                    final (section, icon, label, badge) = item;
                    final isActive = _activeSection == section;
                    return _NavItem(
                      icon: icon,
                      label: label,
                      badge: badge,
                      isActive: isActive,
                      onTap: () => setState(() => _activeSection = section),
                    );
                  }).toList(),
                ),
              ),
              // Logout button
              Padding(
                padding: const EdgeInsets.all(16),
                child: OutlinedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Logout'),
                        content: const Text('Apakah Anda yakin ingin keluar?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Batal'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              context.read<AuthBloc>().add(LogoutEvent());
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(builder: (_) => const LoginPage()),
                                (route) => false,
                              );
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.warningRed,
                            ),
                            child: const Text('Logout'),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.logout, size: 16, color: AppTheme.warningRed),
                  label: const Text('Logout', style: TextStyle(color: AppTheme.warningRed)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.warningRed),
                    minimumSize: const Size(double.infinity, 40),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Divider
        VerticalDivider(width: 1, color: isDark ? Colors.white12 : const Color(0xFFE5E7EB)),

        // ── Kolom Kanan: Content ─────────────────────────────────────────
        Expanded(
          child: _buildContent(),
        ),
      ],
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: switch (_activeSection) {
          _SettingsSection.tampilan => _buildTampilan(),
          _SettingsSection.printer => const PrinterSettingsPage(),
          _SettingsSection.pengguna => _buildPengguna(),
          _SettingsSection.pin => const PinSettingsPage(),
          _SettingsSection.sync => _buildSync(),
          _SettingsSection.tentang => _buildTentang(),
        },
      ),
    );
  }

  Widget _buildTampilan() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Tema Aplikasi', Icons.palette_rounded),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: BlocBuilder<ThemeCubit, ThemeMode>(
              builder: (context, themeMode) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mode saat ini: ${_themeLabel(themeMode)}',
                      style: TextStyle(fontSize: 13, color: AppTheme.neutralGrey),
                    ),
                    const SizedBox(height: 16),
                    SegmentedButton<ThemeMode>(
                      segments: const [
                        ButtonSegment(
                          value: ThemeMode.system,
                          label: Text('Sistem'),
                          icon: Icon(Icons.settings_brightness),
                        ),
                        ButtonSegment(
                          value: ThemeMode.light,
                          label: Text('Terang'),
                          icon: Icon(Icons.light_mode),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          label: Text('Gelap'),
                          icon: Icon(Icons.dark_mode),
                        ),
                      ],
                      selected: {themeMode},
                      onSelectionChanged: (modes) {
                        context.read<ThemeCubit>().setTheme(modes.first);
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPengguna() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Manajemen Pengguna', Icons.people_rounded),
        const SizedBox(height: 16),
        SizedBox(
          height: 500,
          child: const UserManagementPage(),
        ),
      ],
    );
  }

  Widget _buildSync() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Sinkronisasi Cloud', Icons.cloud_sync_rounded),
        const SizedBox(height: 16),
        BlocConsumer<SyncBloc, SyncState>(
          listener: (context, state) {
            if (state is SyncSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Sinkronisasi data ke cloud BERHASIL!'),
                  backgroundColor: AppTheme.primaryGreen,
                ),
              );
            } else if (state is SyncError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Sinkronisasi GAGAL: ${state.message}'),
                  backgroundColor: AppTheme.warningRed,
                ),
              );
            }
          },
          builder: (context, state) {
            final isSyncing = state is SyncInProgress;
            final isError = state is SyncError;
            final lastSync = state is SyncIdle
                ? state.lastSync
                : state is SyncSuccess
                    ? state.lastSync
                    : state is SyncError
                        ? state.lastSync
                        : null;

            String subtitle;
            if (isSyncing) {
              subtitle = 'Sedang menyelaraskan data dengan cloud...';
            } else if (isError) {
              subtitle = 'Gagal: ${state.message}';
            } else if (lastSync != null) {
              final diff = DateTime.now().difference(lastSync);
              String ago;
              if (diff.inSeconds < 60) {
                ago = '${diff.inSeconds} detik yang lalu';
              } else if (diff.inMinutes < 60) {
                ago = '${diff.inMinutes} menit yang lalu';
              } else {
                ago = DateFormat('HH:mm, dd/MM').format(lastSync);
              }
              subtitle = 'Terakhir sinkron: $ago';
            } else {
              subtitle = 'Kirim data lokal & unduh data dari cloud';
            }

            return Column(
              children: [
                // Card: Status Sinkronisasi
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            isSyncing
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryGreen),
                                  )
                                : Icon(
                                    isError ? Icons.cloud_off : Icons.cloud_done,
                                    color: isError ? AppTheme.warningRed : AppTheme.primaryGreen,
                                    size: 28,
                                  ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Status Sinkronisasi',
                                      style: TextStyle(fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 2),
                                  Text(
                                    subtitle,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isError ? AppTheme.warningRed : AppTheme.neutralGrey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: isSyncing
                                ? null
                                : () {
                                    context.read<SyncBloc>().add(const SyncTriggered());
                                    _loadPendingQueueCount();
                                  },
                            icon: const Icon(Icons.sync, size: 16),
                            label: Text(isSyncing ? 'Sedang Sinkron...' : 'Sinkronkan Sekarang'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Card: Antrian Sync
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Icon(
                          Icons.queue_rounded,
                          color: _pendingQueueCount > 0 ? AppTheme.warningRed : AppTheme.primaryGreen,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Antrian Sinkronisasi',
                                  style: TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              Text(
                                _pendingQueueCount > 0
                                    ? '$_pendingQueueCount item menunggu untuk disinkronkan'
                                    : 'Tidak ada data yang menunggu sinkronisasi',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _pendingQueueCount > 0 ? AppTheme.warningRed : AppTheme.neutralGrey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_pendingQueueCount > 0)
                          TextButton(
                            onPressed: () {
                              context.read<SyncBloc>().add(const SyncTriggered());
                              _loadPendingQueueCount();
                            },
                            child: const Text('Kirim'),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Card: Utility
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Utilitas', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        // Bersihkan duplikat satuan
                        OutlinedButton.icon(
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Bersihkan Duplikat?'),
                                content: const Text(
                                  'Fungsi ini akan memindai seluruh produk dan menghapus satuan yang namanya dobel.\n\n'
                                  'Satuan yang sudah pernah dipakai di transaksi TIDAK akan dihapus.',
                                ),
                                actions: [
                                  TextButton(
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: const Text('Batal')),
                                  TextButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      style: TextButton.styleFrom(foregroundColor: Colors.blue),
                                      child: const Text('Lanjutkan')),
                                ],
                              ),
                            );
                            if (confirm == true && context.mounted) {
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (_) => const Center(child: CircularProgressIndicator()),
                              );
                              try {
                                final repo = sl<ProdukRepository>();
                                final result = await repo.cleanupDuplicateSatuan();
                                if (context.mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Selesai! Dihapus: ${result.deleted}, Dilindungi: ${result.protected}',
                                      ),
                                      backgroundColor: Colors.blue,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Gagal: $e')),
                                  );
                                }
                              }
                            }
                          },
                          icon: const Icon(Icons.cleaning_services, size: 16),
                          label: const Text('Bersihkan Duplikat Satuan'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildTentang() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Tentang Aplikasi', Icons.info_rounded),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.point_of_sale_rounded, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Tokodedy PC',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                        Text(
                          _appVersion.isNotEmpty ? 'Versi $_appVersion' : 'Memuat versi...',
                          style: TextStyle(color: AppTheme.neutralGrey),
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 32),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.system_update,
                    color: _checkingUpdate ? Colors.grey : AppTheme.primaryGreen,
                  ),
                  title: Text(_checkingUpdate ? 'Memeriksa pembaruan...' : 'Periksa Pembaruan'),
                  subtitle: const Text('Cek versi terbaru aplikasi'),
                  trailing: _checkingUpdate
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.chevron_right),
                  onTap: _checkingUpdate ? null : _checkUpdate,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryGreen, size: 22),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      ],
    );
  }

  String _themeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'Mengikuti tema sistem';
      case ThemeMode.light:
        return 'Terang';
      case ThemeMode.dark:
        return 'Gelap';
    }
  }
}

// ─── Nav Item ─────────────────────────────────────────────────────────────────

class _NavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final String? badge;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    this.badge,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(bottom: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: widget.isActive
                ? AppTheme.primaryGreen.withValues(alpha: 0.15)
                : _hovered
                    ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                widget.icon,
                size: 18,
                color: widget.isActive ? AppTheme.primaryGreen : AppTheme.neutralGrey,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: widget.isActive ? FontWeight.w600 : FontWeight.normal,
                    color: widget.isActive ? AppTheme.primaryGreen : null,
                  ),
                ),
              ),
              if (widget.badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppTheme.warningRed,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    widget.badge!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
