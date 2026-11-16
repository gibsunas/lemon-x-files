// SPDX-License-Identifier: AGPL-3.0-only
// SolarEdge sync — failure classes as a gate over the vendored lattice.
//
// Pure functions: no model, no provider, no network, no filesystem, no keychain.
// Symbols are prefixed SolarEdge* because every file in baml_src compiles into
// one package; xcel.baml uses the Xcel* prefix for the same reason.
//
// The failure classes below are grounded in solaredge_sync/: the AuthError
// messages in auth.py, the 401/403/429/400/404/422 handling in client.py, the
// MAX_WINDOW_DAYS table in api.py, and the token-rotation write-back.

enum SolarEdgeStage {
  SESSION
  COGNITO
  SITES
  WINDOW
  SERIES
  PANELS
  STORE
}

enum SolarEdgeFailureClass {
  SESSION_NO_TAB
  SESSION_NOT_SIGNED_IN
  SESSION_SAFARI_BLOCKED
  COGNITO_REFRESH_REJECTED
  COGNITO_UNREACHABLE
  COGNITO_MALFORMED
  COGNITO_ROTATION_UNPERSISTED
  SITES_UNAVAILABLE
  SITES_NONE_ACTIVE
  SITES_NOT_VISIBLE
  SITES_MALFORMED
  WINDOW_TOO_WIDE
  WINDOW_INVERTED
  SERIES_UNAUTHORIZED
  SERIES_RATE_LIMITED
  SERIES_REJECTED
  SERIES_NON_JSON
  SERIES_API_ERROR
  SERIES_EMPTY
  PANELS_NO_TOPOLOGY
  PANELS_INVERTER_CHANGED
  PANELS_NO_DATA
  STORE_SCHEMA_DRIFT
  STORE_LOCKED
  STORE_WRITE_FAILED
}

enum SolarEdgeRetry {
  NEVER
  ONCE
  DEFER
  BACKOFF
  NEXT_RUN
}

class SolarEdgeRemedy {
  retry SolarEdgeRetry
  human bool
  refuses string[]
}

// What a stage observes. Every field is optional; no field may hold a secret.
class SolarEdgeEvidence {
  http_status int?
  has_tab bool?
  has_refresh_token bool?
  safari_blocked bool?
  rotation_unpersisted bool?
  body_is_json bool?
  body_has_error bool?
  site_count int?
  site_ids_missing bool?
  window_days int?
  end_before_start bool?
  reading_count int?
  optimizer_count int?
  inverter_changed bool?
  schema_newer bool?
  lock_exhausted bool?
}

// The documented request limits, as a pinned policy rather than a comment.
// Mirrors MAX_WINDOW_DAYS in api.py.
function SolarEdgeMaxWindowDays(granularity: string) -> int {
  if (granularity == "15min") { 8 }
  else if (granularity == "hour") { 31 }
  else if (granularity == "day") { 90 }
  else { 1 }
}

function SolarEdgeWindowAllowed(days: int, granularity: string) -> bool {
  days <= SolarEdgeMaxWindowDays(granularity)
}

function SolarEdgeClassifySession(e: SolarEdgeEvidence) -> SolarEdgeFailureClass {
  if (e.safari_blocked ?? false) {
    SolarEdgeFailureClass.SESSION_SAFARI_BLOCKED
  } else if (!(e.has_tab ?? true)) {
    SolarEdgeFailureClass.SESSION_NO_TAB
  } else {
    SolarEdgeFailureClass.SESSION_NOT_SIGNED_IN
  }
}

function SolarEdgeClassifyCognito(e: SolarEdgeEvidence) -> SolarEdgeFailureClass {
  let status = e.http_status ?? 0;
  if (e.rotation_unpersisted ?? false) {
    SolarEdgeFailureClass.COGNITO_ROTATION_UNPERSISTED
  } else if (status >= 400) {
    SolarEdgeFailureClass.COGNITO_REFRESH_REJECTED
  } else if (!(e.body_is_json ?? true)) {
    SolarEdgeFailureClass.COGNITO_MALFORMED
  } else {
    SolarEdgeFailureClass.COGNITO_UNREACHABLE
  }
}

function SolarEdgeClassifySites(e: SolarEdgeEvidence) -> SolarEdgeFailureClass {
  if (e.site_ids_missing ?? false) {
    SolarEdgeFailureClass.SITES_NOT_VISIBLE
  } else if ((e.site_count ?? 0) == 0) {
    SolarEdgeFailureClass.SITES_NONE_ACTIVE
  } else if (!(e.body_is_json ?? true)) {
    SolarEdgeFailureClass.SITES_MALFORMED
  } else {
    SolarEdgeFailureClass.SITES_UNAVAILABLE
  }
}

function SolarEdgeClassifyWindow(e: SolarEdgeEvidence) -> SolarEdgeFailureClass {
  if (e.end_before_start ?? false) {
    SolarEdgeFailureClass.WINDOW_INVERTED
  } else {
    SolarEdgeFailureClass.WINDOW_TOO_WIDE
  }
}

