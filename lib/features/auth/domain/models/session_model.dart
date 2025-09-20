import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

class SessionModel extends Equatable {
  final String id;
  final String userId;
  final String deviceId;
  final String sessionId;
  final String ipAddress;
  final String? userAgent;
  final String? location;
  final SessionStatus status;
  final DateTime startTime;
  final DateTime? endTime;
  final DateTime lastActivity;
  final Duration timeoutDuration;
  final bool isPersistent;
  final String? sessionFingerprint;
  final Map<String, dynamic> metadata;
  final int consecutiveFailures;
  final bool isLocked;
  final DateTime? lockedUntil;
  final SecurityLevel securityLevel;

  const SessionModel({
    required this.id,
    required this.userId,
    required this.deviceId,
    required this.sessionId,
    required this.ipAddress,
    this.userAgent,
    this.location,
    this.status = SessionStatus.active,
    required this.startTime,
    this.endTime,
    required this.lastActivity,
    this.timeoutDuration = const Duration(minutes: 30),
    this.isPersistent = false,
    this.sessionFingerprint,
    this.metadata = const {},
    this.consecutiveFailures = 0,
    this.isLocked = false,
    this.lockedUntil,
    this.securityLevel = SecurityLevel.standard,
  });

  factory SessionModel.fromJson(Map<String, dynamic> json) {
    return SessionModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      deviceId: json['device_id'] as String,
      sessionId: json['session_id'] as String,
      ipAddress: json['ip_address'] as String,
      userAgent: json['user_agent'] as String?,
      location: json['location'] as String?,
      status: SessionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => SessionStatus.active,
      ),
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time'] as String)
          : null,
      lastActivity: DateTime.parse(json['last_activity'] as String),
      timeoutDuration: Duration(minutes: json['timeout_minutes'] as int? ?? 30),
      isPersistent: json['is_persistent'] as bool,
      sessionFingerprint: json['session_fingerprint'] as String?,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      consecutiveFailures: json['consecutive_failures'] as int,
      isLocked: json['is_locked'] as bool,
      lockedUntil: json['locked_until'] != null
          ? DateTime.parse(json['locked_until'] as String)
          : null,
      securityLevel: SecurityLevel.values.firstWhere(
        (e) => e.name == json['security_level'],
        orElse: () => SecurityLevel.standard,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'device_id': deviceId,
      'session_id': sessionId,
      'ip_address': ipAddress,
      'user_agent': userAgent,
      'location': location,
      'status': status.name,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'last_activity': lastActivity.toIso8601String(),
      'timeout_minutes': timeoutDuration.inMinutes,
      'is_persistent': isPersistent,
      'session_fingerprint': sessionFingerprint,
      'metadata': metadata,
      'consecutive_failures': consecutiveFailures,
      'is_locked': isLocked,
      'locked_until': lockedUntil?.toIso8601String(),
      'security_level': securityLevel.name,
    };
  }

  SessionModel copyWith({
    String? id,
    String? userId,
    String? deviceId,
    String? sessionId,
    String? ipAddress,
    String? userAgent,
    String? location,
    SessionStatus? status,
    DateTime? startTime,
    DateTime? endTime,
    DateTime? lastActivity,
    Duration? timeoutDuration,
    bool? isPersistent,
    String? sessionFingerprint,
    Map<String, dynamic>? metadata,
    int? consecutiveFailures,
    bool? isLocked,
    DateTime? lockedUntil,
    SecurityLevel? securityLevel,
  }) {
    return SessionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      deviceId: deviceId ?? this.deviceId,
      sessionId: sessionId ?? this.sessionId,
      ipAddress: ipAddress ?? this.ipAddress,
      userAgent: userAgent ?? this.userAgent,
      location: location ?? this.location,
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      lastActivity: lastActivity ?? this.lastActivity,
      timeoutDuration: timeoutDuration ?? this.timeoutDuration,
      isPersistent: isPersistent ?? this.isPersistent,
      sessionFingerprint: sessionFingerprint ?? this.sessionFingerprint,
      metadata: metadata ?? this.metadata,
      consecutiveFailures: consecutiveFailures ?? this.consecutiveFailures,
      isLocked: isLocked ?? this.isLocked,
      lockedUntil: lockedUntil ?? this.lockedUntil,
      securityLevel: securityLevel ?? this.securityLevel,
    );
  }

  bool get isActive => status == SessionStatus.active;
  bool get isExpired => status == SessionStatus.expired;
  bool get isTerminated => status == SessionStatus.terminated;
  bool get isSuspended => status == SessionStatus.suspended;

  bool get isLockedDueToFailures =>
      isLocked && lockedUntil != null && DateTime.now().isBefore(lockedUntil!);
  bool get isTimeout =>
      DateTime.now().difference(lastActivity) > timeoutDuration;
  bool get needsLock => consecutiveFailures >= 5 && !isLocked;

  String get activityStatus => _getActivityStatus();
  String get securityStatus => _getSecurityStatus();
  Duration get remainingTime =>
      timeoutDuration - DateTime.now().difference(lastActivity);

  String _getActivityStatus() {
    if (isTerminated) return 'Terminated';
    if (isExpired) return 'Expired';
    if (isSuspended) return 'Suspended';
    if (isLocked) return 'Locked';
    if (isTimeout) return 'Timeout';
    return 'Active';
  }

  String _getSecurityStatus() {
    if (isLockedDueToFailures) return 'High Risk';
    if (consecutiveFailures >= 3) return 'Medium Risk';
    if (securityLevel == SecurityLevel.high) return 'High Security';
    return securityLevel.name;
  }

  SessionModel updateActivity() {
    return copyWith(lastActivity: DateTime.now());
  }

  SessionModel incrementFailures() {
    final newFailures = consecutiveFailures + 1;
    final shouldLock = newFailures >= 5;

    return copyWith(
      consecutiveFailures: newFailures,
      isLocked: shouldLock,
      lockedUntil: shouldLock
          ? DateTime.now().add(const Duration(minutes: 30))
          : null,
    );
  }

  SessionModel resetFailures() {
    return copyWith(consecutiveFailures: 0, isLocked: false, lockedUntil: null);
  }

  SessionModel terminate() {
    return copyWith(status: SessionStatus.terminated, endTime: DateTime.now());
  }

  SessionModel expire() {
    return copyWith(status: SessionStatus.expired, endTime: DateTime.now());
  }

  SessionModel suspend({Duration? duration}) {
    return copyWith(
      status: SessionStatus.suspended,
      lockedUntil: duration != null ? DateTime.now().add(duration) : null,
    );
  }

  static SessionModel create({
    required String userId,
    required String deviceId,
    required String sessionId,
    required String ipAddress,
    String? userAgent,
    String? location,
    Duration timeoutDuration = const Duration(minutes: 30),
    bool isPersistent = false,
    SecurityLevel securityLevel = SecurityLevel.standard,
    Map<String, dynamic> metadata = const {},
  }) {
    final now = DateTime.now();
    return SessionModel(
      id: const Uuid().v4(),
      userId: userId,
      deviceId: deviceId,
      sessionId: sessionId,
      ipAddress: ipAddress,
      userAgent: userAgent,
      location: location,
      startTime: now,
      lastActivity: now,
      timeoutDuration: timeoutDuration,
      isPersistent: isPersistent,
      metadata: metadata,
      securityLevel: securityLevel,
    );
  }

  @override
  List<Object> get props => [
    id,
    userId,
    deviceId,
    sessionId,
    ipAddress,
    userAgent ?? '',
    location ?? '',
    status,
    startTime,
    endTime ?? '',
    lastActivity,
    timeoutDuration.inMinutes,
    isPersistent,
    sessionFingerprint ?? '',
    metadata,
    consecutiveFailures,
    isLocked,
    lockedUntil ?? '',
    securityLevel,
  ];
}

enum SessionStatus { active, expired, terminated, suspended }

enum SecurityLevel { low, standard, high, maximum }
