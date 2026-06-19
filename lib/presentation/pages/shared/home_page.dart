import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../i18n/strings.g.dart';
import '../../../core/di/injection.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import 'login_page.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/cashier/cashier_bloc.dart';
import '../../blocs/hutang/hutang_bloc.dart';
import '../../blocs/laporan/laporan_bloc.dart';
import '../../blocs/notifikasi/notifikasi_bloc.dart';
import '../../blocs/notifikasi/notifikasi_event.dart';
import '../../blocs/notifikasi/notifikasi_state.dart';
import '../../blocs/pembelian/pembelian_bloc.dart';
import '../../blocs/purchase_order/purchase_order_bloc.dart';
import '../../blocs/produk/produk_bloc.dart';
import '../../blocs/supplier/supplier_bloc.dart';
import '../../blocs/transaksi/transaksi_bloc.dart';
import '../../blocs/dashboard/dashboard_bloc.dart';
import '../../blocs/dashboard/dashboard_event.dart';
import '../../blocs/dashboard/dashboard_state.dart';
import '../../blocs/online_order/online_order_bloc.dart';
import '../../blocs/riwayat_harga/riwayat_harga_bloc.dart';
import 'cashier_page.dart';
import 'riwayat_harga_page.dart';
import 'hutang_page.dart';
import 'laporan_page.dart';
import 'notifikasi_page.dart';
import 'pembelian_page.dart';
import 'produk_page.dart';
import 'purchase_order_page.dart';
import 'settings_page.dart';
import 'supplier_page.dart';
import 'transaksi_page.dart';
import 'user_management_page.dart';
import 'online_order_page.dart';

// ─── Entry Point ───────────────────────────────────────────────────────────────

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => sl<NotifikasiBloc>()..add(LoadNotifikasi()),
        ),
        BlocProvider(
          create: (context) => sl<DashboardBloc>()..add(LoadDashboardMetrics()),
        ),
        BlocProvider(
          create: (context) => sl<OnlineOrderBloc>()..add(LoadPendingOnlineOrders()),
        ),
      ],
      child: const _HomeDesktopShell(),
    );
  }
}

// ─── Desktop Shell (Sidebar + Content) ─────────────────────────────────────────

enum _NavSection {
  dashboard,
  kasir,
  produk,
  transaksi,
  laporan,
  pembelian,
  purchaseOrder,
  supplier,
  hutang,
  onlineOrder,
  pengguna,
  pengaturan,
}

extension _NavSectionExt on _NavSection {
  String get label {
    switch (this) {
      case _NavSection.dashboard: return t.navigation.dashboard;
      case _NavSection.kasir: return t.navigation.kasir;
      case _NavSection.produk: return t.navigation.produk;
      case _NavSection.transaksi: return t.navigation.transaksi;
      case _NavSection.laporan: return t.navigation.laporan;
      case _NavSection.pembelian: return t.navigation.pembelian;
      case _NavSection.purchaseOrder: return t.navigation.purchase_order;
      case _NavSection.supplier: return t.navigation.supplier;
      case _NavSection.hutang: return t.navigation.hutang;
      case _NavSection.onlineOrder: return t.navigation.online_order;
      case _NavSection.pengguna: return t.navigation.pengguna;
      case _NavSection.pengaturan: return t.navigation.pengaturan;
    }
  }

  IconData get icon {
    switch (this) {
      case _NavSection.dashboard: return Icons.dashboard_rounded;
      case _NavSection.kasir: return Icons.point_of_sale_rounded;
      case _NavSection.produk: return Icons.inventory_2_rounded;
      case _NavSection.transaksi: return Icons.receipt_long_rounded;
      case _NavSection.laporan: return Icons.bar_chart_rounded;
      case _NavSection.pembelian: return Icons.shopping_bag_rounded;
      case _NavSection.purchaseOrder: return Icons.assignment_rounded;
      case _NavSection.supplier: return Icons.business_rounded;
      case _NavSection.hutang: return Icons.account_balance_wallet_rounded;
      case _NavSection.onlineOrder: return Icons.shopping_cart_checkout_rounded;
      case _NavSection.pengguna: return Icons.manage_accounts_rounded;
      case _NavSection.pengaturan: return Icons.settings_rounded;
    }
  }