function SolarEdgeClassifySeries(e: SolarEdgeEvidence) -> SolarEdgeFailureClass {
  let status = e.http_status ?? 0;
  if (status == 401 || status == 403) {
    SolarEdgeFailureClass.SERIES_UNAUTHORIZED
  } else if (status == 429) {
    SolarEdgeFailureClass.SERIES_RATE_LIMITED
  } else if (!(e.body_is_json ?? true)) {
    SolarEdgeFailureClass.SERIES_NON_JSON
  } else if (e.body_has_error ?? false) {
    SolarEdgeFailureClass.SERIES_API_ERROR
  } else if ((e.reading_count ?? 0) == 0) {
    SolarEdgeFailureClass.SERIES_EMPTY
  } else {
    SolarEdgeFailureClass.SERIES_REJECTED
  }
}

function SolarEdgeClassifyPanels(e: SolarEdgeEvidence) -> SolarEdgeFailureClass {
  if (e.inverter_changed ?? false) {
    SolarEdgeFailureClass.PANELS_INVERTER_CHANGED
  } else if ((e.optimizer_count ?? 0) == 0) {
    SolarEdgeFailureClass.PANELS_NO_TOPOLOGY
  } else {
    SolarEdgeFailureClass.PANELS_NO_DATA
  }
}

function SolarEdgeClassifyStore(e: SolarEdgeEvidence) -> SolarEdgeFailureClass {
  if (e.schema_newer ?? false) {
    SolarEdgeFailureClass.STORE_SCHEMA_DRIFT
  } else if (e.lock_exhausted ?? false) {
    SolarEdgeFailureClass.STORE_LOCKED
  } else {
    SolarEdgeFailureClass.STORE_WRITE_FAILED
  }
}

function SolarEdgeClassify(s: SolarEdgeStage, e: SolarEdgeEvidence) -> SolarEdgeFailureClass {
  match (s) {
    SolarEdgeStage.COGNITO => SolarEdgeClassifyCognito(e)
    SolarEdgeStage.SITES => SolarEdgeClassifySites(e)
    SolarEdgeStage.WINDOW => SolarEdgeClassifyWindow(e)
    SolarEdgeStage.SERIES => SolarEdgeClassifySeries(e)
    SolarEdgeStage.PANELS => SolarEdgeClassifyPanels(e)
    SolarEdgeStage.STORE => SolarEdgeClassifyStore(e)
    _ => SolarEdgeClassifySession(e)
  }
}

function SolarEdgeRemedyFor(c: SolarEdgeFailureClass) -> SolarEdgeRemedy {
  match (c) {
    SolarEdgeFailureClass.SESSION_NO_TAB => SolarEdgeRemedy { retry: SolarEdgeRetry.NEVER, human: true, refuses: ["solaredge/cognito"] }
    SolarEdgeFailureClass.SESSION_NOT_SIGNED_IN => SolarEdgeRemedy { retry: SolarEdgeRetry.NEVER, human: true, refuses: ["solaredge/cognito"] }
    SolarEdgeFailureClass.SESSION_SAFARI_BLOCKED => SolarEdgeRemedy { retry: SolarEdgeRetry.NEVER, human: true, refuses: ["solaredge/cognito"] }
    SolarEdgeFailureClass.COGNITO_REFRESH_REJECTED => SolarEdgeRemedy { retry: SolarEdgeRetry.NEVER, human: true, refuses: ["solaredge/sites", "solaredge/series"] }
    SolarEdgeFailureClass.COGNITO_UNREACHABLE => SolarEdgeRemedy { retry: SolarEdgeRetry.DEFER, human: false, refuses: ["solaredge/sites", "solaredge/series"] }
    SolarEdgeFailureClass.COGNITO_MALFORMED => SolarEdgeRemedy { retry: SolarEdgeRetry.ONCE, human: false, refuses: ["solaredge/sites", "solaredge/series"] }
    SolarEdgeFailureClass.COGNITO_ROTATION_UNPERSISTED => SolarEdgeRemedy { retry: SolarEdgeRetry.NEVER, human: true, refuses: [] }
    SolarEdgeFailureClass.SITES_UNAVAILABLE => SolarEdgeRemedy { retry: SolarEdgeRetry.ONCE, human: false, refuses: [] }
    SolarEdgeFailureClass.SITES_NONE_ACTIVE => SolarEdgeRemedy { retry: SolarEdgeRetry.NEVER, human: true, refuses: ["solaredge/series"] }
    SolarEdgeFailureClass.SITES_NOT_VISIBLE => SolarEdgeRemedy { retry: SolarEdgeRetry.NEVER, human: true, refuses: ["solaredge/series"] }
    SolarEdgeFailureClass.SITES_MALFORMED => SolarEdgeRemedy { retry: SolarEdgeRetry.ONCE, human: false, refuses: [] }
    SolarEdgeFailureClass.WINDOW_TOO_WIDE => SolarEdgeRemedy { retry: SolarEdgeRetry.NEVER, human: false, refuses: [] }
    SolarEdgeFailureClass.WINDOW_INVERTED => SolarEdgeRemedy { retry: SolarEdgeRetry.NEVER, human: false, refuses: [] }
    SolarEdgeFailureClass.SERIES_UNAUTHORIZED => SolarEdgeRemedy { retry: SolarEdgeRetry.NEVER, human: true, refuses: ["solaredge/panels"] }
    SolarEdgeFailureClass.SERIES_RATE_LIMITED => SolarEdgeRemedy { retry: SolarEdgeRetry.DEFER, human: false, refuses: [] }
    SolarEdgeFailureClass.SERIES_REJECTED => SolarEdgeRemedy { retry: SolarEdgeRetry.NEVER, human: false, refuses: [] }
    SolarEdgeFailureClass.SERIES_NON_JSON => SolarEdgeRemedy { retry: SolarEdgeRetry.ONCE, human: false, refuses: [] }
    SolarEdgeFailureClass.SERIES_API_ERROR => SolarEdgeRemedy { retry: SolarEdgeRetry.ONCE, human: false, refuses: [] }
    SolarEdgeFailureClass.SERIES_EMPTY => SolarEdgeRemedy { retry: SolarEdgeRetry.NEVER, human: false, refuses: [] }
    SolarEdgeFailureClass.PANELS_NO_TOPOLOGY => SolarEdgeRemedy { retry: SolarEdgeRetry.NEXT_RUN, human: false, refuses: [] }
    SolarEdgeFailureClass.PANELS_INVERTER_CHANGED => SolarEdgeRemedy { retry: SolarEdgeRetry.NEVER, human: true, refuses: [] }
    SolarEdgeFailureClass.PANELS_NO_DATA => SolarEdgeRemedy { retry: SolarEdgeRetry.NEXT_RUN, human: false, refuses: [] }
    SolarEdgeFailureClass.STORE_SCHEMA_DRIFT => SolarEdgeRemedy { retry: SolarEdgeRetry.NEVER, human: true, refuses: [] }
    SolarEdgeFailureClass.STORE_LOCKED => SolarEdgeRemedy { retry: SolarEdgeRetry.BACKOFF, human: false, refuses: [] }
    SolarEdgeFailureClass.STORE_WRITE_FAILED => SolarEdgeRemedy { retry: SolarEdgeRetry.ONCE, human: false, refuses: [] }
  }
}

