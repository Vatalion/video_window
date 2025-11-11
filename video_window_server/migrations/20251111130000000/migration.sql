-- Migration: Capability system tables
-- Epic 2: Capability Enablement & Verification
-- Story 2-1: Capability Enablement Request Flow
-- Created: 2025-11-11

-- User capabilities snapshot table
CREATE TABLE user_capabilities (
  user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  can_publish BOOLEAN NOT NULL DEFAULT false,
  can_collect_payments BOOLEAN NOT NULL DEFAULT false,
  can_fulfill_orders BOOLEAN NOT NULL DEFAULT false,
  identity_verified_at TIMESTAMPTZ,
  payout_configured_at TIMESTAMPTZ,
  fulfillment_enabled_at TIMESTAMPTZ,
  review_state VARCHAR(32) NOT NULL DEFAULT 'none',
  blockers JSONB NOT NULL DEFAULT '{}'::jsonb,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index for efficient lookups
CREATE INDEX idx_user_capabilities_user_id ON user_capabilities(user_id);

-- Capability requests tracking table
CREATE TABLE capability_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  capability VARCHAR(32) NOT NULL,
  status VARCHAR(32) NOT NULL,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  resolved_at TIMESTAMPTZ,
  CONSTRAINT unique_user_capability UNIQUE(user_id, capability),
  CONSTRAINT valid_capability CHECK (capability IN ('publish', 'collect_payments', 'fulfill_orders')),
  CONSTRAINT valid_status CHECK (status IN ('requested', 'in_review', 'approved', 'blocked'))
);

-- Indexes for capability requests
CREATE INDEX idx_capability_requests_user_id ON capability_requests(user_id);
CREATE INDEX idx_capability_requests_status ON capability_requests(status);
CREATE INDEX idx_capability_requests_created_at ON capability_requests(created_at DESC);

-- Verification tasks table for identity/payout/compliance checks
CREATE TABLE verification_tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  capability VARCHAR(32) NOT NULL,
  task_type VARCHAR(32) NOT NULL,
  status VARCHAR(32) NOT NULL,
  payload JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  completed_at TIMESTAMPTZ,
  CONSTRAINT valid_task_type CHECK (task_type IN ('persona_identity', 'stripe_payout', 'compliance_doc', 'device_trust')),
  CONSTRAINT valid_task_status CHECK (status IN ('pending', 'in_progress', 'completed', 'failed'))
);

-- Indexes for verification tasks
CREATE INDEX idx_verification_tasks_user_id ON verification_tasks(user_id);
CREATE INDEX idx_verification_tasks_status ON verification_tasks(status);
CREATE INDEX idx_verification_tasks_capability ON verification_tasks(capability);

-- Trusted devices table for device trust scoring
CREATE TABLE trusted_devices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  device_id VARCHAR(255) NOT NULL,
  device_type VARCHAR(100) NOT NULL,
  platform VARCHAR(50) NOT NULL,
  trust_score NUMERIC(5,2) NOT NULL DEFAULT 0.80,
  telemetry JSONB DEFAULT '{}'::jsonb,
  last_seen_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  revoked_at TIMESTAMPTZ,
  CONSTRAINT unique_user_device UNIQUE(user_id, device_id),
  CONSTRAINT valid_trust_score CHECK (trust_score >= 0.0 AND trust_score <= 1.0)
);

-- Indexes for trusted devices
CREATE INDEX idx_trusted_devices_user_id ON trusted_devices(user_id);
CREATE INDEX idx_trusted_devices_device_id ON trusted_devices(device_id);
CREATE INDEX idx_trusted_devices_last_seen ON trusted_devices(last_seen_at DESC);

-- Audit events for capability changes
CREATE TABLE capability_audit_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  event_type VARCHAR(64) NOT NULL,
  capability VARCHAR(32),
  entry_point VARCHAR(100),
  device_fingerprint VARCHAR(255),
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT valid_event_type CHECK (event_type IN ('capability.requested', 'capability.approved', 'capability.blocked', 'capability.revoked', 'device.registered', 'device.revoked'))
);

-- Indexes for audit events
CREATE INDEX idx_capability_audit_events_user_id ON capability_audit_events(user_id);
CREATE INDEX idx_capability_audit_events_type ON capability_audit_events(event_type);
CREATE INDEX idx_capability_audit_events_created ON capability_audit_events(created_at DESC);
CREATE INDEX idx_capability_audit_events_capability ON capability_audit_events(capability);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers for automatic updated_at maintenance
CREATE TRIGGER update_user_capabilities_updated_at
  BEFORE UPDATE ON user_capabilities
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_capability_requests_updated_at
  BEFORE UPDATE ON capability_requests
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_verification_tasks_updated_at
  BEFORE UPDATE ON verification_tasks
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Comments for documentation
COMMENT ON TABLE user_capabilities IS 'Snapshot of user capability flags and metadata';
COMMENT ON TABLE capability_requests IS 'Tracks requests for capability enablement with idempotency';
COMMENT ON TABLE verification_tasks IS 'Individual verification tasks (identity, payout, compliance)';
COMMENT ON TABLE trusted_devices IS 'Device registry with trust scoring for fulfillment capability';
COMMENT ON TABLE capability_audit_events IS 'Audit trail for all capability-related events';

COMMENT ON COLUMN user_capabilities.review_state IS 'Values: none, pending, manual_review';
COMMENT ON COLUMN user_capabilities.blockers IS 'JSON map of capability -> blocker message';
COMMENT ON COLUMN capability_requests.metadata IS 'Context data: entryPoint, draftId, deviceFingerprint';
COMMENT ON COLUMN verification_tasks.payload IS 'Task-specific data (encrypted where sensitive)';
COMMENT ON COLUMN trusted_devices.telemetry IS 'Device telemetry (redacted before logging)';

