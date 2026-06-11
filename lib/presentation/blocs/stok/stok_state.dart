import 'package:equatable/equatable.dart';

import '../../../domain/entities/riwayat_stok.dart';

abstract class StokState extends Equatable {
  const StokState();
  @override
  List<Object?> get props => [];
}

class StokInitial extends StokState {}

class StokLoading extends StokState {}

class StokLoaded extends StokState {
  final List<RiwayatStok> riwayatList;
  const StokLoaded(this.riwayatList);
  @override
  List<Object?> get props => [riwayatList];
}

class StokError extends StokState {
  final String message;
  const StokError(this.message);
  @override
  List<Object?> get props => [message];
}

class StokOperationSuccess extends StokState {
  final String message;
  const StokOperationSuccess(this.message);
  @override
  List<Object?> get props => [message];
}
