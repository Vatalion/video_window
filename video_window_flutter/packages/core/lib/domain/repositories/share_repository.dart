import '../entities/share_response.dart';

abstract class ShareRepository {
  Future<String?> toggleStorySave(
      {required String storyId, required bool isSaved});
  Future<ShareResponse> generateStoryDeepLink(
      {required String storyId, required String channel});
}
