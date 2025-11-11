-- Migration: Add refresh_tokens and security_events tables
-- Story: 1-3 Session Management & Refresh
-- Date: 2025-11-11

-- Create refresh_tokens table for token rotation and reuse detection
CREATE TABLE IF NOT EXISTS refresh_tokens (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token_hash TEXT NOT NULL,
  jti TEXT NOT NULL UNIQUE,
  expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
  device_id TEXT,
  device_fingerprint TEXT,
  ip_address TEXT,
  user_agent TEXT,
  rotation_count INTEGER DEFAULT 0,
  last_used_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  revoked BOOLEAN DEFAULT FALSE
);

-- Indexes for refresh_tokens
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_jti ON refresh_tokens(jti);
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_user_id ON refresh_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_expires_at ON refresh_tokens(expires_at);
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_revoked ON refresh_tokens(revoked) WHERE revoked = false;

-- Create security_events table for audit trail
CREATE TABLE IF NOT EXISTS security_events (
  id SERIAL PRIMARY KEY,
  event_type TEXT NOT NULL,
  user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
  severity TEXT NOT NULL CHECK (severity IN ('info', 'warning', 'error', 'critical')),
  metadata JSONB,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Indexes for security_events
CREATE INDEX IF NOT EXISTS idx_security_events_event_type ON security_events(event_type);
CREATE INDEX IF NOT EXISTS idx_security_events_user_id ON security_events(user_id);
CREATE INDEX IF NOT EXISTS idx_security_events_severity ON security_events(severity);
CREATE INDEX IF NOT EXISTS idx_security_events_created_at ON security_events(created_at DESC);

-- Add comments for documentation
COMMENT ON TABLE refresh_tokens IS 'Stores refresh tokens with rotation and reuse detection for SEC-003 compliance';
COMMENT ON COLUMN refresh_tokens.token_hash IS 'SHA-256 hash of the refresh token (plaintext never stored)';
COMMENT ON COLUMN refresh_tokens.jti IS 'JWT ID for token correlation';
COMMENT ON COLUMN refresh_tokens.last_used_at IS 'Timestamp of last use - non-null indicates token reuse attempt';
COMMENT ON COLUMN refresh_tokens.rotation_count IS 'Number of times this token family has been rotated';

COMMENT ON TABLE security_events IS 'Audit log for security-related events (token rotation, reuse, revocation)';
COMMENT ON COLUMN security_events.event_type IS 'Event type: auth.session.rotated, auth.session.revoked, auth.session.reuse_detected, etc.';
COMMENT ON COLUMN security_events.metadata IS 'Additional event context as JSON';

