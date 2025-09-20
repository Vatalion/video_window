import 'package:flutter/material.dart';
import '../../models/cart/cart.dart';
import '../../models/cart/cart_item.dart';
import '../../services/cart/cart_service.dart';

class BulkOperationsWidget extends StatefulWidget {
  final CartService cartService;
  final Function(List<CartItem>) onSelectionChanged;

  const BulkOperationsWidget({
    Key? key,
    required this.cartService,
    required this.onSelectionChanged,
  }) : super(key: key);

  @override
  _BulkOperationsWidgetState createState() => _BulkOperationsWidgetState();
}

class _BulkOperationsWidgetState extends State<BulkOperationsWidget> {
  Set<String> _selectedItemIds = {};
  bool _isSelectAll = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.cartService,
      builder: (context, child) {
        final cart = widget.cartService.currentCart;
        if (cart == null || cart.isEmpty) {
          return const SizedBox.shrink();
        }

        return Card(
          margin: const EdgeInsets.all(8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: _isSelectAll,
                      onChanged: _handleSelectAll,
                    ),
                    Text(
                      'Select all (${cart.items.length})',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    if (_selectedItemIds.isNotEmpty)
                      Text(
                        '${_selectedItemIds.length} selected',
                        style: const TextStyle(color: Colors.blue),
                      ),
                  ],
                ),
                if (_selectedItemIds.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildBulkActions(),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBulkActions() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.delete_outline),
          label: const Text('Remove Selected'),
          onPressed: _handleBulkRemove,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red[50],
            foregroundColor: Colors.red,
          ),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.favorite_border),
          label: const Text('Save for Later'),
          onPressed: _handleBulkSaveForLater,
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.compare_arrows),
          label: const Text('Compare'),
          onPressed: _handleBulkCompare,
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.move_down),
          label: const Text('Move to Wishlist'),
          onPressed: _handleBulkMoveToWishlist,
        ),
      ],
    );
  }

  void _handleSelectAll(bool? selected) {
    final cart = widget.cartService.currentCart;
    if (cart == null) return;

    setState(() {
      _isSelectAll = selected ?? false;
      _selectedItemIds = _isSelectAll
          ? Set.from(cart.items.map((item) => item.id))
          : {};
    });

    widget.onSelectionChanged(_getSelectedItems());
  }

  void _toggleItemSelection(String itemId) {
    setState(() {
      if (_selectedItemIds.contains(itemId)) {
        _selectedItemIds.remove(itemId);
      } else {
        _selectedItemIds.add(itemId);
      }
      _isSelectAll = _selectedItemIds.length == widget.cartService.currentCart?.items.length;
    });

    widget.onSelectionChanged(_getSelectedItems());
  }

  List<CartItem> _getSelectedItems() {
    final cart = widget.cartService.currentCart;
    if (cart == null) return [];

    return cart.items.where((item) => _selectedItemIds.contains(item.id)).toList();
  }

  Future<void> _handleBulkRemove() async {
    final selectedItems = _getSelectedItems();
    if (selectedItems.isEmpty) return;

    final confirmed = await _showConfirmationDialog(
      'Remove Selected Items',
      'Are you sure you want to remove ${selectedItems.length} items from your cart?',
    );

    if (confirmed) {
      for (final item in selectedItems) {
        await widget.cartService.removeItem(item.id);
      }
      _clearSelection();
    }
  }

  Future<void> _handleBulkSaveForLater() async {
    final selectedItems = _getSelectedItems();
    if (selectedItems.isEmpty) return;

    for (final item in selectedItems) {
      await widget.cartService.removeItem(item.id);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${selectedItems.length} items saved for later'),
        duration: const Duration(seconds: 2),
      ),
    );
    _clearSelection();
  }

  Future<void> _handleBulkCompare() async {
    final selectedItems = _getSelectedItems();
    if (selectedItems.isEmpty) return;

    if (selectedItems.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least 2 items to compare'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProductComparisonPage(
          items: selectedItems,
        ),
      ),
    );
  }

  Future<void> _handleBulkMoveToWishlist() async {
    final selectedItems = _getSelectedItems();
    if (selectedItems.isEmpty) return;

    for (final item in selectedItems) {
      await widget.cartService.removeItem(item.id);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${selectedItems.length} items moved to wishlist'),
        duration: const Duration(seconds: 2),
      ),
    );
    _clearSelection();
  }

  void _clearSelection() {
    setState(() {
      _selectedItemIds.clear();
      _isSelectAll = false;
    });
    widget.onSelectionChanged([]);
  }

  Future<bool> _showConfirmationDialog(String title, String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Remove'),
              ),
            ],
          ),
        ) ??
        false;
  }
}

