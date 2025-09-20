import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import '../../../models/shopping_cart.dart';
import '../../../models/cart_item.dart';
import '../../../services/cart_service.dart';

part 'cart_event.dart';
part 'cart_state.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  final CartService _cartService;
  final Uuid _uuid = const Uuid();

  CartBloc(this._cartService) : super(const CartState.initial()) {
    on<CartLoaded>(_onCartLoaded);
    on<CartItemAdded>(_onCartItemAdded);
    on<CartItemRemoved>(_onCartItemRemoved);
    on<CartItemQuantityUpdated>(_onCartItemQuantityUpdated);
    on<CartCleared>(_onCartCleared);
    on<CouponApplied>(_onCouponApplied);
    on<CartRefreshed>(_onCartRefreshed);
    on<CartSessionExtended>(_onCartSessionExtended);
    on<CartBackupRequested>(_onCartBackupRequested);
    on<CartRestoreRequested>(_onCartRestoreRequested);
    on<CartSyncForced>(_onCartSyncForced);
  }

  Future<void> _onCartLoaded(CartLoaded event, Emitter<CartState> emit) async {
    try {
      emit(state.copyWith(status: CartStatus.loading));

      final cart = await _cartService.getCart(
        userId: event.userId,
        sessionId: event.sessionId,
      );

      emit(state.copyWith(
        status: CartStatus.loaded,
        cart: cart,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: CartStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onCartItemAdded(CartItemAdded event, Emitter<CartState> emit) async {
    try {
      emit(state.copyWith(status: CartStatus.loading));

      final updatedCart = await _cartService.addToCart(
        event.item,
        userId: state.cart?.userId,
        sessionId: state.cart?.sessionId,
      );

      emit(state.copyWith(
        status: CartStatus.loaded,
        cart: updatedCart,
        lastAction: CartAction.add,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: CartStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onCartItemRemoved(CartItemRemoved event, Emitter<CartState> emit) async {
    try {
      emit(state.copyWith(status: CartStatus.loading));

      final updatedCart = await _cartService.removeFromCart(
        event.itemId,
        userId: state.cart?.userId,
        sessionId: state.cart?.sessionId,
      );

      emit(state.copyWith(
        status: CartStatus.loaded,
        cart: updatedCart,
        lastAction: CartAction.remove,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: CartStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onCartItemQuantityUpdated(CartItemQuantityUpdated event, Emitter<CartState> emit) async {
    try {
      emit(state.copyWith(status: CartStatus.loading));

      final updatedCart = await _cartService.updateQuantity(
        event.itemId,
        event.quantity,
        userId: state.cart?.userId,
        sessionId: state.cart?.sessionId,
      );

      emit(state.copyWith(
        status: CartStatus.loaded,
        cart: updatedCart,
        lastAction: CartAction.update,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: CartStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onCartCleared(CartCleared event, Emitter<CartState> emit) async {
    try {
      emit(state.copyWith(status: CartStatus.loading));

      final updatedCart = await _cartService.clearCart(
        userId: state.cart?.userId,
        sessionId: state.cart?.sessionId,
      );

      emit(state.copyWith(
        status: CartStatus.loaded,
        cart: updatedCart,
        lastAction: CartAction.clear,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: CartStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onCouponApplied(CouponApplied event, Emitter<CartState> emit) async {
    try {
      emit(state.copyWith(status: CartStatus.loading));

      final updatedCart = await _cartService.applyCoupon(
        event.couponCode,
        userId: state.cart?.userId,
        sessionId: state.cart?.sessionId,
      );

      emit(state.copyWith(
        status: CartStatus.loaded,
        cart: updatedCart,
        lastAction: CartAction.applyCoupon,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: CartStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onCartRefreshed(CartRefreshed event, Emitter<CartState> emit) async {
    try {
      emit(state.copyWith(status: CartStatus.loading));

      final cart = await _cartService.getCart(
        userId: state.cart?.userId,
        sessionId: state.cart?.sessionId,
      );

      emit(state.copyWith(
        status: CartStatus.loaded,
        cart: cart,
        lastAction: CartAction.refresh,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: CartStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onCartSessionExtended(CartSessionExtended event, Emitter<CartState> emit) async {
    try {
      if (state.cart != null) {
        await _cartService.extendSession(
          state.cart!.sessionId,
          event.extension,
        );

        emit(state.copyWith(
          status: CartStatus.loaded,
          lastAction: CartAction.extendSession,
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: CartStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onCartBackupRequested(CartBackupRequested event, Emitter<CartState> emit) async {
    try {
      if (state.cart != null) {
        await _cartService.backupCart(state.cart!);

        emit(state.copyWith(
          status: CartStatus.loaded,
          lastAction: CartAction.backup,
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: CartStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onCartRestoreRequested(CartRestoreRequested event, Emitter<CartState> emit) async {
    try {
      emit(state.copyWith(status: CartStatus.loading));

      final restoredCart = await _cartService.restoreCart(event.cartId);
      if (restoredCart != null) {
        emit(state.copyWith(
          status: CartStatus.loaded,
          cart: restoredCart,
          lastAction: CartAction.restore,
        ));
      } else {
        emit(state.copyWith(
          status: CartStatus.error,
          error: 'Cart not found for restore',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: CartStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onCartSyncForced(CartSyncForced event, Emitter<CartState> emit) async {
    try {
      await _cartService.forceSync();

      emit(state.copyWith(
        status: CartStatus.loaded,
        lastAction: CartAction.forceSync,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: CartStatus.error,
        error: e.toString(),
      ));
    }
  }

  void setCurrentUser(String userId) {
    _cartService.setCurrentUser(userId);
  }

  void clearCurrentUser() {
    _cartService.clearCurrentUser();
  }
}