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

abstract class MediaFile implements _i1.SerializableModel {
  MediaFile._({
    this.id,
    required this.userId,
    required this.type,
    required this.originalFileName,
    required this.s3Key,
    this.cdnUrl,
    required this.mimeType,
    required this.fileSizeBytes,
    this.metadata,
    required this.status,
    required this.isVirusScanned,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MediaFile({
    int? id,
    required int userId,
    required String type,
    required String originalFileName,
    required String s3Key,
    String? cdnUrl,
    required String mimeType,
    required int fileSizeBytes,
    String? metadata,
    required String status,
    required bool isVirusScanned,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _MediaFileImpl;

  factory MediaFile.fromJson(Map<String, dynamic> jsonSerialization) {
    return MediaFile(
      id: jsonSerialization['id'] as int?,
      userId: jsonSerialization['userId'] as int,
      type: jsonSerialization['type'] as String,
      originalFileName: jsonSerialization['originalFileName'] as String,
      s3Key: jsonSerialization['s3Key'] as String,
      cdnUrl: jsonSerialization['cdnUrl'] as String?,
      mimeType: jsonSerialization['mimeType'] as String,
      fileSizeBytes: jsonSerialization['fileSizeBytes'] as int,
      metadata: jsonSerialization['metadata'] as String?,
      status: jsonSerialization['status'] as String,
      isVirusScanned: jsonSerialization['isVirusScanned'] as bool,
      createdAt:
          _i1.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
      updatedAt:
          _i1.DateTimeJsonExtension.fromJson(jsonSerialization['updatedAt']),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int userId;

  String type;

  String originalFileName;

  String s3Key;

  String? cdnUrl;

  String mimeType;

  int fileSizeBytes;

  String? metadata;

  String status;

  bool isVirusScanned;

  DateTime createdAt;

  DateTime updatedAt;

  /// Returns a shallow copy of this [MediaFile]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  MediaFile copyWith({
    int? id,
    int? userId,
    String? type,
    String? originalFileName,
    String? s3Key,
    String? cdnUrl,
    String? mimeType,
    int? fileSizeBytes,
    String? metadata,
    String? status,
    bool? isVirusScanned,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'userId': userId,
      'type': type,
      'originalFileName': originalFileName,
      's3Key': s3Key,
      if (cdnUrl != null) 'cdnUrl': cdnUrl,
      'mimeType': mimeType,
      'fileSizeBytes': fileSizeBytes,
      if (metadata != null) 'metadata': metadata,
      'status': status,
      'isVirusScanned': isVirusScanned,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _MediaFileImpl extends MediaFile {
  _MediaFileImpl({
    int? id,
    required int userId,
    required String type,
    required String originalFileName,
    required String s3Key,
    String? cdnUrl,
    required String mimeType,
    required int fileSizeBytes,
    String? metadata,
    required String status,
    required bool isVirusScanned,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
          id: id,
          userId: userId,
          type: type,
          originalFileName: originalFileName,
          s3Key: s3Key,
          cdnUrl: cdnUrl,
          mimeType: mimeType,
          fileSizeBytes: fileSizeBytes,
          metadata: metadata,
          status: status,
          isVirusScanned: isVirusScanned,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );

  /// Returns a shallow copy of this [MediaFile]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  MediaFile copyWith({
    Object? id = _Undefined,
    int? userId,
    String? type,
    String? originalFileName,
    String? s3Key,
    Object? cdnUrl = _Undefined,
    String? mimeType,
    int? fileSizeBytes,
    Object? metadata = _Undefined,
    String? status,
    bool? isVirusScanned,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MediaFile(
      id: id is int? ? id : this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      originalFileName: originalFileName ?? this.originalFileName,
      s3Key: s3Key ?? this.s3Key,
      cdnUrl: cdnUrl is String? ? cdnUrl : this.cdnUrl,
      mimeType: mimeType ?? this.mimeType,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      metadata: metadata is String? ? metadata : this.metadata,
      status: status ?? this.status,
      isVirusScanned: isVirusScanned ?? this.isVirusScanned,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
