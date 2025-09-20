import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/models/address_model.dart';
import '../bloc/address_bloc.dart';
import '../bloc/address_event.dart';
import '../bloc/address_state.dart';

/// Widget for displaying a list of addresses
class AddressList extends StatelessWidget {
  final String userId;
  final Function(AddressModel)? onAddressSelected;
  final Function(AddressModel)? onAddressEdit;
  final Function(String)? onAddressDelete;

  const AddressList({
    super.key,
    required this.userId,
    this.onAddressSelected,
    this.onAddressEdit,
    this.onAddressDelete,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AddressBloc, AddressState>(
      builder: (context, state) {
        if (state is AddressInitial) {
          context.read<AddressBloc>().add(FetchAddresses(userId));
        }

        if (state is AddressLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is AddressError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Error: ${state.message}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.read<AddressBloc>().add(FetchAddresses(userId)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (state is AddressesLoaded) {
          if (state.addresses.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_off, size: 48, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No addresses found',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Add your first address to get started',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: state.addresses.length,
                  itemBuilder: (context, index) {
                    final address = state.addresses[index];
                    return AddressCard(
                      address: address,
                      isDefault: address.isDefault,
                      onSelected: onAddressSelected,
                      onEdit: onAddressEdit,
                      onDelete: onAddressDelete,
                    );
                  },
                ),
              ),
            ],
          );
        }

        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}

/// Widget for displaying a single address card
class AddressCard extends StatelessWidget {
  final AddressModel address;
  final bool isDefault;
  final Function(AddressModel)? onSelected;
  final Function(AddressModel)? onEdit;
  final Function(String)? onDelete;

  const AddressCard({
    super.key,
    required this.address,
    required this.isDefault,
    this.onSelected,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: InkWell(
        onTap: () => onSelected?.call(address),
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
                        Row(
                          children: [
                            Text(
                              '${address.firstName} ${address.lastName}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (isDefault) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Default',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (address.company.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            address.company,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          onEdit?.call(address);
                          break;
                        case 'delete':
                          _showDeleteConfirmation(context);
                          break;
                        case 'set_default':
                          if (!isDefault) {
                            context.read<AddressBloc>().add(SetDefaultAddress(address.id));
                          }
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      if (!isDefault)
                        const PopupMenuItem(
                          value: 'set_default',
                          child: Row(
                            children: [
                              Icon(Icons.star),
                              SizedBox(width: 8),
                              Text('Set as Default'),
                            ],
                          ),
                        ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                address.addressLine1,
                style: const TextStyle(fontSize: 14),
              ),
              if (address.addressLine2.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  address.addressLine2,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
              const SizedBox(height: 4),
              Text(
                '${address.city}, ${address.state} ${address.postalCode}',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                address.country,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.phone,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    address.phoneNumber,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.email,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    address.email,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    address.isResidential ? Icons.home : Icons.business,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    address.isResidential ? 'Residential' : 'Business',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(width: 16),
                  if (address.isValidated) ...[
                    Icon(
                      Icons.verified,
                      size: 16,
                      color: Colors.green.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Validated',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Address'),
        content: const Text('Are you sure you want to delete this address?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onDelete?.call(address.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}