import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/models/address_model.dart';
import '../../domain/models/address_validation_model.dart';
import '../../domain/usecases/create_address.dart';
import '../../domain/usecases/delete_address.dart';
import '../../domain/usecases/get_addresses.dart';
import '../../domain/usecases/update_address.dart';
import '../../domain/usecases/validate_address.dart';
import '../../domain/repositories/address_repository.dart';
import 'address_event.dart';
import 'address_state.dart';

/// BLoC for managing address operations
class AddressBloc extends Bloc<AddressEvent, AddressState> {
  final GetAddresses getAddresses;
  final CreateAddress createAddress;
  final UpdateAddress updateAddress;
  final DeleteAddress deleteAddress;
  final ValidateAddress validateAddress;
  final AddressRepository addressRepository;

  AddressBloc({
    required this.getAddresses,
    required this.createAddress,
    required this.updateAddress,
    required this.deleteAddress,
    required this.validateAddress,
    required this.addressRepository,
  }) : super(const AddressInitial()) {
    on<FetchAddresses>(_onFetchAddresses);
    on<CreateAddress>(_onCreateAddress);
    on<UpdateAddress>(_onUpdateAddress);
    on<DeleteAddress>(_onDeleteAddress);
    on<SetDefaultAddress>(_onSetDefaultAddress);
    on<ValidateAddress>(_onValidateAddress);
    on<SelectAddress>(_onSelectAddress);
    on<ClearSelectedAddress>(_onClearSelectedAddress);
    on<ResetAddressState>(_onResetAddressState);
  }

  Future<void> _onFetchAddresses(
    FetchAddresses event,
    Emitter<AddressState> emit,
  ) async {
    emit(const AddressLoading());

    final result = await getAddresses(event.userId);

    result.fold(
      (failure) => emit(AddressError(
        failure: failure,
        message: _mapFailureToMessage(failure),
      )),
      (addresses) {
        final defaultAddress = addresses.where((a) => a.isDefault).firstOrNull;
        emit(AddressesLoaded(
          addresses: addresses,
          defaultAddress: defaultAddress,
        ));
      },
    );
  }

  Future<void> _onCreateAddress(
    CreateAddress event,
    Emitter<AddressState> emit,
  ) async {
    emit(const AddressLoading());

    final result = await createAddress(event.address);

    result.fold(
      (failure) => emit(AddressError(
        failure: failure,
        message: _mapFailureToMessage(failure),
      )),
      (address) => emit(AddressCreated(address)),
    );
  }

  Future<void> _onUpdateAddress(
    UpdateAddress event,
    Emitter<AddressState> emit,
  ) async {
    emit(const AddressLoading());

    final result = await updateAddress(event.address);

    result.fold(
      (failure) => emit(AddressError(
        failure: failure,
        message: _mapFailureToMessage(failure),
      )),
      (address) => emit(AddressUpdated(address)),
    );
  }

  Future<void> _onDeleteAddress(
    DeleteAddress event,
    Emitter<AddressState> emit,
  ) async {
    emit(const AddressLoading());

    final result = await deleteAddress(event.addressId);

    result.fold(
      (failure) => emit(AddressError(
        failure: failure,
        message: _mapFailureToMessage(failure),
      )),
      (_) => emit(AddressDeleted(event.addressId)),
    );
  }

  Future<void> _onSetDefaultAddress(
    SetDefaultAddress event,
    Emitter<AddressState> emit,
  ) async {
    emit(const AddressLoading());

    final result = await addressRepository.setDefaultAddress(event.addressId);

    result.fold(
      (failure) => emit(AddressError(
        failure: failure,
        message: _mapFailureToMessage(failure),
      )),
      (_) => emit(AddressSetDefault(event.addressId)),
    );
  }

  Future<void> _onValidateAddress(
    ValidateAddress event,
    Emitter<AddressState> emit,
  ) async {
    emit(const AddressLoading());

    final result = await validateAddress(event.address);

    result.fold(
      (failure) => emit(AddressError(
        failure: failure,
        message: _mapFailureToMessage(failure),
      )),
      (validationResult) => emit(AddressValidated(validationResult)),
    );
  }

  Future<void> _onSelectAddress(
    SelectAddress event,
    Emitter<AddressState> emit,
  ) async {
    emit(AddressSelected(event.address));
  }

  Future<void> _onClearSelectedAddress(
    ClearSelectedAddress event,
    Emitter<AddressState> emit,
  ) async {
    emit(const AddressInitial());
  }

  Future<void> _onResetAddressState(
    ResetAddressState event,
    Emitter<AddressState> emit,
  ) async {
    emit(const AddressInitial());
  }

  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case ServerFailure:
        return 'Server error: ${failure.message}';
      case NetworkFailure:
        return 'Network error: ${failure.message}';
      case CacheFailure:
        return 'Cache error: ${failure.message}';
      case ValidationFailure:
        return 'Validation error: ${failure.message}';
      case AuthenticationFailure:
        return 'Authentication error: ${failure.message}';
      case AuthorizationFailure:
        return 'Authorization error: ${failure.message}';
      case AddressValidationFailure:
        return 'Address validation error: ${failure.message}';
      default:
        return 'Unexpected error: ${failure.message}';
    }
  }
}