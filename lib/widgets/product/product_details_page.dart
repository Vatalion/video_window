import 'package:flutter/material.dart';
import '../../models/product/product.dart';
import '../../services/product/product_service.dart';

class ProductDetailsPage extends StatefulWidget {
  final Product product;
  final ProductService productService;

  const ProductDetailsPage({
    Key? key,
    required this.product,
    required this.productService,
  }) : super(key: key);

  @override
  _ProductDetailsPageState createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  bool _isLoading = false;
  int _selectedImageIndex = 0;
  int _quantity = 1;
  ProductVariant? _selectedVariant;
  PageController _pageController = PageController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareProduct,
          ),
          IconButton(
            icon: const Icon(Icons.favorite_border),
            onPressed: _toggleFavorite,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProductImages(),
            _buildProductInfo(),
            _buildPriceSection(),
            _buildVariantSelector(),
            _buildQuantitySelector(),
            _buildActionButtons(),
            _buildProductDetails(),
            _buildReviews(),
            _buildRecommendations(),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImages() {
    if (widget.product.imageUrls.isEmpty) {
      return Container(
        height: 300,
        color: Colors.grey[200],
        child: const Icon(Icons.image, size: 100, color: Colors.grey),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 300,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.product.imageUrls.length,
            onPageChanged: (index) {
              setState(() {
                _selectedImageIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return Image.network(
                widget.product.imageUrls[index],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.image_not_supported, size: 100, color: Colors.grey);
                },
              );
            },
          ),
        ),
        if (widget.product.imageUrls.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.product.imageUrls.length,
              (index) => Container(
                margin: const EdgeInsets.all(4),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index == _selectedImageIndex
                      ? Theme.of(context).primaryColor
                      : Colors.grey[300],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProductInfo() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.product.name,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            widget.product.description,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 16),
              const SizedBox(width: 4),
              Text(
                widget.product.rating.toStringAsFixed(1),
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(width: 4),
              Text(
                '(${widget.product.reviewCount} reviews)',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
          ),
          if (!widget.product.inStock)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Out of Stock',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPriceSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.product.hasSale) ...[
            Text(
              '\$${widget.product.price.toStringAsFixed(2)}',
              style: TextStyle(
                decoration: TextDecoration.lineThrough,
                color: Colors.grey[600],
                fontSize: 20,
              ),
            ),
            Text(
              '\$${widget.product.currentPrice.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${widget.product.discountPercentage.toStringAsFixed(0)}% OFF',
                style: const TextStyle(color: Colors.red, fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
          ] else
            Text(
              '\$${widget.product.currentPrice.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          Text(
            'In Stock: ${widget.product.availableQuantity}',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildVariantSelector() {
    if (widget.product.variants.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Variants',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: widget.product.variants.map((variant) {
              final isSelected = _selectedVariant?.id == variant.id;
              return ChoiceChip(
                label: Text(variant.name),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedVariant = selected ? variant : null;
                  });
                },
                backgroundColor: isSelected ? Theme.of(context).primaryColor.withOpacity(0.2) : null,
                selectedColor: Theme.of(context).primaryColor,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantitySelector() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quantity',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: _quantity > 1
                    ? () => setState(() => _quantity--)
                    : null,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '$_quantity',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: _quantity < widget.product.availableQuantity
                    ? () => setState(() => _quantity++)
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: !widget.product.inStock || _isLoading ? null : _handleAddToCart,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Add to Cart'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 1,
            child: OutlinedButton(
              onPressed: _handleBuyNow,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Buy Now'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductDetails() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Product Details',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            widget.product.description,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildReviews() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Reviews',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: _showAllReviews,
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 24),
              const SizedBox(width: 4),
              Text(
                widget.product.rating.toStringAsFixed(1),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              Text(
                'out of 5',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Frequently Bought Together',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: widget.productService.recommendations.take(5).length,
              itemBuilder: (context, index) {
                final recommendation = widget.productService.recommendations[index];
                return Container(
                  width: 150,
                  margin: const EdgeInsets.only(right: 8),
                  child: Card(
                    child: Column(
                      children: [
                        Expanded(
                          child: Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.image, size: 64, color: Colors.grey),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            'Product ${recommendation.productId}',
                            style: const TextStyle(fontSize: 12),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAddToCart() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await widget.productService.addToCart(
        product: widget.product,
        variant: _selectedVariant,
        quantity: _quantity,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product added to cart'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add to cart: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleBuyNow() {
    _handleAddToCart();
  }

  void _shareProduct() {
  }

  void _toggleFavorite() {
  }

  void _showAllReviews() {
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}