  Color get color {
    switch (this) {
      case _NavSection.dashboard: return AppTheme.navDashboard;
      case _NavSection.kasir: return AppTheme.navKasir;
      case _NavSection.produk: return AppTheme.navProduk;
      case _NavSection.transaksi: return AppTheme.navTransaksi;
      case _NavSection.laporan: return AppTheme.navLaporan;
      case _NavSection.pembelian: return AppTheme.navPembelian;
      case _NavSection.purchaseOrder: return AppTheme.navPurchaseOrder;
      case _NavSection.supplier: return AppTheme.navSupplier;
      case _NavSection.hutang: return AppTheme.navHutang;
      case _NavSection.onlineOrder: return AppTheme.navOnlineOrder;
      case _NavSection.pengguna: return AppTheme.navPengguna;
      case _NavSection.pengaturan: return AppTheme.navPengaturan;
    }
  }
}

class _HomeDesktopShell extends StatefulWidget {
  const _HomeDesktopShell();

  @override
  State<_HomeDesktopShell> createState() => _HomeDesktopShellState();
}

class _HomeDesktopShellState extends State<_HomeDesktopShell> {
  _NavSection _activeSection = _NavSection.dashboard;
  bool _sidebarCollapsed = false;
  bool _emailPromptShown = false;

  static const double _kSidebarExpanded = 240;
  static const double _kSidebarCollapsed = 72;

  void _navigate(_NavSection section) {
    setState(() => _activeSection = section);
  }

  void _reloadDashboardAndNotif() {
    if (mounted) {
      context.read<NotifikasiBloc>().add(LoadNotifikasi());
      context.read<DashboardBloc>().add(LoadDashboardMetrics());
      context.read<OnlineOrderBloc>().add(LoadPendingOnlineOrders());
    }
  }

