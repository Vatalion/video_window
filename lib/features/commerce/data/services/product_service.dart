import 'package:flutter/material.dart';
import '../../domain/models/product.dart';

class ProductService {
  // Mock service implementation - in real app this would connect to backend

  Future<List<Product>> getProducts() async {
    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 500));

    // Return mock data
    return [
      Product(
        id: '1',
        name: 'Sample Product 1',
        description: 'This is a sample physical product',
        type: ProductType.physical,
        media: [
          ProductMedia(
            id: '1',
            url: 'https://example.com/images/product1.jpg',
            type: MediaType.image,
            altText: 'Product 1 image',
          ),
        ],
        price: 29.99,
        currency: 'USD',
        stockQuantity: 100,
        status: ProductStatus.published,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now().subtract(const Duration(days: 15)),
        variants: [
          ProductVariant(
            id: '1',
            name: 'Size: Small',
            options: {'size': 'small'},
            price: 29.99,
            stockQuantity: 30,
          ),
          ProductVariant(
            id: '2',
            name: 'Size: Medium',
            options: {'size': 'medium'},
            price: 34.99,
            stockQuantity: 40,
          ),
          ProductVariant(
            id: '3',
            name: 'Size: Large',
            options: {'size': 'large'},
            price: 39.99,
            stockQuantity: 30,
          ),
        ],
        shippingInfo: ShippingInfo(
          weight: 0.5,
          dimensions: '10x10x10',
          requiresShipping: true,
        ),
      ),
      Product(
        id: '2',
        name: 'Sample Digital Product',
        description: 'This is a sample digital product',
        type: ProductType.digital,
        media: [
          ProductMedia(
            id: '2',
            url: 'https://example.com/images/digital1.jpg',
            type: MediaType.image,
            altText: 'Digital product image',
          ),
        ],
        price: 19.99,
        currency: 'USD',
        stockQuantity: -1, // Unlimited for digital products
        status: ProductStatus.published,
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
        updatedAt: DateTime.now().subtract(const Duration(days: 10)),
      ),
    ];
  }

  Future<Product?> getProduct(String productId) async {
    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 300));

    // Return mock data
    final products = await getProducts();
    return products.firstWhere((product) => product.id == productId, orElse: () => null);
  }

  Future<Product> createProduct(Product product) async {
    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 500));

    // Return created product with new timestamp
    return product.copyWith(createdAt: DateTime.now(), updatedAt: DateTime.now());
  }

  Future<Product> updateProduct(Product product) async {
    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 500));

    // Return updated product with new timestamp
    return product.copyWith(updatedAt: DateTime.now());
  }

  Future<bool> deleteProduct(String productId) async {
    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 500));

    return true; // Return success
  }

  void validateProductData(Product product) {
    if (product.name.trim().isEmpty) {
      throw const FormatException('Product name cannot be empty');
    }

    if (product.name.length > 100) {
      throw const FormatException('Product name must be less than 100 characters');
    }

    if (product.description.trim().isEmpty) {
      throw const FormatException('Product description cannot be empty');
    }

    if (product.description.length > 1000) {
      throw const FormatException('Product description must be less than 1000 characters');
    }

    if (product.price < 0) {
      throw const FormatException('Product price cannot be negative');
    }

    if (product.currency.isEmpty) {
      throw const FormatException('Product currency cannot be empty');
    }

    if (product.type == ProductType.physical && product.shippingInfo == null) {
      throw const FormatException('Physical products must have shipping information');
    }
  }
}