import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../models/product/product.dart';
import '../../models/cart/cart.dart';
import '../../models/cart/cart_item.dart';
import '../cart/cart_service.dart';

class ProductService extends ChangeNotifier {
  List<Product> _products = [];
  List<Product> _featuredProducts = [];
  List<ProductRecommendation> _recommendations = [];
  bool _isLoading = false;
  String? _error;
  CartService? _cartService;
  WebSocketChannel? _inventoryChannel;

  List<Product> get products => _products;
  List<Product> get featuredProducts => _featuredProducts;
  List<ProductRecommendation> get recommendations => _recommendations;
  bool get isLoading => _isLoading;
  String? get error => _error;

  ProductService({CartService? cartService}) {
    _cartService = cartService;
    _initWebSocket();
  }

  Future<void> fetchProducts({String? categoryId, String? searchQuery, int page = 1, int limit = 20}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (categoryId != null) {
        queryParams['categoryId'] = categoryId;
      }

      if (searchQuery != null) {
        queryParams['search'] = searchQuery;
      }

      final uri = Uri.parse('https://api.example.com/products')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _products = (data['products'] as List)
            .map((product) => Product.fromJson(product))
            .toList();
      } else {
        throw Exception('Failed to load products: ${response.statusCode}');
      }
    } catch (e) {
      _error = 'Failed to fetch products: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchFeaturedProducts() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.example.com/products/featured'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _featuredProducts = (data['products'] as List)
            .map((product) => Product.fromJson(product))
            .toList();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to fetch featured products: $e');
      }
    }
  }

  Future<Product?> fetchProductById(String productId) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.example.com/products/$productId'),
      );

      if (response.statusCode == 200) {
        return Product.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Failed to fetch product: $e');
      }
      return null;
    }
  }

  Future<void> addToCart({
    required Product product,
    ProductVariant? variant,
    int quantity = 1,
  }) async {
    if (_cartService == null) return;

    try {
      final cartItem = CartItem(
        id: 'cart_${DateTime.now().millisecondsSinceEpoch}',
        productId: product.id,
        name: product.name,
        description: product.description,
        price: variant?.currentPrice ?? product.currentPrice,
        quantity: quantity,
        imageUrl: variant?.imageUrl ?? product.imageUrls.firstOrNull,
        variantAttributes: variant?.attributes,
        addedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _cartService!.addItem(cartItem);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to add product to cart: $e');
      }
    }
  }

  Future<void> fetchRecommendations() async {
    if (_cartService?.currentCart == null) return;

    try {
      final cartItems = _cartService!.currentCart!.items.map((item) => item.productId).toList();

      final response = await http.post(
        Uri.parse('https://api.example.com/products/recommendations'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'cartItems': cartItems,
          'userId': _cartService!.currentCart!.userId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _recommendations = (data['recommendations'] as List)
            .map((rec) => ProductRecommendation.fromJson(rec))
            .toList();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to fetch recommendations: $e');
      }
    }
  }

  Future<void> checkInventory(String productId) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.example.com/products/$productId/inventory'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _updateProductInventory(productId, data['availableQuantity'], data['inStock']);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to check inventory: $e');
      }
    }
  }

  void _updateProductInventory(String productId, int availableQuantity, bool inStock) {
    final productIndex = _products.indexWhere((p) => p.id == productId);
    if (productIndex >= 0) {
      _products[productIndex] = _products[productIndex].copyWith(
        availableQuantity: availableQuantity,
        inStock: inStock,
        updatedAt: DateTime.now(),
      );
      notifyListeners();
    }
  }

  void _initWebSocket() {
    try {
      _inventoryChannel = WebSocketChannel.connect(
        Uri.parse('wss://api.example.com/inventory-updates'),
      );

      _inventoryChannel!.stream.listen(
        (message) {
          final data = jsonDecode(message);
          if (data['type'] == 'inventory_update') {
            _updateProductInventory(
              data['productId'],
              data['availableQuantity'],
              data['inStock'],
            );
          }
        },
        onError: (error) {
          if (kDebugMode) {
            print('WebSocket error: $error');
          }
        },
        onDone: () {
          _attemptReconnect();
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('Failed to connect inventory WebSocket: $e');
      }
    }
  }

  void _attemptReconnect() {
    Future.delayed(const Duration(seconds: 5), () {
      _initWebSocket();
    });
  }

  List<Product> getProductsByCategory(String categoryId) {
    return _products.where((product) =>
        product.categories.any((category) => category.id == categoryId)).toList();
  }

  List<Product> searchProducts(String query) {
    final lowercaseQuery = query.toLowerCase();
    return _products.where((product) =>
        product.name.toLowerCase().contains(lowercaseQuery) ||
        product.description.toLowerCase().contains(lowercaseQuery)).toList();
  }

  Future<void> refreshInventory() async {
    for (final product in _products) {
      await checkInventory(product.id);
    }
  }

  @override
  void dispose() {
    _inventoryChannel?.sink.close();
    super.dispose();
  }
}