import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/models/address_model.dart';
import '../../domain/models/address_validation_model.dart';

/// Abstract base class for all address states
abstract class AddressState extends Equatable {
  const AddressState();

  @override
  List<Object> get props => [];
}

/// Initial state
class AddressInitial extends AddressState {
  const AddressInitial();
}

/// Loading state
class AddressLoading extends AddressState {
  const AddressLoading();
}

/// State when addresses are loaded
class AddressesLoaded extends AddressState {
  final List<AddressModel> addresses;
  final AddressModel? defaultAddress;

  const AddressesLoaded({
    required this.addresses,
    this.defaultAddress,
  });

  @override
  List<Object> get props => [addresses];
}

/// State when a single address is loaded
class AddressLoaded extends AddressState {
  final AddressModel address;

  const AddressLoaded(this.address);

  @override
  List<Object> get props => [address];
}

/// State when address is selected
class AddressSelected extends AddressState {
  final AddressModel address;

  const AddressSelected(this.address);

  @override
  List<Object> get props => [address];
}

/// State when address is created
class AddressCreated extends AddressState {
  final AddressModel address;

  const AddressCreated(this.address);

  @override
  List<Object> get props => [address];
}

/// State when address is updated
class AddressUpdated extends AddressState {
  final AddressModel address;

  const AddressUpdated(this.address);

  @override
  List<Object> get props => [address];
}

/// State when address is deleted
class AddressDeleted extends AddressState {
  final String addressId;

  const AddressDeleted(this.addressId);

  @override
  List<Object> get props => [addressId];
}

/// State when address is validated
class AddressValidated extends AddressState {
  final AddressValidationModel validationResult;

  const AddressValidated(this.validationResult);

  @override
  List<Object> get props => [validationResult];
}

/// State when address suggestions are loaded
class AddressSuggestionsLoaded extends AddressState {
  final List<String> suggestions;

  const AddressSuggestionsLoaded(this.suggestions);

  @override
  List<Object> get props => [suggestions];
}

/// State when address is set as default
class AddressSetDefault extends AddressState {
  final String addressId;

  const AddressSetDefault(this.addressId);

  @override
  List<Object> get props => [addressId];
}

/// Error state
class AddressError extends AddressState {
  final Failure failure;
  final String message;

  const AddressError({
    required this.failure,
    required this.message,
  });

  @override
  List<Object> get props => [failure, message];
}