  void _showEmailDialog(BuildContext context, User user) {
    final emailCtrl = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(t.dialog.email_title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.dialog.email_subtitle,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailCtrl,
              decoration: InputDecoration(
                labelText: t.dialog.email_label,
                prefixIcon: const Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t.dialog.btn_nanti),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = emailCtrl.text.trim();
              if (email.isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text(t.dialog.email_empty)),
                );
                return;
              }
              if (!RegExp(r'^[^\@\s]+@[^\@\s]+\.[^\@\s]+$').hasMatch(email)) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text(t.dialog.email_invalid)),
                );
                return;
              }
              try {
                await sl<AuthRepository>().updateUser(
                  user.copyWith(email: email),
                );
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  context.read<AuthBloc>().add(CheckAuthStatus());
                }
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text('${t.dialog.save_failed}: ${e.toString()}')),
                  );
                }
              }
            },
            child: Text(t.dialog.btn_simpan),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isAdmin) {
    switch (_activeSection) {
      case _NavSection.dashboard:
        return _DashboardPanel(
          onNavigate: _navigate,
          isAdmin: isAdmin,
          onReload: _reloadDashboardAndNotif,
        );
      case _NavSection.kasir:
        return BlocProvider.value(
          value: sl<CashierBloc>(),
          child: const CashierPage(),
        );
      case _NavSection.produk:
        return BlocProvider.value(
          value: sl<ProdukBloc>(),
          child: const ProdukPage(),
        );
      case _NavSection.transaksi:
        return BlocProvider(
          create: (_) => sl<TransaksiBloc>(),
          child: const TransaksiPage(),
        );
      case _NavSection.laporan:
        return BlocProvider.value(
          value: sl<LaporanBloc>(),
          child: const LaporanPage(),
        );
      case _NavSection.pembelian:
        return BlocProvider.value(
          value: sl<PembelianBloc>(),
          child: const PembelianPage(),
        );
      case _NavSection.purchaseOrder:
        return BlocProvider(
          create: (_) => sl<PurchaseOrderBloc>(),
          child: const PurchaseOrderPage(),
        );
      case _NavSection.supplier:
        return BlocProvider.value(
          value: sl<SupplierBloc>(),
          child: const SupplierPage(),
        );
      case _NavSection.hutang:
        return BlocProvider.value(
          value: sl<HutangBloc>(),
          child: const HutangPage(),
        );
      case _NavSection.onlineOrder:
        return BlocProvider.value(
          value: sl<OnlineOrderBloc>(),
          child: const OnlineOrderPage(),
        );
      case _NavSection.pengguna:
        return const UserManagementPage();
      case _NavSection.pengaturan:
        return const SettingsPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (prev, current) => current is Unauthenticated,
      listener: (context, state) {
        _emailPromptShown = false;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          String username = '';
          String role = 'kasir';
          if (authState is Authenticated) {
            username = authState.user.nama ?? authState.user.email ?? '';
            role = authState.user.role;
          }
          final isAdmin = role == 'owner';

          final currentUser = authState is Authenticated ? authState.user : null;
          if (currentUser != null && currentUser.email == null && !_emailPromptShown) {
            _emailPromptShown = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showEmailDialog(context, currentUser);
            });
          }

          return Scaffold(
            body: Row(
              children: [
                // ── Sidebar ────────────────────────────────────────────
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeInOut,
                  width: _sidebarCollapsed ? _kSidebarCollapsed : _kSidebarExpanded,
                  child: _Sidebar(
                    collapsed: _sidebarCollapsed,
                    activeSection: _activeSection,
                    username: username,
                    role: role,
                    isAdmin: isAdmin,
                    onNavigate: _navigate,
                    onToggleCollapse: () => setState(() => _sidebarCollapsed = !_sidebarCollapsed),
                    onLogout: () => context.read<AuthBloc>().add(LogoutEvent()),
                  ),
                ),

                // ── Content Area ───────────────────────────────────────
                Expanded(
                  child: Column(
                    children: [
                      // Top Bar
                      _TopBar(
                        activeSection: _activeSection,
                        onReload: _reloadDashboardAndNotif,
                      ),
                      // Page Content
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          transitionBuilder: (child, anim) => FadeTransition(
                            opacity: anim,
                            child: child,
                          ),
                          child: KeyedSubtree(
                            key: ValueKey(_activeSection),
                            child: _buildContent(isAdmin),
                          ),
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
    );
  }
}

// ─── Sidebar Widget ─────────────────────────────────────────────────────────────

class _Sidebar extends StatelessWidget {
  final bool collapsed;
  final _NavSection activeSection;
  final String username;
  final String role;
  final bool isAdmin;
  final void Function(_NavSection) onNavigate;
  final VoidCallback onToggleCollapse;
  final VoidCallback onLogout;

  const _Sidebar({
    required this.collapsed,
    required this.activeSection,
    required this.username,
    required this.role,
    required this.isAdmin,
    required this.onNavigate,
    required this.onToggleCollapse,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.sidebarBackgroundDark : AppTheme.sidebarBackgroundLight;


    // Menu groups
    final kasirItems = [_NavSection.kasir, _NavSection.transaksi];
    final stokItems = [_NavSection.produk, _NavSection.pembelian, _NavSection.purchaseOrder, _NavSection.supplier];
    final keuanganItems = [_NavSection.laporan, _NavSection.hutang];
    final onlineItems = [_NavSection.onlineOrder];
    final adminItems = isAdmin ? [_NavSection.pengguna] : <_NavSection>[];
    final settingItems = [_NavSection.pengaturan];

    return Container(
      color: bg,
      child: Column(
        children: [
          // Logo + Collapse Toggle
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: collapsed ? AppTheme.spaceSm : AppTheme.spaceMd,
              vertical: AppTheme.spaceLg,
            ),
            child: Row(
              children: [
                Container(
                  width: collapsed ? 32 : 40,
                  height: collapsed ? 32 : 40,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: Icon(Icons.point_of_sale_rounded, color: Colors.white, size: collapsed ? 16 : 22),
                ),
                if (!collapsed) ...[
                  const SizedBox(width: AppTheme.spaceSm),
                  Expanded(
                    child: Text(
                      AppConstants.appName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        letterSpacing: -0.3,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                IconButton(
                  onPressed: onToggleCollapse,
                  icon: Icon(
                    collapsed ? Icons.chevron_right : Icons.chevron_left,
                    color: Colors.white54,
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          Divider(color: Theme.of(context).dividerTheme.color, height: 1),
          const SizedBox(height: AppTheme.spaceSm),

          // Nav Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [
                _SidebarItem(section: _NavSection.dashboard, active: activeSection == _NavSection.dashboard, collapsed: collapsed, onTap: () => onNavigate(_NavSection.dashboard)),
                const SizedBox(height: 4),
                if (!collapsed) _SidebarLabel(t.navigation.group_kasir),
                 kasirItems.map((s) => _SidebarItem(section: s, active: activeSection == s, collapsed: collapsed, onTap: () => onNavigate(s))).toList().first,
                 kasirItems.map((s) => _SidebarItem(section: s, active: activeSection == s, collapsed: collapsed, onTap: () => onNavigate(s))).toList().last,
                const SizedBox(height: 4),
                if (!collapsed) _SidebarLabel(t.navigation.group_stok),
                ...stokItems.map((s) => _SidebarItem(section: s, active: activeSection == s, collapsed: collapsed, onTap: () => onNavigate(s))),
                if (isAdmin) ...[
                  const SizedBox(height: 4),
                  if (!collapsed) _SidebarLabel(t.navigation.group_keuangan),
                  ...keuanganItems.map((s) => _SidebarItem(section: s, active: activeSection == s, collapsed: collapsed, onTap: () => onNavigate(s))),
                ],
                const SizedBox(height: 4),
                if (!collapsed) _SidebarLabel(t.navigation.group_online),
                ...onlineItems.map((s) => _SidebarItem(section: s, active: activeSection == s, collapsed: collapsed, onTap: () => onNavigate(s))),
                if (adminItems.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  if (!collapsed) _SidebarLabel(t.navigation.group_admin),
                  ...adminItems.map((s) => _SidebarItem(section: s, active: activeSection == s, collapsed: collapsed, onTap: () => onNavigate(s))),
                ],
              ],
            ),
          ),

          const Divider(color: AppTheme.white06, height: 1),

          // Settings + User
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                ...settingItems.map((s) => _SidebarItem(
                  section: s,
                  active: activeSection == s,
                  collapsed: collapsed,
                  onTap: () => onNavigate(s),
                )),
                const SizedBox(height: 4),
                // User info + logout
                InkWell(
                  onTap: onLogout,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.2),
                          child: Text(
                            username.isNotEmpty ? username[0].toUpperCase() : '?',
                            style: const TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                        if (!collapsed) ...[
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  username,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  role.toUpperCase(),
                                  style: const TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 0.5),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.logout_rounded, color: Colors.white38, size: 18),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatefulWidget {
  final _NavSection section;
  final bool active;
  final bool collapsed;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.section,
    required this.active,
    required this.collapsed,
    required this.onTap,
  });

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.active;
    final section = widget.section;

    return Tooltip(
      message: widget.collapsed ? section.label : '',
      preferBelow: false,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.symmetric(vertical: 2),
            padding: EdgeInsets.symmetric(horizontal: widget.collapsed ? 16 : 12, vertical: 10),
            decoration: BoxDecoration(
              color: active
                  ? section.color.withValues(alpha: 0.18)
                  : _hovered
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: active
                  ? Border.all(color: section.color.withValues(alpha: 0.35), width: 1)
                  : null,
            ),
            child: Row(
              mainAxisAlignment: widget.collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                Icon(
                  section.icon,
                  size: 20,
                  color: active ? section.color : Colors.white54,
                ),
                if (!widget.collapsed) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      section.label,
                      style: TextStyle(
                        color: active ? Colors.white : Colors.white70,
                        fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                        fontSize: 13.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarLabel extends StatelessWidget {
  final String text;
  const _SidebarLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, top: 8, bottom: 4),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white24,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

// ─── Top Bar ────────────────────────────────────────────────────────────────────

class _TopBar extends StatefulWidget {
  final _NavSection activeSection;
  final VoidCallback onReload;

  const _TopBar({required this.activeSection, required this.onReload});

  @override
  State<_TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<_TopBar> {

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).colorScheme.surface : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white12 : const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            widget.activeSection.label,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
          ),
          const Spacer(),
          // Refresh
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            tooltip: 'Refresh',
            onPressed: widget.onReload,
          ),
          const SizedBox(width: 4),
          // Notifikasi
          BlocBuilder<NotifikasiBloc, NotifikasiState>(
            builder: (context, state) {
              int unread = 0;
              if (state is NotifikasiLoaded) unread = state.unreadNotifikasi.length;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_rounded, size: 20),
                    tooltip: 'Notifikasi',
                    onPressed: () => _showNotifikasiDropdown(context, unread),
                  ),
                  if (unread > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: AppTheme.warningRed,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$unread',
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  void _showNotifikasiDropdown(BuildContext context, int unread) {
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (ctx) => Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: const EdgeInsets.only(top: 60, right: 16),
          child: Material(
            elevation: 12,
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            child: SizedBox(
              width: 360,
              height: 480,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.black.withValues(alpha: 0.08))),
                      color: Theme.of(context).colorScheme.surface,
                    ),
                    child: Row(
                      children: [
                        const Text('Notifikasi',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                        if (unread > 0)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.warningRed,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text('$unread baru',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                          ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () =>
                              context.read<NotifikasiBloc>().add(MarkAllNotifikasiAsRead()),
                          icon: const Icon(Icons.done_all, size: 15),
                          label: const Text('Tandai Dibaca', style: TextStyle(fontSize: 12)),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () => Navigator.pop(ctx),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: BlocProvider.value(
                      value: context.read<NotifikasiBloc>(),
                      child: const NotifikasiPage(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


// ─── Dashboard Panel ────────────────────────────────────────────────────────────

class _DashboardPanel extends StatelessWidget {
  final void Function(_NavSection) onNavigate;
  final bool isAdmin;
  final VoidCallback onReload;

  const _DashboardPanel({
    required this.onNavigate,
    required this.isAdmin,
    required this.onReload,
  });

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${t.home.welcome} 👋',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('EEEE, dd MMMM yyyy', 'id').format(DateTime.now()),
                      style: TextStyle(color: AppTheme.neutralGrey, fontSize: 14),
                    ),
                  ],
                ),
              ),
              // Kasir CTA
              ElevatedButton.icon(
                onPressed: () => onNavigate(_NavSection.kasir),
                icon: const Icon(Icons.point_of_sale_rounded, size: 18),
                label: const Text('Buka Kasir', style: TextStyle(fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Dashboard Metrics Cards
          BlocBuilder<DashboardBloc, DashboardState>(
            builder: (context, state) {
              if (state is DashboardLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is DashboardLoaded) {
                return Column(
                  children: [
                    // Metric Cards Row
                    Row(
                      children: [
                        _MetricCard(
                          label: t.dashboard.omzet_today,
                          value: formatCurrency.format(state.metrics.omzet),
                          icon: Icons.trending_up_rounded,
                          color: AppTheme.primaryGreen,
                          gradient: isDark
                              ? [const Color(0xFF1a4d2e), const Color(0xFF0f3320)]
                              : [const Color(0xFF22c55e), const Color(0xFF15803d)],
                          isHighlight: true,
                        ),
                        const SizedBox(width: 16),
                        _MetricCard(
                          label: t.dashboard.transaction,
                          value: '${state.metrics.transaksi}',
                          icon: Icons.receipt_long_rounded,
                          color: Colors.blue,
                          gradient: null,
                        ),
                        const SizedBox(width: 16),
                        _MetricCard(
                          label: t.dashboard.sold,
                          value: '${state.metrics.terjual}',
                          icon: Icons.shopping_bag_rounded,
                          color: Colors.orange,
                          gradient: null,
                        ),
                        const SizedBox(width: 16),
                        _MetricCard(
                          label: 'Stok Menipis',
                          value: '${state.metrics.stokMenipis.length}',
                          icon: Icons.warning_rounded,
                          color: AppTheme.warningRed,
                          gradient: null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Two-column: Stok Menipis + Online Order
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Stok Menipis
                        Expanded(
                          child: _DashboardCard(
                            title: t.dashboard.low_stock,
                            icon: Icons.warning_rounded,
                            color: AppTheme.warningRed,
                            onViewAll: () => onNavigate(_NavSection.produk),
                            child: state.metrics.stokMenipis.isEmpty
                                ? const _EmptyState('Semua stok dalam kondisi cukup ✅')
                                : ListView.separated(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: state.metrics.stokMenipis.length.clamp(0, 8),
                                    separatorBuilder: (ctx, idx) => const Divider(height: 1),
                                    itemBuilder: (_, i) {
                                      final p = state.metrics.stokMenipis[i];
                                      return ListTile(
                                        dense: true,
                                        leading: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: AppTheme.warningRed.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Icon(Icons.warning_rounded, color: AppTheme.warningRed, size: 16),
                                        ),
                                        title: Text(p.nama, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                        trailing: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: AppTheme.warningRed,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            'Sisa ${p.stok}',
                                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Update Harga Terakhir
                        Expanded(
                          child: _DashboardCard(
                            title: t.price_update.title,
                            icon: Icons.price_change_rounded,
                            color: Colors.blue,
                            onViewAll: () => showDialog(
                              context: context,
                              builder: (_) => Dialog(
                                clipBehavior: Clip.antiAlias,
                                child: SizedBox(
                                  width: 400,
                                  height: 500,
                                  child: Scaffold(
                                    appBar: AppBar(title: const Text('Riwayat Harga')),
                                    body: BlocProvider(
                                      create: (_) => sl<RiwayatHargaBloc>(),
                                      child: const RiwayatHargaPage(),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            child: state.metrics.updateHargaTerakhir.isEmpty
                                ? const _EmptyState('Belum ada perubahan harga hari ini')
                                : ListView.separated(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: state.metrics.updateHargaTerakhir.length.clamp(0, 8),
                                    separatorBuilder: (ctx, idx) => const Divider(height: 1),
                                    itemBuilder: (_, i) {
                                      final r = state.metrics.updateHargaTerakhir[i];
                                      final isNaik = r.hargaJualBaru > r.hargaJualLama;
                                      return ListTile(
                                        dense: true,
                                        leading: Icon(
                                          isNaik ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                                          color: isNaik ? AppTheme.warningRed : AppTheme.primaryGreen,
                                          size: 18,
                                        ),
                                        title: Text(
                                          r.produkNama ?? t.price_update.product_deleted,
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                        ),
                                        trailing: Text(
                                          formatCurrency.format(r.hargaJualBaru),
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // Online Orders Pending
          const SizedBox(height: 24),
          BlocBuilder<OnlineOrderBloc, OnlineOrderState>(
            builder: (context, state) {
              if (state is OnlineOrderLoaded && state.orders.isNotEmpty) {
                return _DashboardCard(
                  title: 'Pesanan Online Baru (${state.orders.length})',
                  icon: Icons.shopping_cart_checkout_rounded,
                  color: Colors.indigo,
                  onViewAll: () => onNavigate(_NavSection.onlineOrder),
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: state.orders.length.clamp(0, 5),
                    itemBuilder: (context, i) {
                      final order = state.orders[i];
                      return ListTile(
                        dense: true,
                        leading: const CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.orange,
                          child: Icon(Icons.person, color: Colors.white, size: 16),
                        ),
                        title: Text(order.namaCustomer, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        subtitle: Text(
                          'Rp ${formatCurrency.format(order.totalHarga)} • ${order.metodePengiriman.toUpperCase()}',
                          style: const TextStyle(fontSize: 11),
                        ),
                        trailing: ElevatedButton(
                          onPressed: () {
                            context.read<OnlineOrderBloc>().add(ProcessOnlineOrder(order.id, 'processing'));
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            textStyle: const TextStyle(fontSize: 12),
                          ),
                          child: const Text('Proses'),
                        ),
                      );
                    },
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }
}

// ─── Dashboard Helpers ──────────────────────────────────────────────────────────

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final List<Color>? gradient;
  final bool isHighlight;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.gradient,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isHighlight && gradient != null) {
      return Expanded(
        flex: 2,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradient!,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(icon, color: Colors.white70, size: 18),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5), overflow: TextOverflow.ellipsis),
                ),
              ]),
              const SizedBox(height: 10),
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -1), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      );
    }

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? Theme.of(context).colorScheme.surfaceContainer : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white12 : const Color(0xFFE5E7EB),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 12),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.5), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Widget child;
  final VoidCallback? onViewAll;

  const _DashboardCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.child,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).colorScheme.surfaceContainer : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 12),
            child: Row(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                ),
                if (onViewAll != null)
                  TextButton(
                    onPressed: onViewAll,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                    ),
                    child: const Text('Lihat Semua', style: TextStyle(fontSize: 12)),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          child,
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState(this.message);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Text(message, style: const TextStyle(color: Colors.grey, fontSize: 13)),
      ),
    );
  }
}
