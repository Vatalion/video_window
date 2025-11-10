BEGIN;

--
-- ACTION CREATE TABLE
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
-- ACTION CREATE TABLE
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
-- ACTION CREATE TABLE
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
-- ACTION CREATE TABLE
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
-- MIGRATION VERSION FOR video_window
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('video_window', '20251110120541566', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20251110120541566', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20240516151843329', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20240516151843329', "timestamp" = now();


COMMIT;
