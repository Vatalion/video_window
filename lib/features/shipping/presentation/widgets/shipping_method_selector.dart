import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/models/shipping_method_model.dart';
import '../../domain/models/shipping_rate_model.dart';
import '../../domain/models/address_model.dart';

/// Widget for selecting shipping methods
class ShippingMethodSelector extends StatefulWidget {
  final AddressModel origin;
  final AddressModel destination;
  final double weightKg;
  final double lengthCm;
  final double widthCm;
  final double heightCm;
  final double? declaredValue;
  final Function(ShippingRateModel)? onShippingMethodSelected;
  final String? initialSelectedMethodId;

  const ShippingMethodSelector({
    super.key,
    required this.origin,
    required this.destination,
    required this.weightKg,
    required this.lengthCm,
    required this.widthCm,
    required this.heightCm,
    this.declaredValue,
    this.onShippingMethodSelected,
    this.initialSelectedMethodId,
  });

  @override
  State<ShippingMethodSelector> createState() => _ShippingMethodSelectorState();
}

class _ShippingMethodSelectorState extends State<ShippingMethodSelector> {
  List<ShippingRateModel> _shippingRates = [];
  ShippingRateModel? _selectedRate;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadShippingRates();
  }

  Future<void> _loadShippingRates() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Simulate API call - in real implementation, this would call the repository
      await Future.delayed(const Duration(seconds: 2));

      final mockRates = _generateMockShippingRates();
      setState(() {
        _shippingRates = mockRates;
        _isLoading = false;

        // Set initial selection
        if (widget.initialSelectedMethodId != null) {
          _selectedRate = mockRates.firstWhere(
            (rate) => rate.shippingMethod.id == widget.initialSelectedMethodId,
            orElse: () => mockRates.first,
          );
        } else if (mockRates.isNotEmpty) {
          _selectedRate = mockRates.first;
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load shipping rates: ${e.toString()}';
      });
    }
  }

  List<ShippingRateModel> _generateMockShippingRates() {
    final mockMethods = [
      ShippingMethodModel(
        id: 'fedex-standard',
        name: 'FedEx Standard',
        description: 'Reliable ground shipping with tracking',
        carrier: 'FedEx',
        serviceType: 'Ground',
        baseCost: 8.99,
        costPerKg: 2.50,
        costPerKm: 0.10,
        estimatedDeliveryDaysMin: 3,
        estimatedDeliveryDaysMax: 5,
        isInternational: widget.origin.country != widget.destination.country,
        requiresSignature: false,
        includesInsurance: false,
        maxWeightKg: 30.0,
        maxLengthCm: 150.0,
        maxWidthCm: 150.0,
        maxHeightCm: 150.0,
        supportedCountries: ['US', 'CA', 'MX'],
        restrictions: {},
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now(),
      ),
      ShippingMethodModel(
        id: 'fedex-express',
        name: 'FedEx Express',
        description: 'Fast overnight shipping with guaranteed delivery',
        carrier: 'FedEx',
        serviceType: 'Express',
        baseCost: 24.99,
        costPerKg: 5.00,
        costPerKm: 0.25,
        estimatedDeliveryDaysMin: 1,
        estimatedDeliveryDaysMax: 2,
        isInternational: widget.origin.country != widget.destination.country,
        requiresSignature: true,
        includesInsurance: true,
        maxWeightKg: 30.0,
        maxLengthCm: 150.0,
        maxWidthCm: 150.0,
        maxHeightCm: 150.0,
        supportedCountries: ['US', 'CA', 'MX'],
        restrictions: {},
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now(),
      ),
      ShippingMethodModel(
        id: 'ups-ground',
        name: 'UPS Ground',
        description: 'Economical ground shipping with tracking',
        carrier: 'UPS',
        serviceType: 'Ground',
        baseCost: 7.99,
        costPerKg: 2.25,
        costPerKm: 0.08,
        estimatedDeliveryDaysMin: 4,
        estimatedDeliveryDaysMax: 7,
        isInternational: widget.origin.country != widget.destination.country,
        requiresSignature: false,
        includesInsurance: false,
        maxWeightKg: 30.0,
        maxLengthCm: 150.0,
        maxWidthCm: 150.0,
        maxHeightCm: 150.0,
        supportedCountries: ['US', 'CA', 'MX'],
        restrictions: {},
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now(),
      ),
      ShippingMethodModel(
        id: 'usps-priority',
        name: 'USPS Priority Mail',
        description: 'Affordable priority shipping with tracking',
        carrier: 'USPS',
        serviceType: 'Priority',
        baseCost: 6.99,
        costPerKg: 1.75,
        costPerKm: 0.05,
        estimatedDeliveryDaysMin: 2,
        estimatedDeliveryDaysMax: 3,
        isInternational: widget.origin.country != widget.destination.country,
        requiresSignature: false,
        includesInsurance: false,
        maxWeightKg: 30.0,
        maxLengthCm: 150.0,
        maxWidthCm: 150.0,
        maxHeightCm: 150.0,
        supportedCountries: ['US'],
        restrictions: {},
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now(),
      ),
    ];

    return mockMethods.map((method) {
      final distanceKm = _calculateDistance(widget.origin, widget.destination);
      final cost = method.calculateCost(
        weightKg: widget.weightKg,
        distanceKm: distanceKm,
        declaredValue: widget.declaredValue,
        destinationCountry: widget.destination.country,
      );

      final deliveryDates = method.getEstimatedDeliveryDates(DateTime.now());

      return ShippingRateModel(
        id: 'rate-${method.id}',
        shippingMethod: method,
        origin: widget.origin,
        destination: widget.destination,
        weightKg: widget.weightKg,
        lengthCm: widget.lengthCm,
        widthCm: widget.widthCm,
        heightCm: widget.heightCm,
        distanceKm: distanceKm,
        baseCost: cost * 0.8, // Base cost
        taxAmount: cost * 0.1, // Tax
        dutyAmount: cost * 0.1, // Duty
        totalCost: cost,
        currency: 'USD',
        estimatedDeliveryDate: deliveryDates.maxDate,
        isAvailable: method.isValidPackage(
          weightKg: widget.weightKg,
          lengthCm: widget.lengthCm,
          widthCm: widget.widthCm,
          heightCm: widget.heightCm,
          destinationCountry: widget.destination.country,
        ),
        warnings: method.isInternational && !method.supportedCountries.contains(widget.destination.country)
            ? ['International shipping may have additional restrictions']
            : [],
        restrictions: [],
        calculatedAt: DateTime.now(),
      );
    }).toList();
  }

  double _calculateDistance(AddressModel origin, AddressModel destination) {
    // Simple distance calculation (in real implementation, use geocoding)
    if (origin.state == destination.state) {
      return 50.0; // Same state
    } else if (origin.country == destination.country) {
      return 500.0; // Same country, different state
    } else {
      return 2000.0; // International
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(),
        const SizedBox(height: 16),
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_errorMessage != null)
          _buildErrorState()
        else
          _buildShippingMethodList(),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Shipping Method',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          'From: ${widget.origin.city}, ${widget.origin.state}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Text(
          'To: ${widget.destination.city}, ${widget.destination.state}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Text(
          'Package: ${widget.weightKg}kg, ${widget.lengthCm}x${widget.widthCm}x${widget.heightCm}cm',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red),
      ),
      child: Column(
        children: [
          const Icon(Icons.error, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadShippingRates,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildShippingMethodList() {
    return Column(
      children: _shippingRates.map((rate) => _buildShippingMethodCard(rate)).toList(),
    );
  }

  Widget _buildShippingMethodCard(ShippingRateModel rate) {
    final isSelected = _selectedRate?.id == rate.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? Colors.blue : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: rate.isAvailable ? () => _selectShippingRate(rate) : null,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rate.shippingMethod.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          rate.shippingMethod.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (rate.isAvailable)
                    Radio<ShippingRateModel>(
                      value: rate,
                      groupValue: _selectedRate,
                      onChanged: (value) => _selectShippingRate(rate!),
                    )
                  else
                    const Text(
                      'Unavailable',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.local_shipping,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    rate.shippingMethod.carrier,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    rate.shippingMethod.deliveryEstimate,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(width: 16),
                  if (rate.shippingMethod.requiresSignature) ...[
                    Icon(
                      Icons.fingerprint,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Signature Required',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
              if (rate.warnings.isNotEmpty) ...[
                const SizedBox(height: 8),
                ...rate.warnings.map((warning) => Row(
                  children: [
                    Icon(
                      Icons.warning,
                      size: 16,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        warning,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                  ],
                )),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Cost',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        rate.formattedTotalCost,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  if (rate.shippingMethod.includesInsurance)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Insured',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
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

  void _selectShippingRate(ShippingRateModel rate) {
    setState(() {
      _selectedRate = rate;
    });
    widget.onShippingMethodSelected?.call(rate);
  }
}