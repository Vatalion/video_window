import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/checkout_bloc.dart';
import '../bloc/checkout_state.dart';
import '../../domain/models/payment_model.dart';
import '../../domain/models/checkout_security_model.dart';

class CheckoutCompletionWidget extends StatelessWidget {
  final String orderId;
  final PaymentTransactionModel transaction;
  final CheckoutSessionModel session;
  final SecurityContextModel securityContext;
  final Function() onContinueShopping;
  final Function() onViewOrderDetails;
  final Function() onDownloadReceipt;
  final Function() onShareOrder;

  const CheckoutCompletionWidget({
    required this.orderId,
    required this.transaction,
    required this.session,
    required this.securityContext,
    required this.onContinueShopping,
    required this.onViewOrderDetails,
    required this.onDownloadReceipt,
    required this.onShareOrder,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocListener<CheckoutBloc, CheckoutState>(
      listener: (context, state) {
        // Handle any post-completion state changes
      },
      child: Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              _buildSuccessHeader(),
              _buildOrderDetails(),
              _buildSecurityVerification(),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          // Success animation container
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.green.shade200,
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                Icons.check_circle,
                color: Colors.green.shade600,
                size: 64,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Order Confirmed!',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Thank you for your purchase',
            style: TextStyle(
              fontSize: 16,
              color: Colors.green.shade700,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green.shade200,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Order #${orderId.toUpperCase()}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.green.shade800,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDetails() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Details',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildOrderSummary(),
          const SizedBox(height: 24),
          _buildPaymentConfirmation(),
          const SizedBox(height: 24),
          _buildDeliveryEstimate(),
        ],
      ),
    );
  }

  Widget _buildOrderSummary() {
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
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Payment Summary',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  DateFormat('MMM dd, yyyy').format(transaction.createdAt),
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildPricingRow('Subtotal', '\$${transaction.amount.toStringAsFixed(2)}'),
            _buildPricingRow('Shipping', '\$0.00'), // This would come from order summary
            _buildPricingRow('Tax', '\$0.00'), // This would come from order summary
            const Divider(height: 24),
            _buildPricingRow(
              'Total',
              '\$${transaction.amount.toStringAsFixed(2)}',
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
              color: isTotal ? Colors.black87 : Colors.grey.shade700,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 18 : 14,
              color: isTotal ? Theme.of(context).primaryColor : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentConfirmation() {
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
                  Icons.payment,
                  color: Colors.green.shade700,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Payment Confirmation',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Paid',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 48,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Center(
                    child: Icon(
                      _getPaymentIcon(),
                      color: Colors.grey.shade700,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '•••• •••• •••• ${transaction.transactionId.substring(transaction.transactionId.length - 4)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontFamily: 'monospace',
                        ),
                      ),
                      Text(
                        'Transaction ID: ${transaction.transactionId}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
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
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Payment verified and secured',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryEstimate() {
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
                  Icons.local_shipping_outlined,
                  color: Colors.blue.shade700,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Delivery Information',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.calendar_today_outlined,
                    color: Colors.blue.shade700,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Estimated Delivery',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getDeliveryDateRange(),
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityVerification() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.security,
                  color: Colors.grey.shade700,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Security Verification',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green.shade600,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Transaction verified and secured',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green.shade600,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Data encrypted end-to-end',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green.shade600,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'PCI compliant payment processing',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onContinueShopping,
              icon: const Icon(Icons.shopping_bag_outlined),
              label: const Text('Continue Shopping'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onViewOrderDetails,
                  icon: const Icon(Icons.receipt_long_outlined, size: 18),
                  label: const Text('View Details'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onDownloadReceipt,
                  icon: const Icon(Icons.download_outlined, size: 18),
                  label: const Text('Receipt'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onShareOrder,
                  icon: const Icon(Icons.share_outlined, size: 18),
                  label: const Text('Share'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Order confirmation and receipt sent to your email',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  IconData _getPaymentIcon() {
    // This would determine the payment icon based on the payment method
    return Icons.credit_card;
  }

  String _getDeliveryDateRange() {
    final now = DateTime.now();
    final minDelivery = now.add(const Duration(days: 3));
    final maxDelivery = now.add(const Duration(days: 7));

    return '${DateFormat('MMM dd').format(minDelivery)} - ${DateFormat('MMM dd').format(maxDelivery)}';
  }
}

class OrderSuccessAnimation extends StatefulWidget {
  final Widget child;

  const OrderSuccessAnimation({required this.child, super.key});

  @override
  State<OrderSuccessAnimation> createState() => _OrderSuccessAnimationState();
}

class _OrderSuccessAnimationState extends State<OrderSuccessAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}