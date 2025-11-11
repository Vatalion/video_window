/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod_client/serverpod_client.dart' as _i1;
import '../capabilities/capability_type.dart' as _i2;

abstract class CapabilityRequestDto implements _i1.SerializableModel {
  CapabilityRequestDto._({
    required this.capability,
    required this.context,
  });

  factory CapabilityRequestDto({
    required _i2.CapabilityType capability,
    required Map<String, String> context,
  }) = _CapabilityRequestDtoImpl;

  factory CapabilityRequestDto.fromJson(
      Map<String, dynamic> jsonSerialization) {
    return CapabilityRequestDto(
      capability:
          _i2.CapabilityType.fromJson((jsonSerialization['capability'] as int)),
      context: (jsonSerialization['context'] as Map).map((k, v) => MapEntry(
            k as String,
            v as String,
          )),
    );
  }

  _i2.CapabilityType capability;

  Map<String, String> context;

  /// Returns a shallow copy of this [CapabilityRequestDto]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  CapabilityRequestDto copyWith({
    _i2.CapabilityType? capability,
    Map<String, String>? context,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      'capability': capability.toJson(),
      'context': context.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _CapabilityRequestDtoImpl extends CapabilityRequestDto {
  _CapabilityRequestDtoImpl({
    required _i2.CapabilityType capability,
    required Map<String, String> context,
  }) : super._(
          capability: capability,
          context: context,
        );

  /// Returns a shallow copy of this [CapabilityRequestDto]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  CapabilityRequestDto copyWith({
    _i2.CapabilityType? capability,
    Map<String, String>? context,
  }) {
    return CapabilityRequestDto(
      capability: capability ?? this.capability,
      context: context ??
          this.context.map((
                key0,
                value0,
              ) =>
                  MapEntry(
                    key0,
                    value0,
                  )),
    );
  }
}
