// SPDX-License-Identifier: AGPL-3.0-only
// CyberPower UPS collector — failure classes as a gate over the vendored lattice.
// Symbols are prefixed CyberPower* because every file in baml_src compiles into
// one package; xcel.baml and solaredge.baml use their own prefixes.
//
// Pure functions: no model, no provider, no network, no filesystem.
// The unit's address, the community string and the store path are evidence a
// host supplies; none of them are secrets this file may hold.
//
// The gate is per unit. A failure means "this poll is not a measurement", not
// "the collector stops" — the collector records the failed unit and reads the
// others. `allowed: false` is therefore the right answer for every class below,
// and `page` is what decides whether a human is woken.

enum CyberPowerStage {
  SNMP
  STORE
}

enum CyberPowerFailureClass {
  SNMP_UNREACHABLE
  SNMP_MALFORMED_RESPONSE
  SNMP_ERROR_STATUS
  SNMP_UNSUPPORTED
  STORE_SCHEMA_DRIFT
  STORE_MIGRATION_FAILED
  STORE_LOCKED
  STORE_WRITE_FAILED
}

enum CyberPowerRetry {
  NEVER
  ONCE
  DEFER
  BACKOFF
  NEXT_RUN
}

class CyberPowerRemedy {
  retry CyberPowerRetry
  human bool
  refuses string[]
}

// Every field is optional: a stage fills only what it can observe. The
// collector's own statuses map onto these:
//   runs.status = unreachable  -> reachable = false
//   runs.status = error        -> malformed = true, or error_status != 0
//   runs.status = ok           -> all false, and no class is asked for
class CyberPowerEvidence {
  reachable bool?
  malformed bool?
  error_status int?
  missing_required int?
  schema_newer bool?
  migration_failed bool?
  lock_exhausted bool?
  write_failed bool?
}

function CyberPowerClassifySnmp(e: CyberPowerEvidence) -> CyberPowerFailureClass {
  if (!(e.reachable ?? true)) {
    CyberPowerFailureClass.SNMP_UNREACHABLE
  } else if (e.malformed ?? false) {
    CyberPowerFailureClass.SNMP_MALFORMED_RESPONSE
  } else if ((e.error_status ?? 0) != 0) {
    CyberPowerFailureClass.SNMP_ERROR_STATUS
  } else {
    CyberPowerFailureClass.SNMP_UNSUPPORTED
  }
}

function CyberPowerClassifyStore(e: CyberPowerEvidence) -> CyberPowerFailureClass {
  if (e.schema_newer ?? false) {
    CyberPowerFailureClass.STORE_SCHEMA_DRIFT
  } else if (e.migration_failed ?? false) {
    CyberPowerFailureClass.STORE_MIGRATION_FAILED
  } else if (e.lock_exhausted ?? false) {
    CyberPowerFailureClass.STORE_LOCKED
  } else {
    CyberPowerFailureClass.STORE_WRITE_FAILED
  }
}

function CyberPowerClassify(s: CyberPowerStage, e: CyberPowerEvidence) -> CyberPowerFailureClass {
  match (s) {
    CyberPowerStage.SNMP => CyberPowerClassifySnmp(e)
    CyberPowerStage.STORE => CyberPowerClassifyStore(e)
  }
}

function CyberPowerRemedyFor(c: CyberPowerFailureClass) -> CyberPowerRemedy {
  match (c) {
    CyberPowerFailureClass.SNMP_UNREACHABLE => CyberPowerRemedy { retry: CyberPowerRetry.NEXT_RUN, human: false, refuses: [] }
    CyberPowerFailureClass.SNMP_MALFORMED_RESPONSE => CyberPowerRemedy { retry: CyberPowerRetry.ONCE, human: false, refuses: [] }
    CyberPowerFailureClass.SNMP_ERROR_STATUS => CyberPowerRemedy { retry: CyberPowerRetry.ONCE, human: false, refuses: [] }
    CyberPowerFailureClass.SNMP_UNSUPPORTED => CyberPowerRemedy { retry: CyberPowerRetry.NEVER, human: true, refuses: ["cyberpower/snmp"] }
    CyberPowerFailureClass.STORE_SCHEMA_DRIFT => CyberPowerRemedy { retry: CyberPowerRetry.NEVER, human: true, refuses: [] }
    CyberPowerFailureClass.STORE_MIGRATION_FAILED => CyberPowerRemedy { retry: CyberPowerRetry.NEVER, human: true, refuses: ["cyberpower/store"] }
    CyberPowerFailureClass.STORE_LOCKED => CyberPowerRemedy { retry: CyberPowerRetry.BACKOFF, human: false, refuses: [] }
    CyberPowerFailureClass.STORE_WRITE_FAILED => CyberPowerRemedy { retry: CyberPowerRetry.ONCE, human: false, refuses: [] }
  }
}

