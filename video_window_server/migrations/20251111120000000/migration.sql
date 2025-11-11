BEGIN;

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
-- MIGRATION VERSION FOR video_window
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('video_window', '20251111120000000', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20251111120000000', "timestamp" = now();

COMMIT;

