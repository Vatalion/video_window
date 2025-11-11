BEGIN;

--
-- ACTION CREATE TABLE
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
-- ACTION CREATE TABLE
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
-- ACTION CREATE TABLE
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
-- ACTION CREATE TABLE
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
-- ACTION CREATE TABLE
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
-- ACTION CREATE TABLE
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
-- ACTION CREATE TABLE
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
