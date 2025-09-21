import 'package:flutter/material.dart';
import '../../domain/models/product.dart';

class ProductCreationScreen extends StatefulWidget {
  const ProductCreationScreen({super.key});

  @override
  State<ProductCreationScreen> createState() => _ProductCreationScreenState();
}

class _ProductCreationScreenState extends State<ProductCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers for form fields
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _currencyController = TextEditingController();
  final _stockController = TextEditingController();
  final _weightController = TextEditingController();
  final _dimensionsController = TextEditingController();
  
  // Form state
  ProductType _selectedProductType = ProductType.physical;
  ProductStatus _productStatus = ProductStatus.draft;
  bool _requiresShipping = true;
  
  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _currencyController.dispose();
    _stockController.dispose();
    _weightController.dispose();
    _dimensionsController.dispose();
    super.dispose();
  }

  void _saveProduct() {
    if (_formKey.currentState!.validate()) {
      // Create a new product with the form data
      final product = Product(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        description: _descriptionController.text,
        type: _selectedProductType,
        media: [], // Empty for now, would be populated with actual media
        price: double.tryParse(_priceController.text) ?? 0.0,
        currency: _currencyController.text,
        stockQuantity: int.tryParse(_stockController.text) ?? 0,
        status: _productStatus,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        variants: [], // Empty for now
        shippingInfo: _selectedProductType == ProductType.physical
            ? ShippingInfo(
                weight: double.tryParse(_weightController.text) ?? 0.0,
                dimensions: _dimensionsController.text,
                requiresShipping: _requiresShipping,
              )
            : null,
      );
      
      // In a real implementation, this would save to a repository
      // For now, we'll just show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product saved successfully!')),
      );
      
      // If status is published, we might want to navigate back
      if (_productStatus == ProductStatus.published) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Product'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveProduct,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Product Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a product name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Product Type Selector
              const Text('Product Type', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SegmentedButton<ProductType>(
                segments: const [
                  ButtonSegment(value: ProductType.physical, label: Text('Physical')),
                  ButtonSegment(value: ProductType.digital, label: Text('Digital')),
                  ButtonSegment(value: ProductType.service, label: Text('Service')),
                ],
                selected: {_selectedProductType},
                onSelectionChanged: (Set<ProductType> newSelection) {
                  setState(() {
                    _selectedProductType = newSelection.first;
                  });
                },
              ),
              const SizedBox(height: 16),
              
              // Product Description (Rich Text Editor would go here)
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a product description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Media Upload Section (would be more complex in real implementation)
              const Text('Media', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                height: 100,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text('Media Upload Area\n(Drag and drop or click to upload)'),
                ),
              ),
              const SizedBox(height: 16),
              
              // Pricing Section
              const Text('Pricing', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: 'Price',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a price';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid price';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _currencyController,
                      decoration: const InputDecoration(
                        labelText: 'Currency',
                        border: OutlineInputBorder(),
                      ),
                      initialValue: 'USD',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a currency';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Inventory Section
              const Text('Inventory', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _stockController,
                decoration: const InputDecoration(
                  labelText: 'Stock Quantity',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter stock quantity';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Shipping Section (only for physical products)
              if (_selectedProductType == ProductType.physical) ...[
                const Text('Shipping', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _weightController,
                  decoration: const InputDecoration(
                    labelText: 'Weight (kg)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _dimensionsController,
                  decoration: const InputDecoration(
                    labelText: 'Dimensions (LxWxH cm)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Requires Shipping'),
                  value: _requiresShipping,
                  onChanged: (bool value) {
                    setState(() {
                      _requiresShipping = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
              ],
              
              // Product Variants Section (simplified for now)
              const Text('Variants', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                height: 100,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text('Variant Configuration\n(Click to add variants)'),
                ),
              ),
              const SizedBox(height: 16),
              
              // Status Selector
              const Text('Status', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SegmentedButton<ProductStatus>(
                segments: const [
                  ButtonSegment(value: ProductStatus.draft, label: Text('Draft')),
                  ButtonSegment(value: ProductStatus.published, label: Text('Publish')),
                ],
                selected: {_productStatus},
                onSelectionChanged: (Set<ProductStatus> newSelection) {
                  setState(() {
                    _productStatus = newSelection.first;
                  });
                },
              ),
              const SizedBox(height: 32),
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveProduct,
                      child: const Text('Save Product'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}