import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/cart_bloc.dart';
import '../bloc/cart_event.dart';
import '../bloc/cart_state.dart';
import '../../../models/cart_item.dart';
import '../../../models/shopping_cart.dart';

class CartWidget extends StatefulWidget {
  final String? userId;
  final String? sessionId;

  const CartWidget({
    super.key,
    this.userId,
    this.sessionId,
  });

  @override
  State<CartWidget> createState() => _CartWidgetState();
}

class _CartWidgetState extends State<CartWidget> {
  late CartBloc _cartBloc;

  @override
  void initState() {
    super.initState();
    _cartBloc = CartBloc(CartService());
    _cartBloc.add(CartLoaded(
      userId: widget.userId,
      sessionId: widget.sessionId,
    ));
  }

  @override
  void dispose() {
    _cartBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => _cartBloc,
      child: CartContent(
        userId: widget.userId,
        sessionId: widget.sessionId,
      ),
    );
  }
}

class CartContent extends StatelessWidget {
  final String? userId;
  final String? sessionId;

  const CartContent({
    super.key,
    this.userId,
    this.sessionId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartBloc, CartState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.isError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Error loading cart',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  state.error ?? 'Unknown error',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context.read<CartBloc>().add(CartLoaded(
                      userId: userId,
                      sessionId: sessionId,
                    ));
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (state.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'Your cart is empty',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Add some items to get started',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.cart!.items.length,
                itemBuilder: (context, index) {
                  final item = state.cart!.items[index];
                  return CartItemWidget(
                    item: item,
                    onQuantityChanged: (quantity) {
                      context.read<CartBloc>().add(
                        CartItemQuantityUpdated(item.id, quantity),
                      );
                    },
                    onRemove: () {
                      context.read<CartBloc>().add(CartItemRemoved(item.id));
                    },
                  );
                },
              ),
            ),
            _buildCartSummary(context, state.cart!),
          ],
        );
      },
    );
  }

  Widget _buildCartSummary(BuildContext context, ShoppingCart cart) {
    final currencyFormat = NumberFormat.currency(symbol: cart.currency);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Subtotal (${cart.itemCount} items)'),
              Text(currencyFormat.format(cart.subtotal)),
            ],
          ),
          if (cart.tax > 0)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tax'),
                Text(currencyFormat.format(cart.tax)),
              ],
            ),
          if (cart.shipping > 0)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Shipping'),
                Text(currencyFormat.format(cart.shipping)),
              ],
            ),
          if (cart.discountAmount != null && cart.discountAmount! > 0)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Discount'),
                Text(
                  '-${currencyFormat.format(cart.discountAmount)}',
                  style: const TextStyle(color: Colors.green),
                ),
              ],
            ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(
                currencyFormat.format(cart.total),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    context.read<CartBloc>().add(CartCleared());
                  },
                  child: const Text('Clear Cart'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // Handle checkout
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Checkout functionality coming soon!'),
                      ),
                    );
                  },
                  child: const Text('Checkout'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CartItemWidget extends StatelessWidget {
  final CartItem item;
  final Function(int) onQuantityChanged;
  final VoidCallback onRemove;

  const CartItemWidget({
    super.key,
    required this.item,
    required this.onQuantityChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: 'USD');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                item.imageUrl,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image_not_supported),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    currencyFormat.format(item.price),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (item.variantId != null)
                    Text(
                      'Variant: ${item.variantId}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
            Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: item.quantity > 1
                          ? () => onQuantityChanged(item.quantity - 1)
                          : null,
                      icon: const Icon(Icons.remove),
                      iconSize: 18,
                    ),
                    Text('${item.quantity}'),
                    IconButton(
                      onPressed: () => onQuantityChanged(item.quantity + 1),
                      icon: const Icon(Icons.add),
                      iconSize: 18,
                    ),
                  ],
                ),
                Text(
                  currencyFormat.format(item.totalPrice),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.delete_outline),
              color: Colors.red,
            ),
          ],
        ),
      ),
    );
  }
}