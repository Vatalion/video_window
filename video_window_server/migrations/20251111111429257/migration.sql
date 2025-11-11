BEGIN;

--
-- ACTION CREATE TABLE
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
-- ACTION CREATE TABLE
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
-- ACTION CREATE TABLE
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
-- ACTION CREATE TABLE
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
-- ACTION CREATE TABLE
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
-- ACTION CREATE TABLE
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
-- MIGRATION VERSION FOR video_window
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('video_window', '20251111111429257', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20251111111429257', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20240516151843329', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20240516151843329', "timestamp" = now();


COMMIT;
