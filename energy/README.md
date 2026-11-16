# energy — Xcel sync as a gated isotope set

The Xcel utility sync expressed twice: as **pure BAML** (the gate) and as
**Gherkin** (the executable sheet). The two are deliberately separate artifacts.

- The BAML decides *whether* to cross a boundary and *what to call the failure*.
- The Gherkin decides *what must be true* and is the live evidence.

## Layout

```
energy/
  baml.toml
  LATTICE_VENDORED          # pin: commit + sha256 per vendored file
  baml_src/
    lattice.baml            # vendored — 42i weights, rungs, distance, position
    policy.baml             # vendored — Decide(Deviations, Policy)
    energy.baml             # ours — Stage, FailureClass, Remedy, Classify, Evaluate
  isotopes/
    xcel-sync.isotopes.json # 6 isotopes, 21 failure classes
  features/
    credential.feature      # keychain
    idp-gigya.feature       # accounts.login
    oidc-handoff.feature    # PKCE authorize/token
    salesforce.feature      # session establishment
    usage.feature           # myenergy data
    store.feature           # SQLite
```

## Why the secret cannot leak into the BAML

`lattice.baml` and `policy.baml` are pure functions: no model, no provider, no
network. BAML has no FFI, so a vendored lattice cannot read the keychain even if
a future edit wanted it to. The isolation is **structural**, not a policy that
can be weakened. The credential lives in one process (the signed `adhd` host) and
never crosses into this directory.

## Vendoring

`baml_src/lattice.baml` and `baml_src/policy.baml` are copies, not dependencies —
BAML has no package imports yet. `LATTICE_VENDORED` pins the source commit and a
sha256 per file; `verify.sh` in the source repo fails if a copy drifts.

Verified 2026-11-16: both files are byte-identical to
`isotope-baml@6503786`.

Licence: **AGPL-3.0-only**, carried by the SPDX header in each file. This matches
the rest of the lab and is the intended arrangement for a vendored lattice.

## The six isotopes

| Isotope | Boundary | Reaches network | Fails closed |
|---|---|---|---|
| `xcel/credential` | keychain | no | yes — refuses everything after |
| `xcel/idp-gigya` | `accounts.us1.gigya.com` | yes | yes |
| `xcel/oidc-handoff` | `apim.xcelenergy.com/v3/idp` | yes | yes |
| `xcel/salesforce` | `my.xcelenergy.com/MyAccount` | yes | yes |
| `xcel/usage` | `myenergy.xcelenergy.com` | yes | no — data only |
| `xcel/store` | local SQLite | no | no — never blocks a retry |

Each failure class carries `retry`, `human`, and `refuses`. **Only
`retry: NEVER` plus `human: true` pages.** That distinction is the whole point:
the original job failed 65 times because every cause collapsed into one
"auth failed" alarm.

`Evaluate(class)` returns the whole decision in one call:

```baml
Evaluate(FailureClass.IDP_OTP_REQUIRED)
# failure_class, retry, human, refuses, distance, rung, rung_name, page, allowed
```

## What is verified, and what is not

| Claim | Status |
|---|---|
| Gigya `accounts.login` reachable, `403042` = bad credential | verified live |
| Token endpoint `400` on an invalid code | verified live |
| OIDC/PKCE redirect chain | verified live |
| Screen set fields `loginID`, `password`, `code` | verified from `accounts.getScreenSets` |
| OTP codes other than `403042` | **not** verified — set as booleans, never invented |
| REST session recognized by the OIDC OP | **open question** (`oidc/no-session`) |
| BAML type-checks and tests pass | **not run** — no toolchain installed |

## Running the checks

```sh
baml check --agent-skill-check off
baml test  --agent-skill-check off
```

Neither has been run here: `baml` is a 0.2.5 wrapper reporting
`baml toolchain not installed (canary)`. The files are written to the source
repo's conventions but are **unverified until those two commands pass**.

## Adding a failure class

1. Add it to `FailureClass` and to `RemedyFor` in `baml_src/energy.baml`.
2. Add it to `failure_classes` in `isotopes/xcel-sync.isotopes.json`.
3. Add a `Scenario` to that isotope's feature that asserts the class name.
4. Do not invent a provider error code. Pin it from a live response and record
   the date. Only `403042` is verified today.
