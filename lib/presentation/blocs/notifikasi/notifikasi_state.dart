import 'package:equatable/equatable.dart';
import '../../../domain/entities/notifikasi.dart';

abstract class NotifikasiState extends Equatable {
  const NotifikasiState();

  @override
  List<Object> get props => [];
}

class NotifikasiInitial extends NotifikasiState {}

class NotifikasiLoading extends NotifikasiState {}

class NotifikasiLoaded extends NotifikasiState {
  final List<Notifikasi> unreadNotifikasi;
  final List<Notifikasi> allNotifikasi;

  const NotifikasiLoaded({
    required this.unreadNotifikasi,
    required this.allNotifikasi,
  });

  @override
  List<Object> get props => [unreadNotifikasi, allNotifikasi];
}

class NotifikasiError extends NotifikasiState {
  final String message;

  const NotifikasiError(this.message);

  @override
  List<Object> get props => [message];
}