// An absent unit is degradation; a bad answer is unhealthy; a broken store is
// an outage. A card that is not the model the collector understands is a
// regression: the assumed interface is wrong, not just unavailable.
function CyberPowerDeviationsFor(c: CyberPowerFailureClass) -> Deviations {
  match (c) {
    CyberPowerFailureClass.SNMP_UNREACHABLE => Deviations { called_during_degraded: 1 }
    CyberPowerFailureClass.SNMP_MALFORMED_RESPONSE => Deviations { called_during_unhealthy: 1 }
    CyberPowerFailureClass.SNMP_ERROR_STATUS => Deviations { called_during_unhealthy: 1 }
    CyberPowerFailureClass.SNMP_UNSUPPORTED => Deviations { called_during_regression: 1 }
    CyberPowerFailureClass.STORE_LOCKED => Deviations { called_during_degraded: 1 }
    CyberPowerFailureClass.STORE_WRITE_FAILED => Deviations { called_during_outage: 1 }
    CyberPowerFailureClass.STORE_SCHEMA_DRIFT => Deviations { called_during_regression: 1 }
    CyberPowerFailureClass.STORE_MIGRATION_FAILED => Deviations { called_during_regression: 1 }
  }
}

class CyberPowerDecision {
  failure_class CyberPowerFailureClass
  retry CyberPowerRetry
  human bool
  refuses string[]
  distance int
  rung int
  rung_name string
  page bool
  allowed bool
}

// The one function a host calls. `refuse_above: 0` means a failed poll is never
// a measurement; the collector still records the run and reads the other units.
function CyberPowerEvaluate(c: CyberPowerFailureClass) -> CyberPowerDecision {
  let r = CyberPowerRemedyFor(c);
  let d = CyberPowerDeviationsFor(c);
  let p = PositionOf(d);
  let gate = Decide(d, Policy { refuse_above: 0 });
  CyberPowerDecision {
    failure_class: c,
    retry: r.retry,
    human: r.human,
    refuses: r.refuses,
    distance: p.distance,
    rung: p.rung,
    rung_name: p.name,
    page: r.human && (r.retry == CyberPowerRetry.NEVER),
    allowed: gate.allow
  }
}

test "an unreachable unit is recorded, not paged" {
  let d = CyberPowerEvaluate(CyberPowerFailureClass.SNMP_UNREACHABLE);
  assert.equal(d.page, false)
  assert.equal(d.allowed, false)
  assert.equal(d.retry, CyberPowerRetry.NEXT_RUN)
}

test "an unsupported card pages" {
  let d = CyberPowerEvaluate(CyberPowerFailureClass.SNMP_UNSUPPORTED);
  assert.equal(d.page, true)
  assert.equal(d.allowed, false)
}

test "a locked store backs off without paging" {
  let d = CyberPowerEvaluate(CyberPowerFailureClass.STORE_LOCKED);
  assert.equal(d.retry, CyberPowerRetry.BACKOFF)
  assert.equal(d.page, false)
}

test "a newer store schema is a human decision" {
  assert.equal(CyberPowerClassify(CyberPowerStage.STORE, CyberPowerEvidence { schema_newer: true }), CyberPowerFailureClass.STORE_SCHEMA_DRIFT)
}

test "a malformed response is not an absent unit" {
  assert.equal(
    CyberPowerClassify(CyberPowerStage.SNMP, CyberPowerEvidence { reachable: true, malformed: true }),
    CyberPowerFailureClass.SNMP_MALFORMED_RESPONSE
  )
}

test "a device error-status is health, not reachability" {
  assert.equal(
    CyberPowerClassify(CyberPowerStage.SNMP, CyberPowerEvidence { reachable: true, error_status: 5 }),
    CyberPowerFailureClass.SNMP_ERROR_STATUS
  )
}
