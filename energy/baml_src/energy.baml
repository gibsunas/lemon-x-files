// SPDX-License-Identifier: AGPL-3.0-only
// Xcel energy sync — failure classes as a gate over the vendored lattice.
//
// Pure functions: no model, no provider, no network, no filesystem, no keychain.
// The credential cannot reach this file: BAML has no FFI, so the isolation is
// structural rather than a policy that a future edit could weaken.

enum Stage {
  CREDENTIAL
  IDP
  OIDC
  SALESFORCE
  USAGE
  STORE
}

enum FailureClass {
  CREDENTIAL_MISSING
  CREDENTIAL_DENIED
  CREDENTIAL_ACL_DRIFT
  IDP_BAD_CREDENTIAL
  IDP_OTP_REQUIRED
  IDP_ACCOUNT_LOCKED
  IDP_RATE_LIMITED
  IDP_UNAVAILABLE
  OIDC_NO_SESSION
  OIDC_CODE_REJECTED
  OIDC_PKCE_MISMATCH
  OIDC_STATE_MISMATCH
  SALESFORCE_CALLBACK_ERROR
  SALESFORCE_NO_SESSION_TOKEN
  USAGE_SESSION_EXPIRED
  USAGE_MALFORMED_PAYLOAD
  USAGE_EMPTY_WINDOW
  USAGE_ODR_UNAVAILABLE
  STORE_SCHEMA_DRIFT
  STORE_LOCKED
  STORE_WRITE_FAILED
}

enum Retry {
  NEVER
  ONCE
  DEFER
  BACKOFF
  NEXT_RUN
}

class Remedy {
  retry Retry
  human bool
  refuses string[]
}

// Evidence is what an integration observes. Every field is optional so a stage
// fills only what it can actually see. No field may ever hold a secret.
class Evidence {
  http_status int?
  provider_error_code int?
  otp_required bool?
  account_locked bool?
  carried_code bool?
  state_ok bool?
  verifier_rejected bool?
  has_session_token bool?
  body_is_html bool?
  reading_count int?
  schema_newer bool?
  lock_exhausted bool?
}

// Only 403042 is verified against the live API. Every other signal arrives as a
// boolean the integration sets from the response body, so no provider code is
// invented here. Pin a code from a live response before adding it.
function ClassifyIdp(e: Evidence) -> FailureClass {
  let status = e.http_status ?? 0;
  let code = e.provider_error_code ?? 0;
  if (e.otp_required ?? false) {
    FailureClass.IDP_OTP_REQUIRED
  } else if (e.account_locked ?? false) {
    FailureClass.IDP_ACCOUNT_LOCKED
  } else if (code == 403042) {
    FailureClass.IDP_BAD_CREDENTIAL
  } else if (status == 429) {
    FailureClass.IDP_RATE_LIMITED
  } else if (status >= 500) {
    FailureClass.IDP_UNAVAILABLE
  } else {
    FailureClass.IDP_BAD_CREDENTIAL
  }
}

function ClassifyOidc(e: Evidence) -> FailureClass {
  if (!(e.carried_code ?? false)) {
    FailureClass.OIDC_NO_SESSION
  } else if (!(e.state_ok ?? true)) {
    FailureClass.OIDC_STATE_MISMATCH
  } else if (e.verifier_rejected ?? false) {
    FailureClass.OIDC_PKCE_MISMATCH
  } else {
    FailureClass.OIDC_CODE_REJECTED
  }
}

function ClassifySalesforce(e: Evidence) -> FailureClass {
  let status = e.http_status ?? 0;
  if (status == 302 && !(e.has_session_token ?? false)) {
    FailureClass.SALESFORCE_NO_SESSION_TOKEN
  } else {
    FailureClass.SALESFORCE_CALLBACK_ERROR
  }
}

function ClassifyUsage(e: Evidence) -> FailureClass {
  let status = e.http_status ?? 0;
  if (e.body_is_html ?? false) {
    FailureClass.USAGE_SESSION_EXPIRED
  } else if (status != 200 && status != 0) {
    FailureClass.USAGE_MALFORMED_PAYLOAD
  } else {
    FailureClass.USAGE_EMPTY_WINDOW
  }
}

function ClassifyStore(e: Evidence) -> FailureClass {
  if (e.schema_newer ?? false) {
    FailureClass.STORE_SCHEMA_DRIFT
  } else if (e.lock_exhausted ?? false) {
    FailureClass.STORE_LOCKED
  } else {
    FailureClass.STORE_WRITE_FAILED
  }
}

function Classify(s: Stage, e: Evidence) -> FailureClass {
  match (s) {
    Stage.IDP => ClassifyIdp(e)
    Stage.OIDC => ClassifyOidc(e)
    Stage.SALESFORCE => ClassifySalesforce(e)
    Stage.USAGE => ClassifyUsage(e)
    Stage.STORE => ClassifyStore(e)
    _ => FailureClass.CREDENTIAL_MISSING
  }
}

