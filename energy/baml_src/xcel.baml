// SPDX-License-Identifier: AGPL-3.0-only
// Xcel energy sync — failure classes as a gate over the vendored lattice.
// Symbols are prefixed Xcel* because all baml_src files compile into one package.
//
// Pure functions: no model, no provider, no network, no filesystem, no keychain.
// The credential cannot reach this file: BAML has no FFI, so the isolation is
// structural rather than a policy that a future edit could weaken.

enum XcelStage {
  CREDENTIAL
  IDP
  OIDC
  SALESFORCE
  USAGE
  STORE
}

enum XcelFailureClass {
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

enum XcelRetry {
  NEVER
  ONCE
  DEFER
  BACKOFF
  NEXT_RUN
}

class XcelRemedy {
  retry XcelRetry
  human bool
  refuses string[]
}

// XcelEvidence is what an integration observes. Every field is optional so a stage
// fills only what it can actually see. No field may ever hold a secret.
class XcelEvidence {
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
function XcelClassifyIdp(e: XcelEvidence) -> XcelFailureClass {
  let status = e.http_status ?? 0;
  let code = e.provider_error_code ?? 0;
  if (e.otp_required ?? false) {
    XcelFailureClass.IDP_OTP_REQUIRED
  } else if (e.account_locked ?? false) {
    XcelFailureClass.IDP_ACCOUNT_LOCKED
  } else if (code == 403042) {
    XcelFailureClass.IDP_BAD_CREDENTIAL
  } else if (status == 429) {
    XcelFailureClass.IDP_RATE_LIMITED
  } else if (status >= 500) {
    XcelFailureClass.IDP_UNAVAILABLE
  } else {
    XcelFailureClass.IDP_BAD_CREDENTIAL
  }
}

function XcelClassifyOidc(e: XcelEvidence) -> XcelFailureClass {
  if (!(e.carried_code ?? false)) {
    XcelFailureClass.OIDC_NO_SESSION
  } else if (!(e.state_ok ?? true)) {
    XcelFailureClass.OIDC_STATE_MISMATCH
  } else if (e.verifier_rejected ?? false) {
    XcelFailureClass.OIDC_PKCE_MISMATCH
  } else {
    XcelFailureClass.OIDC_CODE_REJECTED
  }
}

function XcelClassifySalesforce(e: XcelEvidence) -> XcelFailureClass {
  let status = e.http_status ?? 0;
  if (status == 302 && !(e.has_session_token ?? false)) {
    XcelFailureClass.SALESFORCE_NO_SESSION_TOKEN
  } else {
    XcelFailureClass.SALESFORCE_CALLBACK_ERROR
  }
}

function XcelClassifyUsage(e: XcelEvidence) -> XcelFailureClass {
  let status = e.http_status ?? 0;
  if (e.body_is_html ?? false) {
    XcelFailureClass.USAGE_SESSION_EXPIRED
  } else if (status != 200 && status != 0) {
    XcelFailureClass.USAGE_MALFORMED_PAYLOAD
  } else {
    XcelFailureClass.USAGE_EMPTY_WINDOW
  }
}

function XcelClassifyStore(e: XcelEvidence) -> XcelFailureClass {
  if (e.schema_newer ?? false) {
    XcelFailureClass.STORE_SCHEMA_DRIFT
  } else if (e.lock_exhausted ?? false) {
    XcelFailureClass.STORE_LOCKED
  } else {
    XcelFailureClass.STORE_WRITE_FAILED
  }
}

function XcelClassify(s: XcelStage, e: XcelEvidence) -> XcelFailureClass {
  match (s) {
    XcelStage.IDP => XcelClassifyIdp(e)
    XcelStage.OIDC => XcelClassifyOidc(e)
    XcelStage.SALESFORCE => XcelClassifySalesforce(e)
    XcelStage.USAGE => XcelClassifyUsage(e)
    XcelStage.STORE => XcelClassifyStore(e)
    _ => XcelFailureClass.CREDENTIAL_MISSING
  }
}

function XcelRemedyFor(c: XcelFailureClass) -> XcelRemedy {
  match (c) {
    XcelFailureClass.CREDENTIAL_MISSING => XcelRemedy { retry: XcelRetry.NEVER, human: true, refuses: ["xcel/idp-gigya"] }
    XcelFailureClass.CREDENTIAL_DENIED => XcelRemedy { retry: XcelRetry.NEVER, human: true, refuses: ["xcel/idp-gigya"] }
    XcelFailureClass.CREDENTIAL_ACL_DRIFT => XcelRemedy { retry: XcelRetry.NEVER, human: true, refuses: ["xcel/idp-gigya"] }
    XcelFailureClass.IDP_BAD_CREDENTIAL => XcelRemedy { retry: XcelRetry.NEVER, human: true, refuses: ["xcel/oidc-handoff"] }
    XcelFailureClass.IDP_OTP_REQUIRED => XcelRemedy { retry: XcelRetry.NEVER, human: true, refuses: ["xcel/oidc-handoff"] }
    XcelFailureClass.IDP_ACCOUNT_LOCKED => XcelRemedy { retry: XcelRetry.NEVER, human: true, refuses: ["xcel/oidc-handoff"] }
    XcelFailureClass.IDP_RATE_LIMITED => XcelRemedy { retry: XcelRetry.DEFER, human: false, refuses: ["xcel/oidc-handoff"] }
    XcelFailureClass.IDP_UNAVAILABLE => XcelRemedy { retry: XcelRetry.DEFER, human: false, refuses: ["xcel/oidc-handoff"] }
    XcelFailureClass.OIDC_NO_SESSION => XcelRemedy { retry: XcelRetry.NEVER, human: true, refuses: ["xcel/salesforce"] }
    XcelFailureClass.OIDC_CODE_REJECTED => XcelRemedy { retry: XcelRetry.ONCE, human: false, refuses: ["xcel/salesforce"] }
    XcelFailureClass.OIDC_PKCE_MISMATCH => XcelRemedy { retry: XcelRetry.NEVER, human: false, refuses: ["xcel/salesforce"] }
    XcelFailureClass.OIDC_STATE_MISMATCH => XcelRemedy { retry: XcelRetry.NEVER, human: false, refuses: ["xcel/salesforce"] }
    XcelFailureClass.SALESFORCE_CALLBACK_ERROR => XcelRemedy { retry: XcelRetry.ONCE, human: false, refuses: ["xcel/usage"] }
    XcelFailureClass.SALESFORCE_NO_SESSION_TOKEN => XcelRemedy { retry: XcelRetry.ONCE, human: false, refuses: ["xcel/usage"] }
    XcelFailureClass.USAGE_SESSION_EXPIRED => XcelRemedy { retry: XcelRetry.NEVER, human: true, refuses: [] }
    XcelFailureClass.USAGE_MALFORMED_PAYLOAD => XcelRemedy { retry: XcelRetry.ONCE, human: false, refuses: [] }
    XcelFailureClass.USAGE_EMPTY_WINDOW => XcelRemedy { retry: XcelRetry.NEVER, human: false, refuses: [] }
    XcelFailureClass.USAGE_ODR_UNAVAILABLE => XcelRemedy { retry: XcelRetry.NEXT_RUN, human: false, refuses: [] }
    XcelFailureClass.STORE_SCHEMA_DRIFT => XcelRemedy { retry: XcelRetry.NEVER, human: true, refuses: [] }
    XcelFailureClass.STORE_LOCKED => XcelRemedy { retry: XcelRetry.BACKOFF, human: false, refuses: [] }
    XcelFailureClass.STORE_WRITE_FAILED => XcelRemedy { retry: XcelRetry.ONCE, human: false, refuses: [] }
  }
}

// A failure class becomes a 42i deviation. Transport failures are degradation;
// a dead session is an outage; anything else is a regression.
function XcelDeviationsFor(c: XcelFailureClass) -> Deviations {
  match (c) {
    XcelFailureClass.IDP_RATE_LIMITED => Deviations { called_during_degraded: 1 }
    XcelFailureClass.IDP_UNAVAILABLE => Deviations { called_during_unhealthy: 1 }
    XcelFailureClass.USAGE_SESSION_EXPIRED => Deviations { called_during_outage: 1 }
    XcelFailureClass.USAGE_ODR_UNAVAILABLE => Deviations { called_during_degraded: 1 }
    _ => Deviations { called_during_regression: 1 }
  }
}

class XcelSyncDecision {
  failure_class XcelFailureClass
  retry XcelRetry
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
function XcelEvaluate(c: XcelFailureClass) -> XcelSyncDecision {
  let r = XcelRemedyFor(c);
  let d = XcelDeviationsFor(c);
  let p = PositionOf(d);
  let gate = Decide(d, Policy { refuse_above: 0 });
  XcelSyncDecision {
    failure_class: c,
    retry: r.retry,
    human: r.human,
    refuses: r.refuses,
    distance: p.distance,
    rung: p.rung,
    rung_name: p.name,
    page: r.human && (r.retry == XcelRetry.NEVER),
    allowed: gate.allow
  }
}

test "an OTP challenge pages and refuses the next boundary" {
  let d = XcelEvaluate(XcelFailureClass.IDP_OTP_REQUIRED);
  assert.equal(d.page, true)
  assert.equal(d.rung, 2)
}

test "a rate limit does not page" {
  assert.equal(XcelEvaluate(XcelFailureClass.IDP_RATE_LIMITED).page, false)
}

test "an empty window is a success and does not page" {
  assert.equal(XcelEvaluate(XcelFailureClass.USAGE_EMPTY_WINDOW).page, false)
}

test "the verified bad-credential code is classified" {
  assert.equal(XcelClassify(XcelStage.IDP, XcelEvidence { provider_error_code: 403042 }), XcelFailureClass.IDP_BAD_CREDENTIAL)
}

test "an HTML body at the usage stage is an expired session" {
  assert.equal(XcelClassify(XcelStage.USAGE, XcelEvidence { http_status: 200, body_is_html: true }), XcelFailureClass.USAGE_SESSION_EXPIRED)
}

test "a callback without a session token is not success" {
  assert.equal(XcelClassify(XcelStage.SALESFORCE, XcelEvidence { http_status: 302, has_session_token: false }), XcelFailureClass.SALESFORCE_NO_SESSION_TOKEN)
}