class BulkCartItemWidget extends StatefulWidget {
  final CartItem item;
  final bool isSelected;
  final Function(bool) onSelectionChanged;
  final Function(int) onUpdateQuantity;
  final VoidCallback onRemove;

  const BulkCartItemWidget({
    Key? key,
    required this.item,
    required this.isSelected,
    required this.onSelectionChanged,
    required this.onUpdateQuantity,
    required this.onRemove,
  }) : super(key: key);

  @override
  _BulkCartItemWidgetState createState() => _BulkCartItemWidgetState();
}

class _BulkCartItemWidgetState extends State<BulkCartItemWidget> {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Checkbox(
              value: widget.isSelected,
              onChanged: widget.onSelectionChanged,
            ),
            const SizedBox(width: 12),
            _buildItemImage(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildItemInfo(),
                  const SizedBox(height: 8),
                  _buildQuantityControls(),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _buildRemoveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildItemImage() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: widget.item.imageUrl != null
          ? Image.network(
              widget.item.imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.image_not_supported, size: 32, color: Colors.grey);
              },
            )
          : const Icon(Icons.image, size: 32, color: Colors.grey),
    );
  }

  Widget _buildItemInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.item.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          '\$${widget.item.price.toStringAsFixed(2)}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildQuantityControls() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: widget.item.quantity > 1
              ? () => widget.onUpdateQuantity(widget.item.quantity - 1)
              : null,
          iconSize: 20,
        ),
        Text('${widget.item.quantity}'),
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          onPressed: () => widget.onUpdateQuantity(widget.item.quantity + 1),
          iconSize: 20,
        ),
      ],
    );
  }

  Widget _buildRemoveButton() {
    return IconButton(
      icon: const Icon(Icons.delete_outline, color: Colors.red),
      onPressed: widget.onRemove,
    );
  }
}

class ProductComparisonPage extends StatelessWidget {
  final List<CartItem> items;

  const ProductComparisonPage({
    Key? key,
    required this.items,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Compare ${items.length} Products'),
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildComparisonCriteria(),
            ...items.map((item) => _buildProductColumn(item)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonCriteria() {
    return Container(
      width: 150,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ComparisonHeader(text: ''),
          _ComparisonRow(text: 'Product'),
          _ComparisonRow(text: 'Price'),
          _ComparisonRow(text: 'Quantity'),
          _ComparisonRow(text: 'Total'),
          _ComparisonRow(text: 'Description'),
        ],
      ),
    );
  }

  Widget _buildProductColumn(CartItem item) {
    return Container(
      width: 200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ComparisonHeader(text: 'Product ${items.indexOf(item) + 1}'),
          _ComparisonRow(text: item.name),
          _ComparisonRow(text: '\$${item.price.toStringAsFixed(2)}'),
          _ComparisonRow(text: '${item.quantity}'),
          _ComparisonRow(text: '\$${item.totalPrice.toStringAsFixed(2)}'),
          _ComparisonRow(text: item.description),
        ],
      ),
    );
  }
}

class _ComparisonHeader extends StatelessWidget {
  final String text;

  const _ComparisonHeader({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  final String text;

  const _ComparisonRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}