function RemedyFor(c: FailureClass) -> Remedy {
  match (c) {
    FailureClass.CREDENTIAL_MISSING => Remedy { retry: Retry.NEVER, human: true, refuses: ["xcel/idp-gigya"] }
    FailureClass.CREDENTIAL_DENIED => Remedy { retry: Retry.NEVER, human: true, refuses: ["xcel/idp-gigya"] }
    FailureClass.CREDENTIAL_ACL_DRIFT => Remedy { retry: Retry.NEVER, human: true, refuses: ["xcel/idp-gigya"] }
    FailureClass.IDP_BAD_CREDENTIAL => Remedy { retry: Retry.NEVER, human: true, refuses: ["xcel/oidc-handoff"] }
    FailureClass.IDP_OTP_REQUIRED => Remedy { retry: Retry.NEVER, human: true, refuses: ["xcel/oidc-handoff"] }
    FailureClass.IDP_ACCOUNT_LOCKED => Remedy { retry: Retry.NEVER, human: true, refuses: ["xcel/oidc-handoff"] }
    FailureClass.IDP_RATE_LIMITED => Remedy { retry: Retry.DEFER, human: false, refuses: ["xcel/oidc-handoff"] }
    FailureClass.IDP_UNAVAILABLE => Remedy { retry: Retry.DEFER, human: false, refuses: ["xcel/oidc-handoff"] }
    FailureClass.OIDC_NO_SESSION => Remedy { retry: Retry.NEVER, human: true, refuses: ["xcel/salesforce"] }
    FailureClass.OIDC_CODE_REJECTED => Remedy { retry: Retry.ONCE, human: false, refuses: ["xcel/salesforce"] }
    FailureClass.OIDC_PKCE_MISMATCH => Remedy { retry: Retry.NEVER, human: false, refuses: ["xcel/salesforce"] }
    FailureClass.OIDC_STATE_MISMATCH => Remedy { retry: Retry.NEVER, human: false, refuses: ["xcel/salesforce"] }
    FailureClass.SALESFORCE_CALLBACK_ERROR => Remedy { retry: Retry.ONCE, human: false, refuses: ["xcel/usage"] }
    FailureClass.SALESFORCE_NO_SESSION_TOKEN => Remedy { retry: Retry.ONCE, human: false, refuses: ["xcel/usage"] }
    FailureClass.USAGE_SESSION_EXPIRED => Remedy { retry: Retry.NEVER, human: true, refuses: [] }
    FailureClass.USAGE_MALFORMED_PAYLOAD => Remedy { retry: Retry.ONCE, human: false, refuses: [] }
    FailureClass.USAGE_EMPTY_WINDOW => Remedy { retry: Retry.NEVER, human: false, refuses: [] }
    FailureClass.USAGE_ODR_UNAVAILABLE => Remedy { retry: Retry.NEXT_RUN, human: false, refuses: [] }
    FailureClass.STORE_SCHEMA_DRIFT => Remedy { retry: Retry.NEVER, human: true, refuses: [] }
    FailureClass.STORE_LOCKED => Remedy { retry: Retry.BACKOFF, human: false, refuses: [] }
    FailureClass.STORE_WRITE_FAILED => Remedy { retry: Retry.ONCE, human: false, refuses: [] }
  }
}

// A failure class becomes a 42i deviation. Transport failures are degradation;
// a dead session is an outage; anything else is a regression.
function DeviationsFor(c: FailureClass) -> Deviations {
  match (c) {
    FailureClass.IDP_RATE_LIMITED => Deviations { called_during_degraded: 1 }
    FailureClass.IDP_UNAVAILABLE => Deviations { called_during_unhealthy: 1 }
    FailureClass.USAGE_SESSION_EXPIRED => Deviations { called_during_outage: 1 }
    FailureClass.USAGE_ODR_UNAVAILABLE => Deviations { called_during_degraded: 1 }
    _ => Deviations { called_during_regression: 1 }
  }
}

class SyncDecision {
  failure_class FailureClass
  retry Retry
  human bool
  refuses string[]
  distance int
  rung int
  rung_name string
  page bool
  allowed bool
}

// The one function a host calls. `refuse_above: 0` means any deviation refuses
// the crossing; the lattice still reports the rung so the alarm can rank it.
function Evaluate(c: FailureClass) -> SyncDecision {
  let r = RemedyFor(c);
  let d = DeviationsFor(c);
  let p = PositionOf(d);
  let gate = Decide(d, Policy { refuse_above: 0 });
  SyncDecision {
    failure_class: c,
    retry: r.retry,
    human: r.human,
    refuses: r.refuses,
    distance: p.distance,
    rung: p.rung,
    rung_name: p.name,
    page: r.human && (r.retry == Retry.NEVER),
    allowed: gate.allow
  }
}

test "an OTP challenge pages and refuses the next boundary" {
  let d = Evaluate(FailureClass.IDP_OTP_REQUIRED);
  assert.equal(d.page, true)
  assert.equal(d.rung, 2)
}

test "a rate limit does not page" {
  assert.equal(Evaluate(FailureClass.IDP_RATE_LIMITED).page, false)
}

test "an empty window is a success and does not page" {
  assert.equal(Evaluate(FailureClass.USAGE_EMPTY_WINDOW).page, false)
}

test "the verified bad-credential code is classified" {
  assert.equal(Classify(Stage.IDP, Evidence { provider_error_code: 403042 }), FailureClass.IDP_BAD_CREDENTIAL)
}

test "an HTML body at the usage stage is an expired session" {
  assert.equal(Classify(Stage.USAGE, Evidence { http_status: 200, body_is_html: true }), FailureClass.USAGE_SESSION_EXPIRED)
}

test "a callback without a session token is not success" {
  assert.equal(Classify(Stage.SALESFORCE, Evidence { http_status: 302, has_session_token: false }), FailureClass.SALESFORCE_NO_SESSION_TOKEN)
}
