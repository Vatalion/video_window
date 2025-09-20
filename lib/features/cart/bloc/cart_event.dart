part of 'cart_bloc.dart';

abstract class CartEvent extends Equatable {
  const CartEvent();

  @override
  List<Object> get props => [];
}

class CartLoaded extends CartEvent {
  final String? userId;
  final String? sessionId;

  const CartLoaded({this.userId, this.sessionId});

  @override
  List<Object?> get props => [userId, sessionId];
}

class CartItemAdded extends CartEvent {
  final CartItem item;

  const CartItemAdded(this.item);

  @override
  List<Object> get props => [item];
}

class CartItemRemoved extends CartEvent {
  final String itemId;

  const CartItemRemoved(this.itemId);

  @override
  List<Object> get props => [itemId];
}

class CartItemQuantityUpdated extends CartEvent {
  final String itemId;
  final int quantity;

  const CartItemQuantityUpdated(this.itemId, this.quantity);

  @override
  List<Object> get props => [itemId, quantity];
}

class CartCleared extends CartEvent {
  const CartCleared();
}

class CouponApplied extends CartEvent {
  final String couponCode;

  const CouponApplied(this.couponCode);

  @override
  List<Object> get props => [couponCode];
}

class CartRefreshed extends CartEvent {
  const CartRefreshed();
}

class CartSessionExtended extends CartEvent {
  final Duration extension;

  const CartSessionExtended(this.extension);

  @override
  List<Object> get props => [extension];
}

class CartBackupRequested extends CartEvent {
  const CartBackupRequested();
}

class CartRestoreRequested extends CartEvent {
  final String cartId;

  const CartRestoreRequested(this.cartId);

  @override
  List<Object> get props => [cartId];
}

class CartSyncForced extends CartEvent {
  const CartSyncForced();
}