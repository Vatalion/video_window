import 'package:flutter/material.dart';
import 'dart:math' show min;
import '../../domain/models/product.dart';
import '../../data/repositories/product_repository.dart';
import 'product_creation_screen.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final ProductRepository _repository = ProductRepository();
  List<Product> _products = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final products = await _repository.getProducts();
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load products: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadProducts,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadProducts,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _products.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ProductCreationScreen(),
                              ),
                            ).then((value) {
                              // Refresh the product list when returning from creation screen
                              _loadProducts();
                            });
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Create New Product'),
                        ),
                      );
                    }

                    final product = _products[index - 1];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        title: Text(product.name),
                        subtitle: Text(
                          '${product.description.substring(0, min(product.description.length, 100))}${product.description.length > 100 ? '...' : ''}\n'
                          'Price: ${product.price} ${product.currency}\n'
                          'Type: ${product.type.name}\n'
                          'Status: ${product.status.name}',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            // In a full implementation, this would navigate to an edit screen
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Edit functionality would go here')),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ProductCreationScreen(),
            ),
          ).then((value) {
            // Refresh the product list when returning from creation screen
            _loadProducts();
          });
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}