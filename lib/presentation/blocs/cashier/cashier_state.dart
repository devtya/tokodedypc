import 'package:equatable/equatable.dart';

import '../../../domain/usecases/transaksi/buat_transaksi.dart';

class CashierDiscountHelper {
  static double hitungTotalDiskon(double subtotal, int tipe, double value) {
    if (tipe == 1) return subtotal * value / 100;
    if (tipe == 2) return value;
    return 0;
  }
}

abstract class CashierState extends Equatable {
  const CashierState();
  @override
  List<Object?> get props => [];
}

class CashierInitial extends CashierState {}

class CashierLoading extends CashierState {}

class CashierReady extends CashierState {
  final List<CartItem> cart;
  final double jumlahBayar;
  final int globalDiskonTipe;
  final double globalDiskonValue;

  const CashierReady({
    this.cart = const [],
    this.jumlahBayar = 0,
    this.globalDiskonTipe = 0,
    this.globalDiskonValue = 0,
  });

  double get total => cart.fold(0.0, (sum, item) => sum + item.subtotal);
  double get totalDiskon => cart.fold(
    0.0,
    (sum, item) =>
        sum +
        CashierDiscountHelper.hitungTotalDiskon(
          item.subtotal,
          item.diskonTipe,
          item.diskonValue,
        ),
  );
  double get totalSetelahDiskon {
    final subtotal = total - totalDiskon;
    return subtotal -
        CashierDiscountHelper.hitungTotalDiskon(
          subtotal,
          globalDiskonTipe,
          globalDiskonValue,
        );
  }

  double get kembalian =>
      jumlahBayar >= totalSetelahDiskon ? jumlahBayar - totalSetelahDiskon : 0;

  CashierReady copyWith({
    List<CartItem>? cart,
    double? jumlahBayar,
    int? globalDiskonTipe,
    double? globalDiskonValue,
  }) {
    return CashierReady(
      cart: cart ?? this.cart,
      jumlahBayar: jumlahBayar ?? this.jumlahBayar,
      globalDiskonTipe: globalDiskonTipe ?? this.globalDiskonTipe,
      globalDiskonValue: globalDiskonValue ?? this.globalDiskonValue,
    );
  }

  @override
  List<Object?> get props => [cart, jumlahBayar, globalDiskonTipe, globalDiskonValue];
}

class CashierSuccess extends CashierState {
  final String transaksiId;
  final bool isHutang;
  const CashierSuccess(this.transaksiId, {this.isHutang = false});
  @override
  List<Object?> get props => [transaksiId, isHutang];
}

class CashierError extends CashierState {
  final String message;
  final List<CartItem> cart;
  final double jumlahBayar;
  final int globalDiskonTipe;
  final double globalDiskonValue;

  const CashierError(
    this.message, {
    this.cart = const [],
    this.jumlahBayar = 0,
    this.globalDiskonTipe = 0,
    this.globalDiskonValue = 0,
  });

  double get total => cart.fold(0.0, (sum, item) => sum + item.subtotal);
  double get totalDiskon => cart.fold(
    0.0,
    (sum, item) =>
        sum +
        CashierDiscountHelper.hitungTotalDiskon(
          item.subtotal,
          item.diskonTipe,
          item.diskonValue,
        ),
  );
  double get totalSetelahDiskon {
    final subtotal = total - totalDiskon;
    return subtotal -
        CashierDiscountHelper.hitungTotalDiskon(
          subtotal,
          globalDiskonTipe,
          globalDiskonValue,
        );
  }

  double get kembalian =>
      jumlahBayar >= totalSetelahDiskon ? jumlahBayar - totalSetelahDiskon : 0;

  @override
  List<Object?> get props => [message, cart, jumlahBayar, globalDiskonTipe, globalDiskonValue];
}
