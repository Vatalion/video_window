-- Migration: Add recovery_tokens table for account recovery
-- Story: 1-4 Account Recovery (Email Only)
-- Date: 2025-11-11

-- Create recovery_tokens table for one-time recovery tokens
CREATE TABLE IF NOT EXISTS recovery_tokens (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token_hash TEXT NOT NULL UNIQUE,
  jti TEXT NOT NULL UNIQUE,
  expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
  used_at TIMESTAMP WITH TIME ZONE,
  revoked BOOLEAN DEFAULT FALSE,
  ip_address TEXT,
  user_agent TEXT,
  device_fingerprint TEXT,
  location_data TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  
  -- Indexes for performance
  INDEX idx_recovery_tokens_jti ON recovery_tokens(jti),
  INDEX idx_recovery_tokens_user_id ON recovery_tokens(user_id),
  INDEX idx_recovery_tokens_expires_at ON recovery_tokens(expires_at),
  INDEX idx_recovery_tokens_used ON recovery_tokens(used_at)
);

-- Comments for documentation
COMMENT ON TABLE recovery_tokens IS 'Stores one-time recovery tokens for account recovery (Story 1-4)';
COMMENT ON COLUMN recovery_tokens.token_hash IS 'bcrypt hash of the recovery token (plaintext never stored)';
COMMENT ON COLUMN recovery_tokens.jti IS 'Unique token ID for tracking and revocation';
COMMENT ON COLUMN recovery_tokens.expires_at IS '15-minute expiration from issuance';
COMMENT ON COLUMN recovery_tokens.used_at IS 'Timestamp of token use - non-null prevents reuse';
COMMENT ON COLUMN recovery_tokens.revoked IS 'Manual revocation via "Not You?" link';
COMMENT ON COLUMN recovery_tokens.location_data IS 'GeoIP data for security context in recovery email';

