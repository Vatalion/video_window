import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/models/order_summary_model.dart';
import '../../domain/models/payment_model.dart';

class OrderSummaryWidget extends StatelessWidget {
  final OrderSummaryModel orderSummary;
  final bool isLoading;
  final bool showItems;
  final bool showActions;
  final VoidCallback? onEditCart;
  final VoidCallback? onApplyCoupon;
  final VoidCallback? onEditShipping;

  const OrderSummaryWidget({
    required this.orderSummary,
    this.isLoading = false,
    this.showItems = true,
    this.showActions = true,
    this.onEditCart,
    this.onApplyCoupon,
    this.onEditShipping,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.receipt_long,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Order Summary',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (isLoading)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (showItems && orderSummary.items.isNotEmpty) ...[
              _buildItemsList(),
              const Divider(height: 24),
            ],
            _buildPricingBreakdown(),
            const SizedBox(height: 16),
            _buildTotalSection(),
            if (showActions) ...[
              const SizedBox(height: 16),
              _buildActionButtons(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildItemsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Items (${orderSummary.totalItems})',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (onEditCart != null)
              TextButton(
                onPressed: onEditCart,
                child: const Text('Edit'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: orderSummary.items.length > 3 ? 3 : orderSummary.items.length,
          separatorBuilder: (context, index) => const Divider(height: 16),
          itemBuilder: (context, index) {
            final item = orderSummary.items[index];
            return _buildItemRow(item);
          },
        ),
        if (orderSummary.items.length > 3) ...[
          const SizedBox(height: 8),
          Text(
            '+${orderSummary.items.length - 3} more items',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildItemRow(OrderItemModel item) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product image placeholder
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: item.productImage != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    item.productImage!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.image_not_supported,
                        color: Colors.grey.shade400,
                      );
                    },
                  ),
                )
              : Icon(
                  Icons.inventory_2_outlined,
                  color: Colors.grey.shade400,
                ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.productName,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'Qty: ${item.quantity}',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
              if (item.variations.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  _formatVariations(item.variations),
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '\$${item.subtotal.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '\$${item.unitPrice.toStringAsFixed(2)} each',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPricingBreakdown() {
    return Column(
      children: [
        _buildPricingRow('Subtotal', orderSummary.formattedSubtotal),
        if (orderSummary.hasShippingCost)
          _buildPricingRow(
            'Shipping',
            orderSummary.formattedShipping,
            onEdit: onEditShipping,
          ),
        if (orderSummary.hasTax)
          _buildPricingRow('Tax', orderSummary.formattedTax),
        if (orderSummary.hasDiscount)
          _buildPricingRow(
            'Discount',
            orderSummary.formattedDiscount,
            isDiscount: true,
          ),
        const SizedBox(height: 8),
        const Divider(),
      ],
    );
  }

  Widget _buildPricingRow(
    String label,
    String value, {
    bool isDiscount = false,
    VoidCallback? onEdit,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isDiscount ? Colors.green.shade700 : Colors.grey.shade700,
                  fontWeight: isDiscount ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
              if (onEdit != null) ...[
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: onEdit,
                  child: Icon(
                    Icons.edit_outlined,
                    size: 14,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ],
          ),
          Text(
            value,
            style: TextStyle(
              color: isDiscount ? Colors.green.shade700 : Colors.grey.shade700,
              fontWeight: isDiscount ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Total',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
          Text(
            orderSummary.formattedTotal,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        if (onApplyCoupon != null)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onApplyCoupon,
              icon: const Icon(Icons.local_offer_outlined),
              label: const Text('Apply Coupon'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        if (onApplyCoupon != null) const SizedBox(height: 8),
        Row(
          children: [
            if (onEditCart != null)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onEditCart,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit Cart'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            if (onEditCart != null) const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  // This would typically trigger the next checkout step
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Proceeding to payment...'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.payment),
                label: const Text('Proceed to Payment'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatVariations(Map<String, dynamic> variations) {
    final formattedVariations = variations.entries
        .where((entry) => entry.value != null && entry.value.toString().isNotEmpty)
        .map((entry) => '${entry.key}: ${entry.value}')
        .join(', ');
    return formattedVariations.isNotEmpty ? '($formattedVariations)' : '';
  }
}

class SecureOrderSummaryWidget extends StatelessWidget {
  final OrderSummaryModel orderSummary;
  final bool isLoading;
  final String sessionId;
  final bool showSecurityBadge;
  final VoidCallback? onEditCart;
  final VoidCallback? onApplyCoupon;
  final VoidCallback? onEditShipping;

  const SecureOrderSummaryWidget({
    required this.orderSummary,
    required this.sessionId,
    this.isLoading = false,
    this.showSecurityBadge = true,
    this.onEditCart,
    this.onApplyCoupon,
    this.onEditShipping,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (showSecurityBadge) _buildSecurityBadge(context),
        OrderSummaryWidget(
          orderSummary: orderSummary,
          isLoading: isLoading,
          showItems: true,
          showActions: true,
          onEditCart: onEditCart,
          onApplyCoupon: onApplyCoupon,
          onEditShipping: onEditShipping,
        ),
        const SizedBox(height: 16),
        _buildSecurityInfo(context),
      ],
    );
  }

  Widget _buildSecurityBadge(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.verified,
            color: Colors.green.shade700,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Secure Checkout',
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Your payment information is encrypted and protected',
                  style: TextStyle(
                    color: Colors.green.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.lock_outline,
            color: Colors.green.shade700,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.security,
                color: Colors.grey.shade600,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                'Security Information',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildSecurityInfoRow('Session ID', _obfuscateSessionId(sessionId)),
          _buildSecurityInfoRow(
            'Last Updated',
            DateFormat('MMM dd, yyyy HH:mm').format(orderSummary.calculatedAt),
          ),
          _buildSecurityInfoRow(
            'Calculation Hash',
            _obfuscateHash(orderSummary.calculationHash),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _obfuscateSessionId(String sessionId) {
    if (sessionId.length <= 8) return sessionId;
    return '${sessionId.substring(0, 4)}...${sessionId.substring(sessionId.length - 4)}';
  }

  String _obfuscateHash(String hash) {
    if (hash.length <= 8) return hash;
    return '${hash.substring(0, 4)}...${hash.substring(hash.length - 4)}';
  }
}