import 'package:equatable/equatable.dart';

class ShareResponse extends Equatable {
  final String shareId;
  final String deepLink;
  final DateTime expiresAt;
  final SocialPreview socialPreview;

  const ShareResponse({
    required this.shareId,
    required this.deepLink,
    required this.expiresAt,
    required this.socialPreview,
  });

  @override
  List<Object?> get props => [shareId, deepLink, expiresAt, socialPreview];
}

class SocialPreview extends Equatable {
  final String title;
  final String description;
  final String image;

  const SocialPreview({
    required this.title,
    required this.description,
    required this.image,
  });

  @override
  List<Object?> get props => [title, description, image];
}
