import 'package:equatable/equatable.dart';
import '../../domain/models/address_model.dart';
import '../../domain/models/address_validation_model.dart';

/// Abstract base class for all address events
abstract class AddressEvent extends Equatable {
  const AddressEvent();

  @override
  List<Object> get props => [];
}

/// Event to fetch all addresses
class FetchAddresses extends AddressEvent {
  final String userId;

  const FetchAddresses(this.userId);

  @override
  List<Object> get props => [userId];
}

/// Event to create a new address
class CreateAddress extends AddressEvent {
  final AddressModel address;

  const CreateAddress(this.address);

  @override
  List<Object> get props => [address];
}

/// Event to update an existing address
class UpdateAddress extends AddressEvent {
  final AddressModel address;

  const UpdateAddress(this.address);

  @override
  List<Object> get props => [address];
}

/// Event to delete an address
class DeleteAddress extends AddressEvent {
  final String addressId;

  const DeleteAddress(this.addressId);

  @override
  List<Object> get props => [addressId];
}

/// Event to set address as default
class SetDefaultAddress extends AddressEvent {
  final String addressId;

  const SetDefaultAddress(this.addressId);

  @override
  List<Object> get props => [addressId];
}

/// Event to validate an address
class ValidateAddress extends AddressEvent {
  final AddressModel address;

  const ValidateAddress(this.address);

  @override
  List<Object> get props => [address];
}

/// Event to get address suggestions
class GetAddressSuggestions extends AddressEvent {
  final String partialAddress;

  const GetAddressSuggestions(this.partialAddress);

  @override
  List<Object> get props => [partialAddress];
}

/// Event to select an address
class SelectAddress extends AddressEvent {
  final AddressModel address;

  const SelectAddress(this.address);

  @override
  List<Object> get props => [address];
}

/// Event to clear selected address
class ClearSelectedAddress extends AddressEvent {
  const ClearSelectedAddress();
}

/// Event to reset address state
class ResetAddressState extends AddressEvent {
  const ResetAddressState();
}