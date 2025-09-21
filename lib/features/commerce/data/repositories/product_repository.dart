import '../services/product_service.dart';
import '../../domain/models/product.dart';

class ProductRepository {
  final ProductService _service = ProductService();

  Future<List<Product>> getProducts() async {
    return await _service.getProducts();
  }

  Future<Product?> getProduct(String productId) async {
    return await _service.getProduct(productId);
  }

  Future<Product> createProduct(Product product) async {
    _service.validateProductData(product);
    return await _service.createProduct(product);
  }

  Future<Product> updateProduct(Product product) async {
    _service.validateProductData(product);
    return await _service.updateProduct(product);
  }

  Future<bool> deleteProduct(String productId) async {
    return await _service.deleteProduct(productId);
  }
}