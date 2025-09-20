part of 'cart_bloc.dart';

enum CartStatus {
  initial,
  loading,
  loaded,
  error,
  syncing,
  backup,
  restore,
}

enum CartAction {
  add,
  remove,
  update,
  clear,
  applyCoupon,
  refresh,
  extendSession,
  backup,
  restore,
  forceSync,
}

class CartState extends Equatable {
  final CartStatus status;
  final ShoppingCart? cart;
  final String? error;
  final CartAction? lastAction;
  final DateTime? lastUpdated;

  const CartState({
    this.status = CartStatus.initial,
    this.cart,
    this.error,
    this.lastAction,
    this.lastUpdated,
  });

  CartState copyWith({
    CartStatus? status,
    ShoppingCart? cart,
    String? error,
    CartAction? lastAction,
    DateTime? lastUpdated,
  }) {
    return CartState(
      status: status ?? this.status,
      cart: cart ?? this.cart,
      error: error ?? this.error,
      lastAction: lastAction ?? this.lastAction,
      lastUpdated: lastUpdated ?? DateTime.now(),
    );
  }

  bool get isLoading => status == CartStatus.loading;
  bool get isLoaded => status == CartStatus.loaded;
  bool get isSyncing => status == CartStatus.syncing;
  bool get isBackup => status == CartStatus.backup;
  bool get isRestore => status == CartStatus.restore;
  bool get isError => status == CartStatus.error;
  bool get isEmpty => cart?.isEmpty ?? true;
  bool get isNotEmpty => cart?.isNotEmpty ?? false;
  bool get isExpired => cart?.isExpired ?? false;
  bool get isExpiringSoon => cart?.isExpiringSoon ?? false;

  int get itemCount => cart?.itemCount ?? 0;
  double get subtotal => cart?.subtotal ?? 0;
  double get tax => cart?.tax ?? 0;
  double get shipping => cart?.shipping ?? 0;
  double get total => cart?.total ?? 0;
  String get currency => cart?.currency ?? 'USD';
  bool get hasCoupon => cart?.couponCode != null;
  double get discountAmount => cart?.discountAmount ?? 0;

  factory CartState.initial() {
    return const CartState(
      status: CartStatus.initial,
    );
  }

  @override
  List<Object?> get props => [
        status,
        cart,
        error,
        lastAction,
        lastUpdated,
      ];
}