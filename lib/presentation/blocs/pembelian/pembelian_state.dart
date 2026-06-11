import 'package:equatable/equatable.dart';

import '../../../domain/entities/pembelian.dart';

abstract class PembelianState extends Equatable {
  const PembelianState();
  @override
  List<Object?> get props => [];
}

class PembelianInitial extends PembelianState {}

class PembelianLoading extends PembelianState {}

class PembelianLoaded extends PembelianState {
  final List<Pembelian> list;
  const PembelianLoaded(this.list);
  @override
  List<Object?> get props => [list];
}

class PembelianSuccess extends PembelianState {
  final String message;
  const PembelianSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

class PembelianError extends PembelianState {
  final String message;
  const PembelianError(this.message);
  @override
  List<Object?> get props => [message];
}
