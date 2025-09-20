import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../models/content/content.dart';

class PublishingService extends ChangeNotifier {
  List<Content> _contents = [];
  List<PublishingTemplate> _templates = [];
  bool _isLoading = false;
  String? _error;
  WebSocketChannel? _workflowChannel;

  List<Content> get contents => _contents;
  List<PublishingTemplate> get templates => _templates;
  bool get isLoading => _isLoading;
  String? get error => _error;

  PublishingService() {
    _initWebSocket();
  }

  Future<void> fetchContents({ContentStatus? status, String? authorId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final queryParams = <String, String>{};
      if (status != null) {
        queryParams['status'] = status.name;
      }
      if (authorId != null) {
        queryParams['authorId'] = authorId;
      }

      final uri = Uri.parse('https://api.example.com/content')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _contents = (data['contents'] as List)
            .map((content) => Content.fromJson(content))
            .toList();
      } else {
        throw Exception('Failed to load contents: ${response.statusCode}');
      }
    } catch (e) {
      _error = 'Failed to fetch contents: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchTemplates() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.example.com/publishing/templates'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _templates = (data['templates'] as List)
            .map((template) => PublishingTemplate.fromJson(template))
            .toList();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to fetch templates: $e');
      }
    }
  }

  Future<Content?> createContent(Content content) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('https://api.example.com/content'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(content.toJson()),
      );

      if (response.statusCode == 201) {
        final createdContent = Content.fromJson(jsonDecode(response.body));
        _contents.add(createdContent);
        notifyListeners();
        return createdContent;
      } else {
        throw Exception('Failed to create content: ${response.statusCode}');
      }
    } catch (e) {
      _error = 'Failed to create content: ${e.toString()}';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Content?> updateContent(String contentId, Content content) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.put(
        Uri.parse('https://api.example.com/content/$contentId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(content.toJson()),
      );

      if (response.statusCode == 200) {
        final updatedContent = Content.fromJson(jsonDecode(response.body));
        final index = _contents.indexWhere((c) => c.id == contentId);
        if (index >= 0) {
          _contents[index] = updatedContent;
        }
        notifyListeners();
        return updatedContent;
      } else {
        throw Exception('Failed to update content: ${response.statusCode}');
      }
    } catch (e) {
      _error = 'Failed to update content: ${e.toString()}';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteContent(String contentId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.delete(
        Uri.parse('https://api.example.com/content/$contentId'),
      );

      if (response.statusCode == 200) {
        _contents.removeWhere((c) => c.id == contentId);
        notifyListeners();
        return true;
      } else {
        throw Exception('Failed to delete content: ${response.statusCode}');
      }
    } catch (e) {
      _error = 'Failed to delete content: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Content?> submitForReview(String contentId, List<String> reviewerIds) async {
    final content = _contents.firstWhere((c) => c.id == contentId);

    if (content.status != ContentStatus.draft) {
      throw Exception('Content must be in draft status to submit for review');
    }

    final approvalRequests = reviewerIds.map((reviewerId) => ApprovalRequest(
      id: 'req_${DateTime.now().millisecondsSinceEpoch}_${reviewerId}',
      contentId: contentId,
      requestedBy: content.authorId,
      requestedTo: reviewerId,
      status: ApprovalStatus.pending,
      createdAt: DateTime.now(),
    )).toList();

    final updatedContent = content.copyWith(
      status: ContentStatus.review,
      approvalRequests: [...content.approvalRequests, ...approvalRequests],
      updatedAt: DateTime.now(),
    );

    return await updateContent(contentId, updatedContent);
  }

  Future<Content?> approveContent(String contentId, String approvalRequestId, {String? message}) async {
    final content = _contents.firstWhere((c) => c.id == contentId);
    final approvalRequestIndex = content.approvalRequests.indexWhere((r) => r.id == approvalRequestId);

    if (approvalRequestIndex == -1) {
      throw Exception('Approval request not found');
    }

    final updatedApprovalRequests = List<ApprovalRequest>.from(content.approvalRequests);
    updatedApprovalRequests[approvalRequestIndex] = updatedApprovalRequests[approvalRequestIndex].copyWith(
      status: ApprovalStatus.approved,
      respondedAt: DateTime.now(),
      responseMessage: message,
    );

    bool allApproved = updatedApprovalRequests.every((r) => r.status == ApprovalStatus.approved);
    bool allResponded = updatedApprovalRequests.every((r) => r.status != ApprovalStatus.pending);

    ContentStatus newStatus = content.status;
    if (allApproved && allResponded) {
      newStatus = ContentStatus.draft;
    } else if (allResponded) {
      newStatus = ContentStatus.draft;
    }

    final updatedContent = content.copyWith(
      status: newStatus,
      approvalRequests: updatedApprovalRequests,
      updatedAt: DateTime.now(),
    );

    return await updateContent(contentId, updatedContent);
  }

  Future<Content?> rejectContent(String contentId, String approvalRequestId, {String? message}) async {
    final content = _contents.firstWhere((c) => c.id == contentId);
    final approvalRequestIndex = content.approvalRequests.indexWhere((r) => r.id == approvalRequestId);

    if (approvalRequestIndex == -1) {
      throw Exception('Approval request not found');
    }

    final updatedApprovalRequests = List<ApprovalRequest>.from(content.approvalRequests);
    updatedApprovalRequests[approvalRequestIndex] = updatedApprovalRequests[approvalRequestIndex].copyWith(
      status: ApprovalStatus.rejected,
      respondedAt: DateTime.now(),
      responseMessage: message,
    );

    final updatedContent = content.copyWith(
      status: ContentStatus.draft,
      approvalRequests: updatedApprovalRequests,
      updatedAt: DateTime.now(),
    );

    return await updateContent(contentId, updatedContent);
  }

  Future<Content?> scheduleContent(String contentId, DateTime publishAt) async {
    final content = _contents.firstWhere((c) => c.id == contentId);

    if (content.status != ContentStatus.draft) {
      throw Exception('Content must be in draft status to schedule');
    }

    final updatedPublishSettings = content.publishSettings.copyWith(publishAt: publishAt);
    final updatedContent = content.copyWith(
      status: ContentStatus.scheduled,
      publishSettings: updatedPublishSettings,
      scheduledAt: publishAt,
      updatedAt: DateTime.now(),
    );

    return await updateContent(contentId, updatedContent);
  }

  Future<Content?> publishContent(String contentId) async {
    final content = _contents.firstWhere((c) => c.id == contentId);

    if (!content.isDraft && !content.isScheduled) {
      throw Exception('Content must be in draft or scheduled status to publish');
    }

    final updatedContent = content.copyWith(
      status: ContentStatus.published,
      publishedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return await updateContent(contentId, updatedContent);
  }

  Future<Content?> archiveContent(String contentId) async {
    final content = _contents.firstWhere((c) => c.id == contentId);

    if (!content.isPublished) {
      throw Exception('Only published content can be archived');
    }

    final updatedContent = content.copyWith(
      status: ContentStatus.archived,
      updatedAt: DateTime.now(),
    );

    return await updateContent(contentId, updatedContent);
  }

  Future<Content?> restoreContent(String contentId) async {
    final content = _contents.firstWhere((c) => c.id == contentId);

    if (!content.isArchived) {
      throw Exception('Only archived content can be restored');
    }

    final updatedContent = content.copyWith(
      status: ContentStatus.published,
      updatedAt: DateTime.now(),
    );

    return await updateContent(contentId, updatedContent);
  }

  Future<Content?> createVersion(String contentId, String title, String description, String body, {String? changeLog}) async {
    final content = _contents.firstWhere((c) => c.id == contentId);

    final nextVersionNumber = content.versions.fold(0, (max, version) => version.versionNumber > max ? version.versionNumber : max) + 1;

    final newVersion = ContentVersion(
      id: 'version_${DateTime.now().millisecondsSinceEpoch}',
      versionNumber: nextVersionNumber,
      title: title,
      description: description,
      body: body,
      authorId: content.authorId,
      createdAt: DateTime.now(),
      changeLog: changeLog,
    );

    final updatedContent = content.copyWith(
      versions: [...content.versions, newVersion],
      updatedAt: DateTime.now(),
    );

    return await updateContent(contentId, updatedContent);
  }

  Future<void> processContent(String contentId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('https://api.example.com/content/$contentId/process'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (kDebugMode) {
          print('Content processing completed: $result');
        }
      } else {
        throw Exception('Failed to process content: ${response.statusCode}');
      }
    } catch (e) {
      _error = 'Failed to process content: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _initWebSocket() {
    try {
      _workflowChannel = WebSocketChannel.connect(
        Uri.parse('wss://api.example.com/publishing-workflow'),
      );

      _workflowChannel!.stream.listen(
        (message) {
          final data = jsonDecode(message);
          if (data['type'] == 'workflow_update') {
            _handleWorkflowUpdate(data);
          }
        },
        onError: (error) {
          if (kDebugMode) {
            print('WebSocket error: $error');
          }
        },
        onDone: () {
          _attemptReconnect();
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('Failed to connect workflow WebSocket: $e');
      }
    }
  }

  void _handleWorkflowUpdate(Map<String, dynamic> data) {
    final contentId = data['contentId'];
    final newStatus = ContentStatus.values.firstWhere(
      (status) => status.name == data['status'],
      orElse: () => ContentStatus.draft,
    );

    final contentIndex = _contents.indexWhere((c) => c.id == contentId);
    if (contentIndex >= 0) {
      _contents[contentIndex] = _contents[contentIndex].copyWith(
        status: newStatus,
        updatedAt: DateTime.now(),
      );
      notifyListeners();
    }
  }

  void _attemptReconnect() {
    Future.delayed(const Duration(seconds: 5), () {
      _initWebSocket();
    });
  }

  List<Content> getContentsByStatus(ContentStatus status) {
    return _contents.where((content) => content.status == status).toList();
  }

  List<Content> getContentsByAuthor(String authorId) {
    return _contents.where((content) => content.authorId == authorId).toList();
  }

  @override
  void dispose() {
    _workflowChannel?.sink.close();
    super.dispose();
  }
}