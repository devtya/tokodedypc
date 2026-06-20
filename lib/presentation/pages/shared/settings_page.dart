import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/di/injection.dart';
import '../../../core/services/update_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/services/supabase_sync_service.dart';
import '../../../data/database/app_database.dart';
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
  
  final _scrollController = ScrollController();
  final _queueScrollController = ScrollController();
  final _logScrollController = ScrollController();
  
  final _tampilanKey = GlobalKey();
  final _printerKey = GlobalKey();
  final _penggunaKey = GlobalKey();
  final _pinKey = GlobalKey();
  final _syncKey = GlobalKey();
  final _tentangKey = GlobalKey();

  String _appVersion = '';
  bool _checkingUpdate = false;
  _SettingsSection _activeSection = _SettingsSection.tampilan;
  int _pendingQueueCount = 0;
  bool _isProgrammaticScroll = false;
  
  StreamSubscription<List<PendingSyncQueueTableData>>? _queueSubscription;

  @override
  void initState() {
    super.initState();
    _loadVersion();
    _scrollController.addListener(_onScroll);
    
    // Listen to queue changes to update sidebar badge in real-time
    _queueSubscription = _syncService.watchPendingQueue().listen((items) {
      if (mounted) {
        setState(() {
          _pendingQueueCount = items.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _queueScrollController.dispose();
    _logScrollController.dispose();
    _queueSubscription?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_isProgrammaticScroll || !mounted) return;
    
    final sections = [
      (_tampilanKey, _SettingsSection.tampilan),
      (_printerKey, _SettingsSection.printer),
      (_penggunaKey, _SettingsSection.pengguna),
      (_pinKey, _SettingsSection.pin),
      (_syncKey, _SettingsSection.sync),
      (_tentangKey, _SettingsSection.tentang),
    ];

    _SettingsSection? bestSection;
    double bestDiff = double.infinity;

    for (final (key, section) in sections) {
      final context = key.currentContext;
      if (context != null) {
        final box = context.findRenderObject() as RenderBox?;
        if (box != null) {
          final position = box.localToGlobal(Offset.zero);
          // position.dy is relative to the screen. 
          // We look for the section closest to the top offset of the content container (around 120px).
          final diff = (position.dy - 120).abs();
          if (diff < bestDiff) {
            bestDiff = diff;
            bestSection = section;
          }
        }
      }
    }

    if (bestSection != null && bestSection != _activeSection) {
      setState(() {
        _activeSection = bestSection!;
      });
    }
  }

  void _scrollToSection(GlobalKey key, _SettingsSection section) async {
    setState(() {
      _activeSection = section;
      _isProgrammaticScroll = true;
    });
    
    final context = key.currentContext;
    if (context != null) {
      await Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
    
    await Future.delayed(const Duration(milliseconds: 100));
    _isProgrammaticScroll = false;
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
                    final key = switch (section) {
                      _SettingsSection.tampilan => _tampilanKey,
                      _SettingsSection.printer => _printerKey,
                      _SettingsSection.pengguna => _penggunaKey,
                      _SettingsSection.pin => _pinKey,
                      _SettingsSection.sync => _syncKey,
                      _SettingsSection.tentang => _tentangKey,
                    };
                    return _NavItem(
                      icon: icon,
                      label: label,
                      badge: badge,
                      isActive: isActive,
                      onTap: () => _scrollToSection(key, section),
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
      controller: _scrollController,
      padding: const EdgeInsets.all(32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section 1: Tampilan
            Container(key: _tampilanKey, child: _buildTampilan()),
            const Divider(height: 64, thickness: 1),
            // Section 2: Printer
            Container(key: _printerKey, child: const PrinterSettingsPage()),
            const Divider(height: 64, thickness: 1),
            // Section 3: Pengguna
            Container(key: _penggunaKey, child: _buildPengguna()),
            const Divider(height: 64, thickness: 1),
            // Section 4: PIN & Keamanan
            Container(key: _pinKey, child: const PinSettingsPage()),
            const Divider(height: 64, thickness: 1),
            // Section 5: Sinkronisasi
            Container(key: _syncKey, child: _buildSync()),
            const Divider(height: 64, thickness: 1),
            // Section 6: Tentang Aplikasi
            Container(key: _tentangKey, child: _buildTentang()),
            const SizedBox(height: 200), // Extra bottom padding for scroll space
          ],
        ),
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
        const SizedBox(
          height: 450,
          child: UserManagementPage(),
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
              crossAxisAlignment: CrossAxisAlignment.start,
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
                
                // StreamBuilder: Antrean Sync
                StreamBuilder<List<PendingSyncQueueTableData>>(
                  stream: _syncService.watchPendingQueue(),
                  builder: (context, snapshot) {
                    final queueItems = snapshot.data ?? [];
                    return _buildQueueListCard(queueItems, isSyncing);
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Card: Log Aktivitas Sinkronisasi
                _buildLogsCard(state),
                
                const SizedBox(height: 16),
                
                // Card: Utility
                _buildUtilitasCard(),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildQueueListCard(List<PendingSyncQueueTableData> queueItems, bool isSyncing) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.queue_rounded,
                  color: queueItems.isNotEmpty ? AppTheme.warningRed : AppTheme.primaryGreen,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Antrean Data (${queueItems.length} item)',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
                if (queueItems.isNotEmpty)
                  TextButton.icon(
                    onPressed: isSyncing
                        ? null
                        : () {
                            context.read<SyncBloc>().add(const SyncTriggered());
                          },
                    icon: const Icon(Icons.send_rounded, size: 14),
                    label: const Text('Kirim Semua'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (queueItems.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_outline_rounded, color: AppTheme.primaryGreen, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Semua data lokal telah sinkron dengan cloud.',
                      style: TextStyle(color: AppTheme.neutralGrey, fontSize: 13),
                    ),
                  ],
                ),
              )
            else
              Container(
                constraints: const BoxConstraints(maxHeight: 250),
                decoration: BoxDecoration(
                  border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE5E7EB)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Scrollbar(
                  controller: _queueScrollController,
                  thumbVisibility: true,
                  child: ListView.separated(
                    controller: _queueScrollController,
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(8),
                    itemCount: queueItems.length,
                    separatorBuilder: (_, index) => Divider(height: 8, color: isDark ? Colors.white12 : const Color(0xFFE5E7EB)),
                    itemBuilder: (context, index) {
                      final item = queueItems[index];
                      final isDelete = item.operation == 'delete';
                      final details = _getQueueItemDetails(item.targetTable, item.payload);
                      
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                // Badge table name
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: (isDark ? Colors.white12 : Colors.grey[200]),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    _formatTableName(item.targetTable),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white70 : Colors.black87,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Badge operation
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isDelete 
                                        ? AppTheme.warningRed.withValues(alpha: 0.1)
                                        : AppTheme.primaryGreen.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    isDelete ? 'HAPUS' : 'SIMPAN',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: isDelete ? AppTheme.warningRed : AppTheme.primaryGreen,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                // Delete queue item button
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 16, color: AppTheme.warningRed),
                                  onPressed: () => _confirmDeleteQueueItem(item.id),
                                  tooltip: 'Hapus dari antrean',
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              details,
                              style: const TextStyle(fontSize: 12),
                            ),
                            if (item.lastError != null)
                              Container(
                                margin: const EdgeInsets.only(top: 6),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.warningRed.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.warning_amber_rounded, size: 14, color: AppTheme.warningRed),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        item.lastError!,
                                        style: const TextStyle(fontSize: 11, color: AppTheme.warningRed),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogsCard(SyncState state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final logs = state.logs;
    final isSyncing = state is SyncInProgress;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.history_rounded, size: 24),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Log Aktivitas Sinkronisasi',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
                if (isSyncing)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (logs.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    'Belum ada riwayat aktivitas sinkronisasi.',
                    style: TextStyle(color: AppTheme.neutralGrey, fontSize: 13),
                  ),
                ),
              )
            else
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE5E7EB)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Scrollbar(
                  controller: _logScrollController,
                  thumbVisibility: true,
                  child: ListView.separated(
                    controller: _logScrollController,
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(8),
                    itemCount: logs.length,
                    separatorBuilder: (_, index) => Divider(height: 1, color: isDark ? Colors.white12 : const Color(0xFFE5E7EB)),
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      IconData icon;
                      Color color;
                      String typeLabel;

                      switch (log.type) {
                        case 'push_table':
                          icon = Icons.arrow_upward;
                          color = Colors.orange;
                          typeLabel = 'Upload';
                          break;
                        case 'pull_table':
                          icon = Icons.arrow_downward;
                          color = Colors.blue;
                          typeLabel = 'Download';
                          break;
                        case 'push_done':
                          icon = Icons.cloud_done;
                          color = AppTheme.primaryGreen;
                          typeLabel = 'Upload selesai';
                          break;
                        case 'pull_done':
                          icon = Icons.cloud_done;
                          color = AppTheme.primaryGreen;
                          typeLabel = 'Download selesai';
                          break;
                        case 'error':
                          icon = Icons.error_outline;
                          color = AppTheme.warningRed;
                          typeLabel = 'Error';
                          break;
                        default:
                          icon = Icons.info_outline;
                          color = AppTheme.neutralGrey;
                          typeLabel = log.type;
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        child: Row(
                          children: [
                            Icon(icon, color: color, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    log.tableName != null ? '$typeLabel — ${log.tableName}' : typeLabel,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    log.message,
                                    style: TextStyle(fontSize: 11, color: AppTheme.neutralGrey),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}:${log.timestamp.second.toString().padLeft(2, '0')}',
                              style: TextStyle(fontSize: 10, color: AppTheme.neutralGrey),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUtilitasCard() {
    return Card(
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
                if (confirm != true || !mounted) return;
                
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => const Center(child: CircularProgressIndicator()),
                );
                
                try {
                  final repo = sl<ProdukRepository>();
                  final result = await repo.cleanupDuplicateSatuan();
                  if (!mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Selesai! Dihapus: ${result.deleted}, Dilindungi: ${result.protected}',
                      ),
                      backgroundColor: Colors.blue,
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal: $e')),
                  );
                }
              },
              icon: const Icon(Icons.cleaning_services, size: 16),
              label: const Text('Bersihkan Duplikat Satuan'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteQueueItem(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Antrean?'),
        content: const Text(
            'Apakah Anda yakin ingin menghapus data ini dari antrean sinkronisasi?\n\nPerubahan lokal ini TIDAK akan di-upload ke cloud.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.warningRed),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await _syncService.deleteQueueItem(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item antrean berhasil dihapus')),
      );
    }
  }

  String _getQueueItemDetails(String targetTable, String payloadStr) {
    try {
      final payload = jsonDecode(payloadStr) as Map<String, dynamic>;
      switch (targetTable) {
        case 'produk':
          return 'Nama: ${payload['nama'] ?? '-'}, Satuan: ${payload['satuan'] ?? '-'}';
        case 'satuan_produk':
          return 'Nama: ${payload['nama'] ?? '-'}, Konversi: ${payload['konversi'] ?? '-'}';
        case 'supplier':
          return 'Nama: ${payload['nama'] ?? '-'}';
        case 'transaksi':
          final total = payload['total_harga'] ?? 0;
          return 'Total Belanja: Rp ${NumberFormat('#,###', 'id_ID').format(total)}';
        case 'item_transaksi':
          return 'Produk: ${payload['nama_produk'] ?? '-'}, Qty: ${payload['jumlah'] ?? '-'}';
        case 'pembelian':
          final total = payload['total_harga'] ?? 0;
          return 'Supplier: ${payload['nama_supplier'] ?? '-'}, Total: Rp ${NumberFormat('#,###', 'id_ID').format(total)}';
        case 'item_pembelian':
          return 'Produk: ${payload['nama_produk'] ?? '-'}, Qty: ${payload['jumlah'] ?? '-'}';
        case 'hutang_piutang':
          final jml = payload['jumlah'] ?? 0;
          return 'Pelanggan: ${payload['nama_pelanggan'] ?? '-'}, Jumlah: Rp ${NumberFormat('#,###', 'id_ID').format(jml)}';
        case 'riwayat_stok':
          return 'Tipe: ${payload['tipe'] ?? '-'}, Jumlah: ${payload['jumlah'] ?? '-'}';
        case 'notifikasi':
          return 'Judul: ${payload['judul'] ?? '-'}, Pesan: ${payload['pesan'] ?? '-'}';
        case 'pending_order':
          return 'Pelanggan: ${payload['nama_pelanggan'] ?? '-'}';
        case 'pending_order_item':
          return 'Produk: ${payload['nama_produk'] ?? '-'}, Qty: ${payload['jumlah'] ?? '-'}';
        case 'pending_pembelian':
          return 'Supplier: ${payload['nama_supplier'] ?? '-'}';
        case 'pending_pembelian_item':
          return 'Produk: ${payload['nama_produk'] ?? '-'}, Qty: ${payload['jumlah'] ?? '-'}';
        default:
          return 'ID: ${payload['id'] ?? '-'}';
      }
    } catch (_) {
      return 'Gagal memproses data';
    }
  }

  String _formatTableName(String table) {
    switch (table) {
      case 'produk': return 'Produk';
      case 'satuan_produk': return 'Satuan Produk';
      case 'supplier': return 'Supplier';
      case 'supplier_products': return 'Produk Supplier';
      case 'transaksi': return 'Transaksi Penjualan';
      case 'item_transaksi': return 'Item Penjualan';
      case 'pembelian': return 'Pembelian Barang';
      case 'item_pembelian': return 'Item Pembelian';
      case 'hutang_piutang': return 'Hutang / Piutang';
      case 'riwayat_stok': return 'Riwayat Stok';
      case 'notifikasi': return 'Notifikasi';
      case 'pending_order': return 'Pesanan Tertunda';
      case 'pending_order_item': return 'Item Pesanan Tertunda';
      case 'pending_pembelian': return 'Pembelian Tertunda';
      case 'pending_pembelian_item': return 'Item Pembelian Tertunda';
      case 'online_customers': return 'Pelanggan Online';
      case 'online_orders': return 'Pesanan Online';
      case 'online_order_items': return 'Item Pesanan Online';
      default: return table;
    }
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
