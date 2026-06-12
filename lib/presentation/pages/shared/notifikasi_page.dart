import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../blocs/notifikasi/notifikasi_bloc.dart';
import '../../blocs/notifikasi/notifikasi_event.dart';
import '../../blocs/notifikasi/notifikasi_state.dart';

/// Widget notifikasi untuk ditampilkan sebagai dropdown popup dari TopBar.
/// Tidak menggunakan Scaffold.
class NotifikasiPage extends StatefulWidget {
  const NotifikasiPage({super.key});

  @override
  State<NotifikasiPage> createState() => _NotifikasiPageState();
}

class _NotifikasiPageState extends State<NotifikasiPage> {
  final _dateFormat = DateFormat('dd MMM yyyy, HH:mm');

  @override
  void initState() {
    super.initState();
    context.read<NotifikasiBloc>().add(LoadNotifikasi());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotifikasiBloc, NotifikasiState>(
      builder: (context, state) {
        if (state is NotifikasiLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is NotifikasiLoaded) {
          final items = state.allNotifikasi;
          if (items.isEmpty) {
            return const Center(child: Text('Belum ada notifikasi.'));
          }

          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final notif = items[index];
              final bool isWarning = notif.tipe == 'WARNING';

              return ListTile(
                dense: true,
                tileColor: notif.isRead
                    ? null
                    : AppTheme.surface.withValues(alpha: 0.5),
                leading: CircleAvatar(
                  radius: 16,
                  backgroundColor: isWarning
                      ? AppTheme.warningRed.withValues(alpha: 0.2)
                      : AppTheme.primaryGreen.withValues(alpha: 0.2),
                  child: Icon(
                    isWarning ? Icons.warning_amber_rounded : Icons.info_outline,
                    color: isWarning ? AppTheme.warningRed : AppTheme.primaryGreen,
                    size: 16,
                  ),
                ),
                title: Text(
                  notif.judul,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: notif.isRead ? FontWeight.normal : FontWeight.bold,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 2),
                    Text(notif.pesan, style: const TextStyle(fontSize: 12)),
                    const SizedBox(height: 2),
                    Text(
                      _dateFormat.format(notif.createdAt ?? DateTime.now()),
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                    ),
                  ],
                ),
                onTap: () {
                  if (!notif.isRead) {
                    context.read<NotifikasiBloc>().add(MarkNotifikasiAsRead(notif.id!));
                  }
                },
              );
            },
          );
        }
        if (state is NotifikasiError) {
          return Center(child: Text(state.message));
        }
        return const SizedBox();
      },
    );
  }
}
