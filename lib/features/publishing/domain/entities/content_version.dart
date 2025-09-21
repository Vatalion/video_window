import 'package:equatable/equatable.dart';

class ContentVersion extends Equatable {
  final String id;
  final String contentId;
  final int versionNumber;
  final String title;
  final String description;
  final DateTime createdAt;
  final String createdBy;
  final String? changesSummary;

  const ContentVersion({
    required this.id,
    required this.contentId,
    required this.versionNumber,
    required this.title,
    required this.description,
    required this.createdAt,
    required this.createdBy,
    this.changesSummary,
  });

  ContentVersion copyWith({
    String? id,
    String? contentId,
    int? versionNumber,
    String? title,
    String? description,
    DateTime? createdAt,
    String? createdBy,
    String? changesSummary,
  }) {
    return ContentVersion(
      id: id ?? this.id,
      contentId: contentId ?? this.contentId,
      versionNumber: versionNumber ?? this.versionNumber,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      changesSummary: changesSummary ?? this.changesSummary,
    );
  }

  @override
  List<Object?> get props => [
        id,
        contentId,
        versionNumber,
        title,
        description,
        createdAt,
        createdBy,
        changesSummary,
      ];
}