BEGIN;

--
-- Class CapabilityAuditEvent as table capability_audit_events
--
CREATE TABLE "capability_audit_events" (
    "id" bigserial PRIMARY KEY,
    "userId" bigint NOT NULL,
    "eventType" text NOT NULL,
    "capability" bigint,
    "entryPoint" text,
    "deviceFingerprint" text,
    "metadata" text NOT NULL,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "capability_audit_event_user_id_idx" ON "capability_audit_events" USING btree ("userId");
CREATE INDEX "capability_audit_event_type_idx" ON "capability_audit_events" USING btree ("eventType");
CREATE INDEX "capability_audit_event_created_idx" ON "capability_audit_events" USING btree ("createdAt");
CREATE INDEX "capability_audit_event_capability_idx" ON "capability_audit_events" USING btree ("capability");

--
-- Class CapabilityRequest as table capability_requests
--
CREATE TABLE "capability_requests" (
    "id" bigserial PRIMARY KEY,
    "userId" bigint NOT NULL,
    "capability" bigint NOT NULL,
    "status" bigint NOT NULL,
    "metadata" text NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL,
    "resolvedAt" timestamp without time zone
);

-- Indexes
CREATE UNIQUE INDEX "capability_request_user_capability_idx" ON "capability_requests" USING btree ("userId", "capability");
CREATE INDEX "capability_request_status_idx" ON "capability_requests" USING btree ("status");
CREATE INDEX "capability_request_created_idx" ON "capability_requests" USING btree ("createdAt");

--
-- Class DsarRequest as table dsar_requests
--
CREATE TABLE "dsar_requests" (
    "id" bigserial PRIMARY KEY,
    "userId" bigint NOT NULL,
    "requestType" text NOT NULL,
    "status" text NOT NULL,
    "requestedAt" timestamp without time zone NOT NULL,
    "completedAt" timestamp without time zone,
    "requestData" text,
    "auditLog" text,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "dsar_user_id_idx" ON "dsar_requests" USING btree ("userId");
CREATE INDEX "dsar_status_idx" ON "dsar_requests" USING btree ("status");
CREATE INDEX "dsar_request_type_idx" ON "dsar_requests" USING btree ("requestType");

--
-- Class MediaFile as table media_files
--
CREATE TABLE "media_files" (
    "id" bigserial PRIMARY KEY,
    "userId" bigint NOT NULL,
    "type" text NOT NULL,
    "originalFileName" text NOT NULL,
    "s3Key" text NOT NULL,
    "cdnUrl" text,
    "mimeType" text NOT NULL,
    "fileSizeBytes" bigint NOT NULL,
    "metadata" text,
    "status" text NOT NULL,
    "isVirusScanned" boolean NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "media_user_id_idx" ON "media_files" USING btree ("userId");
CREATE INDEX "media_status_idx" ON "media_files" USING btree ("status");
CREATE INDEX "media_s3_key_idx" ON "media_files" USING btree ("s3Key");

--
-- Class Otp as table otps
--
CREATE TABLE "otps" (
    "id" bigserial PRIMARY KEY,
    "identifier" text NOT NULL,
    "otpHash" text NOT NULL,
    "salt" text NOT NULL,
    "attempts" bigint NOT NULL,
    "used" boolean NOT NULL,
    "expiresAt" timestamp without time zone NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "usedAt" timestamp without time zone
);

-- Indexes
CREATE INDEX "identifier_idx" ON "otps" USING btree ("identifier");

--
-- Class PrivacyAuditLog as table privacy_audit_log
--
CREATE TABLE "privacy_audit_log" (
    "id" bigserial PRIMARY KEY,
    "userId" bigint NOT NULL,
    "actorId" bigint NOT NULL,
    "settingName" text NOT NULL,
    "oldValue" text NOT NULL,
    "newValue" text NOT NULL,
    "changeSummary" text NOT NULL,
    "auditContext" text,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "privacy_audit_log_user_id_idx" ON "privacy_audit_log" USING btree ("userId");
CREATE INDEX "privacy_audit_log_actor_idx" ON "privacy_audit_log" USING btree ("actorId");
CREATE INDEX "privacy_audit_log_created_idx" ON "privacy_audit_log" USING btree ("createdAt");
CREATE INDEX "privacy_audit_log_setting_idx" ON "privacy_audit_log" USING btree ("settingName");

--
-- Class RecoveryToken as table recovery_tokens
--
CREATE TABLE "recovery_tokens" (
    "id" bigserial PRIMARY KEY,
    "userId" bigint NOT NULL,
    "email" text NOT NULL,
    "tokenHash" text NOT NULL,
    "salt" text NOT NULL,
    "deviceInfo" text,
    "ipAddress" text NOT NULL,
    "userAgent" text,
    "location" text,
    "attempts" bigint NOT NULL,
    "used" boolean NOT NULL,
    "revoked" boolean NOT NULL,
    "expiresAt" timestamp without time zone NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "usedAt" timestamp without time zone,
    "revokedAt" timestamp without time zone
);

-- Indexes
CREATE INDEX "recovery_user_id_idx" ON "recovery_tokens" USING btree ("userId");
CREATE INDEX "recovery_email_idx" ON "recovery_tokens" USING btree ("email");
CREATE INDEX "recovery_used_idx" ON "recovery_tokens" USING btree ("used");

--
-- Class UserSession as table sessions
--
CREATE TABLE "sessions" (
    "id" bigserial PRIMARY KEY,
    "userId" bigint NOT NULL,
    "accessToken" text NOT NULL,
    "refreshToken" text NOT NULL,
    "deviceId" text NOT NULL,
    "deviceInfo" text,
    "accessTokenExpiry" timestamp without time zone NOT NULL,
    "refreshTokenExpiry" timestamp without time zone NOT NULL,
    "ipAddress" text,
    "isRevoked" boolean NOT NULL,
    "revokedAt" timestamp without time zone,
    "createdAt" timestamp without time zone NOT NULL,
    "lastUsedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "refresh_token_idx" ON "sessions" USING btree ("refreshToken");

--
-- Class TokenBlacklist as table token_blacklist
--
CREATE TABLE "token_blacklist" (
    "id" bigserial PRIMARY KEY,
    "tokenId" text NOT NULL,
    "tokenType" text NOT NULL,
    "userId" bigint NOT NULL,
    "reason" text,
    "expiresAt" timestamp without time zone NOT NULL,
    "blacklistedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "token_id_idx" ON "token_blacklist" USING btree ("tokenId");
CREATE INDEX "user_id_idx" ON "token_blacklist" USING btree ("userId");

--
-- Class TrustedDevice as table trusted_devices
--
CREATE TABLE "trusted_devices" (
    "id" bigserial PRIMARY KEY,
    "userId" bigint NOT NULL,
    "deviceId" text NOT NULL,
    "deviceType" text NOT NULL,
    "platform" text NOT NULL,
    "trustScore" double precision NOT NULL,
    "telemetry" text NOT NULL,
    "lastSeenAt" timestamp without time zone NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "revokedAt" timestamp without time zone
);

-- Indexes
CREATE UNIQUE INDEX "trusted_device_user_device_idx" ON "trusted_devices" USING btree ("userId", "deviceId");
CREATE INDEX "trusted_device_user_id_idx" ON "trusted_devices" USING btree ("userId");
CREATE INDEX "trusted_device_last_seen_idx" ON "trusted_devices" USING btree ("lastSeenAt");

--
-- Class UserCapabilities as table user_capabilities
--
CREATE TABLE "user_capabilities" (
    "id" bigserial PRIMARY KEY,
    "userId" bigint NOT NULL,
    "canPublish" boolean NOT NULL,
    "canCollectPayments" boolean NOT NULL,
    "canFulfillOrders" boolean NOT NULL,
    "identityVerifiedAt" timestamp without time zone,
    "payoutConfiguredAt" timestamp without time zone,
    "fulfillmentEnabledAt" timestamp without time zone,
    "reviewState" bigint NOT NULL,
    "blockers" text NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "user_capabilities_user_id_idx" ON "user_capabilities" USING btree ("userId");

--
-- Class UserInteraction as table user_interactions
--
CREATE TABLE "user_interactions" (
    "id" bigserial PRIMARY KEY,
    "userId" bigint NOT NULL,
    "videoId" text NOT NULL,
    "interactionType" text NOT NULL,
    "watchTimeSeconds" bigint,
    "metadata" text,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "interaction_user_id_idx" ON "user_interactions" USING btree ("userId", "createdAt");
CREATE INDEX "interaction_video_id_idx" ON "user_interactions" USING btree ("videoId", "createdAt");
CREATE INDEX "interaction_type_idx" ON "user_interactions" USING btree ("interactionType", "createdAt");
CREATE INDEX "interaction_composite_idx" ON "user_interactions" USING btree ("userId", "videoId", "interactionType", "createdAt");

--
-- Class NotificationPreferences as table user_notification_preferences
--
CREATE TABLE "user_notification_preferences" (
    "id" bigserial PRIMARY KEY,
    "userId" bigint NOT NULL,
    "emailNotifications" boolean NOT NULL,
    "pushNotifications" boolean NOT NULL,
    "inAppNotifications" boolean NOT NULL,
    "settings" text,
    "quietHours" text,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "notification_user_id_idx" ON "user_notification_preferences" USING btree ("userId");

--
-- Class PrivacySettings as table user_privacy_settings
--
CREATE TABLE "user_privacy_settings" (
    "id" bigserial PRIMARY KEY,
    "userId" bigint NOT NULL,
    "profileVisibility" text NOT NULL,
    "showEmailToPublic" boolean NOT NULL,
    "showPhoneToFriends" boolean NOT NULL,
    "allowTagging" boolean NOT NULL,
    "allowSearchByPhone" boolean NOT NULL,
    "allowDataAnalytics" boolean NOT NULL,
    "allowMarketingEmails" boolean NOT NULL,
    "allowPushNotifications" boolean NOT NULL,
    "shareProfileWithPartners" boolean NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "privacy_user_id_idx" ON "user_privacy_settings" USING btree ("userId");

--
-- Class UserProfile as table user_profiles
--
CREATE TABLE "user_profiles" (
    "id" bigserial PRIMARY KEY,
    "userId" bigint NOT NULL,
    "username" text,
    "fullName" text,
    "bio" text,
    "avatarUrl" text,
    "profileData" text,
    "visibility" text NOT NULL,
    "isVerified" boolean NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "profile_user_id_idx" ON "user_profiles" USING btree ("userId");

--
-- Class User as table users
--
CREATE TABLE "users" (
    "id" bigserial PRIMARY KEY,
    "email" text,
    "phone" text,
    "role" text NOT NULL,
    "authProvider" text NOT NULL,
    "isEmailVerified" boolean NOT NULL,
    "isPhoneVerified" boolean NOT NULL,
    "isActive" boolean NOT NULL,
    "failedAttempts" bigint NOT NULL,
    "lockedUntil" timestamp without time zone,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL,
    "lastLoginAt" timestamp without time zone
);

-- Indexes
CREATE INDEX "email_idx" ON "users" USING btree ("email");
CREATE INDEX "phone_idx" ON "users" USING btree ("phone");

--
-- Class VerificationTask as table verification_tasks
--
CREATE TABLE "verification_tasks" (
    "id" bigserial PRIMARY KEY,
    "userId" bigint NOT NULL,
    "capability" bigint NOT NULL,
    "taskType" bigint NOT NULL,
    "status" bigint NOT NULL,
    "payload" text NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL,
    "completedAt" timestamp without time zone
);

-- Indexes
CREATE INDEX "verification_task_user_id_idx" ON "verification_tasks" USING btree ("userId");
CREATE INDEX "verification_task_status_idx" ON "verification_tasks" USING btree ("status");
CREATE INDEX "verification_task_capability_idx" ON "verification_tasks" USING btree ("capability");

--
-- Class CloudStorageEntry as table serverpod_cloud_storage
--
CREATE TABLE "serverpod_cloud_storage" (
    "id" bigserial PRIMARY KEY,
    "storageId" text NOT NULL,
    "path" text NOT NULL,
    "addedTime" timestamp without time zone NOT NULL,
    "expiration" timestamp without time zone,
    "byteData" bytea NOT NULL,
    "verified" boolean NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_cloud_storage_path_idx" ON "serverpod_cloud_storage" USING btree ("storageId", "path");
CREATE INDEX "serverpod_cloud_storage_expiration" ON "serverpod_cloud_storage" USING btree ("expiration");

--
-- Class CloudStorageDirectUploadEntry as table serverpod_cloud_storage_direct_upload
--
CREATE TABLE "serverpod_cloud_storage_direct_upload" (
    "id" bigserial PRIMARY KEY,
    "storageId" text NOT NULL,
    "path" text NOT NULL,
    "expiration" timestamp without time zone NOT NULL,
    "authKey" text NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_cloud_storage_direct_upload_storage_path" ON "serverpod_cloud_storage_direct_upload" USING btree ("storageId", "path");

--
-- Class FutureCallEntry as table serverpod_future_call
--
CREATE TABLE "serverpod_future_call" (
    "id" bigserial PRIMARY KEY,
    "name" text NOT NULL,
    "time" timestamp without time zone NOT NULL,
    "serializedObject" text,
    "serverId" text NOT NULL,
    "identifier" text
);

-- Indexes
CREATE INDEX "serverpod_future_call_time_idx" ON "serverpod_future_call" USING btree ("time");
CREATE INDEX "serverpod_future_call_serverId_idx" ON "serverpod_future_call" USING btree ("serverId");
CREATE INDEX "serverpod_future_call_identifier_idx" ON "serverpod_future_call" USING btree ("identifier");

--
-- Class ServerHealthConnectionInfo as table serverpod_health_connection_info
--
CREATE TABLE "serverpod_health_connection_info" (
    "id" bigserial PRIMARY KEY,
    "serverId" text NOT NULL,
    "timestamp" timestamp without time zone NOT NULL,
    "active" bigint NOT NULL,
    "closing" bigint NOT NULL,
    "idle" bigint NOT NULL,
    "granularity" bigint NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_health_connection_info_timestamp_idx" ON "serverpod_health_connection_info" USING btree ("timestamp", "serverId", "granularity");

--
-- Class ServerHealthMetric as table serverpod_health_metric
--
CREATE TABLE "serverpod_health_metric" (
    "id" bigserial PRIMARY KEY,
    "name" text NOT NULL,
    "serverId" text NOT NULL,
    "timestamp" timestamp without time zone NOT NULL,
    "isHealthy" boolean NOT NULL,
    "value" double precision NOT NULL,
    "granularity" bigint NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_health_metric_timestamp_idx" ON "serverpod_health_metric" USING btree ("timestamp", "serverId", "name", "granularity");

--
-- Class LogEntry as table serverpod_log
--
CREATE TABLE "serverpod_log" (
    "id" bigserial PRIMARY KEY,
    "sessionLogId" bigint NOT NULL,
    "messageId" bigint,
    "reference" text,
    "serverId" text NOT NULL,
    "time" timestamp without time zone NOT NULL,
    "logLevel" bigint NOT NULL,
    "message" text NOT NULL,
    "error" text,
    "stackTrace" text,
    "order" bigint NOT NULL
);

-- Indexes
CREATE INDEX "serverpod_log_sessionLogId_idx" ON "serverpod_log" USING btree ("sessionLogId");

--
-- Class MessageLogEntry as table serverpod_message_log
--
CREATE TABLE "serverpod_message_log" (
    "id" bigserial PRIMARY KEY,
    "sessionLogId" bigint NOT NULL,
    "serverId" text NOT NULL,
    "messageId" bigint NOT NULL,
    "endpoint" text NOT NULL,
    "messageName" text NOT NULL,
    "duration" double precision NOT NULL,
    "error" text,
    "stackTrace" text,
    "slow" boolean NOT NULL,
    "order" bigint NOT NULL
);

--
-- Class MethodInfo as table serverpod_method
--
CREATE TABLE "serverpod_method" (
    "id" bigserial PRIMARY KEY,
    "endpoint" text NOT NULL,
    "method" text NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_method_endpoint_method_idx" ON "serverpod_method" USING btree ("endpoint", "method");

--
-- Class DatabaseMigrationVersion as table serverpod_migrations
--
CREATE TABLE "serverpod_migrations" (
    "id" bigserial PRIMARY KEY,
    "module" text NOT NULL,
    "version" text NOT NULL,
    "timestamp" timestamp without time zone
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_migrations_ids" ON "serverpod_migrations" USING btree ("module");

--
-- Class QueryLogEntry as table serverpod_query_log
--
CREATE TABLE "serverpod_query_log" (
    "id" bigserial PRIMARY KEY,
    "serverId" text NOT NULL,
    "sessionLogId" bigint NOT NULL,
    "messageId" bigint,
    "query" text NOT NULL,
    "duration" double precision NOT NULL,
    "numRows" bigint,
    "error" text,
    "stackTrace" text,
    "slow" boolean NOT NULL,
    "order" bigint NOT NULL
);

-- Indexes
CREATE INDEX "serverpod_query_log_sessionLogId_idx" ON "serverpod_query_log" USING btree ("sessionLogId");

--
-- Class ReadWriteTestEntry as table serverpod_readwrite_test
--
CREATE TABLE "serverpod_readwrite_test" (
    "id" bigserial PRIMARY KEY,
    "number" bigint NOT NULL
);

--
-- Class RuntimeSettings as table serverpod_runtime_settings
--
CREATE TABLE "serverpod_runtime_settings" (
    "id" bigserial PRIMARY KEY,
    "logSettings" json NOT NULL,
    "logSettingsOverrides" json NOT NULL,
    "logServiceCalls" boolean NOT NULL,
    "logMalformedCalls" boolean NOT NULL
);

--
-- Class SessionLogEntry as table serverpod_session_log
--
CREATE TABLE "serverpod_session_log" (
    "id" bigserial PRIMARY KEY,
    "serverId" text NOT NULL,
    "time" timestamp without time zone NOT NULL,
    "module" text,
    "endpoint" text,
    "method" text,
    "duration" double precision,
    "numQueries" bigint,
    "slow" boolean,
    "error" text,
    "stackTrace" text,
    "authenticatedUserId" bigint,
    "isOpen" boolean,
    "touched" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "serverpod_session_log_serverid_idx" ON "serverpod_session_log" USING btree ("serverId");
CREATE INDEX "serverpod_session_log_touched_idx" ON "serverpod_session_log" USING btree ("touched");
CREATE INDEX "serverpod_session_log_isopen_idx" ON "serverpod_session_log" USING btree ("isOpen");

--
-- Foreign relations for "serverpod_log" table
--
ALTER TABLE ONLY "serverpod_log"
    ADD CONSTRAINT "serverpod_log_fk_0"
    FOREIGN KEY("sessionLogId")
    REFERENCES "serverpod_session_log"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "serverpod_message_log" table
--
ALTER TABLE ONLY "serverpod_message_log"
    ADD CONSTRAINT "serverpod_message_log_fk_0"
    FOREIGN KEY("sessionLogId")
    REFERENCES "serverpod_session_log"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "serverpod_query_log" table
--
ALTER TABLE ONLY "serverpod_query_log"
    ADD CONSTRAINT "serverpod_query_log_fk_0"
    FOREIGN KEY("sessionLogId")
    REFERENCES "serverpod_session_log"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;


--
-- MIGRATION VERSION FOR video_window
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('video_window', '20251111173322658', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20251111173322658', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20240516151843329', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20240516151843329', "timestamp" = now();


COMMIT;
