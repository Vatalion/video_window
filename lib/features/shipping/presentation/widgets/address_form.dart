import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/models/address_model.dart';
import '../../domain/models/address_validation_model.dart';
import '../bloc/address_bloc.dart';
import '../bloc/address_event.dart';
import '../bloc/address_state.dart';

/// Form widget for creating/editing addresses
class AddressForm extends StatefulWidget {
  final AddressModel? address;
  final String userId;
  final Function(AddressModel)? onAddressSaved;

  const AddressForm({
    super.key,
    this.address,
    required this.userId,
    this.onAddressSaved,
  });

  @override
  State<AddressForm> createState() => _AddressFormState();
}

class _AddressFormState extends State<AddressForm> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _companyController = TextEditingController();
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _countryController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  bool _isDefault = false;
  bool _isResidential = true;
  bool _isLoading = false;
  bool _isValidated = false;
  AddressValidationModel? _validationResult;

  @override
  void initState() {
    super.initState();
    if (widget.address != null) {
      _loadAddressData(widget.address!);
    }
  }

  void _loadAddressData(AddressModel address) {
    _firstNameController.text = address.firstName;
    _lastNameController.text = address.lastName;
    _companyController.text = address.company;
    _addressLine1Controller.text = address.addressLine1;
    _addressLine2Controller.text = address.addressLine2;
    _cityController.text = address.city;
    _stateController.text = address.state;
    _postalCodeController.text = address.postalCode;
    _countryController.text = address.country;
    _phoneController.text = address.phoneNumber;
    _emailController.text = address.email;
    _isDefault = address.isDefault;
    _isResidential = address.isResidential;
    _isValidated = address.isValidated;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _companyController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    _countryController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final address = AddressModel(
        id: widget.address?.id ?? '',
        userId: widget.userId,
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        company: _companyController.text,
        addressLine1: _addressLine1Controller.text,
        addressLine2: _addressLine2Controller.text,
        city: _cityController.text,
        state: _stateController.text,
        postalCode: _postalCodeController.text,
        country: _countryController.text,
        isDefault: _isDefault,
        isResidential: _isResidential,
        phoneNumber: _phoneController.text,
        email: _emailController.text,
        createdAt: widget.address?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        isValidated: _isValidated,
        validationStatus: _validationResult?.status,
        validationDetails: _validationResult?.validationDetails,
      );

      if (widget.address == null) {
        context.read<AddressBloc>().add(CreateAddress(address));
      } else {
        context.read<AddressBloc>().add(UpdateAddress(address));
      }
    }
  }

  void _validateAddress() {
    if (_formKey.currentState!.validate()) {
      final address = AddressModel(
        id: widget.address?.id ?? '',
        userId: widget.userId,
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        company: _companyController.text,
        addressLine1: _addressLine1Controller.text,
        addressLine2: _addressLine2Controller.text,
        city: _cityController.text,
        state: _stateController.text,
        postalCode: _postalCodeController.text,
        country: _countryController.text,
        isDefault: _isDefault,
        isResidential: _isResidential,
        phoneNumber: _phoneController.text,
        email: _emailController.text,
        createdAt: widget.address?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        isValidated: _isValidated,
        validationStatus: _validationResult?.status,
        validationDetails: _validationResult?.validationDetails,
      );

      context.read<AddressBloc>().add(ValidateAddress(address));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AddressBloc, AddressState>(
      listener: (context, state) {
        if (state is AddressCreated || state is AddressUpdated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Address saved successfully')),
          );
          widget.onAddressSaved?.call(widget.address ?? (state is AddressCreated ? state.address : widget.address!));
          Navigator.of(context).pop();
        } else if (state is AddressError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        } else if (state is AddressValidated) {
          setState(() {
            _validationResult = state.validationResult;
            _isValidated = state.validationResult.isValid;
          });
        }
      },
      builder: (context, state) {
        return Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildValidationStatus(),
                const SizedBox(height: 16),
                _buildNameFields(),
                const SizedBox(height: 16),
                _buildCompanyField(),
                const SizedBox(height: 16),
                _buildAddressFields(),
                const SizedBox(height: 16),
                _buildLocationFields(),
                const SizedBox(height: 16),
                _buildContactFields(),
                const SizedBox(height: 16),
                _buildAddressTypeFields(),
                const SizedBox(height: 24),
                _buildActionButtons(state),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildValidationStatus() {
    if (_validationResult != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _validationResult!.isValid ? Colors.green.shade50 : Colors.red.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _validationResult!.isValid ? Colors.green : Colors.red,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _validationResult!.isValid ? Icons.check_circle : Icons.error,
                  color: _validationResult!.isValid ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  _validationResult!.isValid ? 'Address Valid' : 'Address Invalid',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _validationResult!.isValid ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            if (_validationResult!.message.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(_validationResult!.message),
            ],
            if (_validationResult!.suggestions.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('Suggestions:', style: TextStyle(fontWeight: FontWeight.bold)),
              ..._validationResult!.suggestions.map((suggestion) => Text('• $suggestion')),
            ],
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildNameFields() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _firstNameController,
            decoration: const InputDecoration(
              labelText: 'First Name',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter first name';
              }
              return null;
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextFormField(
            controller: _lastNameController,
            decoration: const InputDecoration(
              labelText: 'Last Name',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter last name';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCompanyField() {
    return TextFormField(
      controller: _companyController,
      decoration: const InputDecoration(
        labelText: 'Company (Optional)',
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildAddressFields() {
    return Column(
      children: [
        TextFormField(
          controller: _addressLine1Controller,
          decoration: const InputDecoration(
            labelText: 'Address Line 1',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter address';
            }
            return null;
          },
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _addressLine2Controller,
          decoration: const InputDecoration(
            labelText: 'Address Line 2 (Optional)',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationFields() {
    return Column(
      children: [
        TextFormField(
          controller: _cityController,
          decoration: const InputDecoration(
            labelText: 'City',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter city';
            }
            return null;
          },
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _stateController,
                decoration: const InputDecoration(
                  labelText: 'State/Province',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter state';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _postalCodeController,
                decoration: const InputDecoration(
                  labelText: 'Postal Code',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter postal code';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _countryController,
          decoration: const InputDecoration(
            labelText: 'Country',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter country';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildContactFields() {
    return Column(
      children: [
        TextFormField(
          controller: _phoneController,
          decoration: const InputDecoration(
            labelText: 'Phone Number',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter phone number';
            }
            return null;
          },
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: 'Email',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter email';
            }
            if (!value.contains('@')) {
              return 'Please enter a valid email';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildAddressTypeFields() {
    return Column(
      children: [
        CheckboxListTile(
          title: const Text('Set as default address'),
          value: _isDefault,
          onChanged: (value) {
            setState(() {
              _isDefault = value ?? false;
            });
          },
        ),
        CheckboxListTile(
          title: const Text('Residential address'),
          value: _isResidential,
          onChanged: (value) {
            setState(() {
              _isResidential = value ?? true;
            });
          },
        ),
      ],
    );
  }

  Widget _buildActionButtons(AddressState state) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _validateAddress,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Validate Address'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: Text(widget.address == null ? 'Save Address' : 'Update Address'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}