function SolarEdgeDeviationsFor(c: SolarEdgeFailureClass) -> Deviations {
  match (c) {
    SolarEdgeFailureClass.SERIES_RATE_LIMITED => Deviations { called_during_degraded: 1 }
    SolarEdgeFailureClass.COGNITO_UNREACHABLE => Deviations { called_during_unhealthy: 1 }
    SolarEdgeFailureClass.SESSION_NOT_SIGNED_IN => Deviations { called_during_outage: 1 }
    SolarEdgeFailureClass.COGNITO_REFRESH_REJECTED => Deviations { called_during_outage: 1 }
    _ => Deviations { called_during_regression: 1 }
  }
}

class SolarEdgeSyncDecision {
  failure_class SolarEdgeFailureClass
  retry SolarEdgeRetry
  human bool
  refuses string[]
  distance int
  rung int
  rung_name string
  page bool
  allowed bool
}

function SolarEdgeEvaluate(c: SolarEdgeFailureClass) -> SolarEdgeSyncDecision {
  let r = SolarEdgeRemedyFor(c);
  let d = SolarEdgeDeviationsFor(c);
  let p = PositionOf(d);
  let gate = Decide(d, Policy { refuse_above: 0 });
  SolarEdgeSyncDecision {
    failure_class: c,
    retry: r.retry,
    human: r.human,
    refuses: r.refuses,
    distance: p.distance,
    rung: p.rung,
    rung_name: p.name,
    page: r.human && (r.retry == SolarEdgeRetry.NEVER),
    allowed: gate.allow
  }
}

test "a signed-out session pages and refuses the token exchange" {
  let d = SolarEdgeEvaluate(SolarEdgeFailureClass.SESSION_NOT_SIGNED_IN);
  assert.equal(d.page, true)
  assert.equal(d.rung, 1)
}

test "a rate limit does not page" {
  assert.equal(SolarEdgeEvaluate(SolarEdgeFailureClass.SERIES_RATE_LIMITED).page, false)
}

test "an empty series is a success and does not page" {
  assert.equal(SolarEdgeEvaluate(SolarEdgeFailureClass.SERIES_EMPTY).page, false)
}

test "the documented 15-minute window is 8 days" {
  assert.equal(SolarEdgeMaxWindowDays("15min"), 8)
  assert.equal(SolarEdgeWindowAllowed(8, "15min"), true)
  assert.equal(SolarEdgeWindowAllowed(9, "15min"), false)
}

test "an HTML body at the series stage is non-JSON, not empty" {
  assert.equal(SolarEdgeClassify(SolarEdgeStage.SERIES, SolarEdgeEvidence { body_is_json: false }), SolarEdgeFailureClass.SERIES_NON_JSON)
}

test "a rotated token that could not be persisted requires a human" {
  assert.equal(SolarEdgeEvaluate(SolarEdgeFailureClass.COGNITO_ROTATION_UNPERSISTED).page, true)
}
