import 'package:equatable/equatable.dart';

import '../../../domain/entities/hutang_piutang.dart';

abstract class HutangState extends Equatable {
  const HutangState();
  @override
  List<Object?> get props => [];
}

class HutangInitial extends HutangState {}

class HutangLoading extends HutangState {}

class HutangLoaded extends HutangState {
  final List<HutangPiutang> hutangList;
  final String filterStatus;
  final double totalPiutang;

  const HutangLoaded({
    required this.hutangList,
    this.filterStatus = 'semua',
    this.totalPiutang = 0,
  });

  HutangLoaded copyWith({
    List<HutangPiutang>? hutangList,
    String? filterStatus,
    double? totalPiutang,
  }) {
    return HutangLoaded(
      hutangList: hutangList ?? this.hutangList,
      filterStatus: filterStatus ?? this.filterStatus,
      totalPiutang: totalPiutang ?? this.totalPiutang,
    );
  }

  List<HutangPiutang> get filteredList {
    if (filterStatus == 'semua') return hutangList;
    return hutangList.where((h) => h.status == filterStatus).toList();
  }

  double get totalBelumLunas => hutangList
      .where((h) => h.status == 'belum_lunas')
      .fold(0.0, (sum, h) => sum + h.jumlah);

  @override
  List<Object?> get props => [hutangList, filterStatus, totalPiutang];
}

class HutangSuccess extends HutangState {
  final String message;
  const HutangSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

class HutangError extends HutangState {
  final String message;
  const HutangError(this.message);
  @override
  List<Object?> get props => [message];
}
