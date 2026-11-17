# x-energy — energy boundaries as gated isotope sets

Each boundary is expressed twice: as **pure BAML** (the gate) and as **Gherkin**
(the executable sheet). They are deliberately separate artifacts.

- The BAML decides *whether* to cross a boundary and *what to call the failure*.
- The Gherkin decides *what must be true*, and is the live evidence.

Three systems so far: `xcel`, `solaredge` and `cyberpower`. The layout is the
pattern; adding a fourth should not require changing the first three.

## Layout

```
packages/x-energy/
  baml.toml
  LATTICE_VENDORED            # pin: commit + sha256 per vendored file
  baml_src/
    lattice.baml              # vendored — 42i weights, rungs, distance, position
    policy.baml               # vendored — Decide(Deviations, Policy)
    xcel.baml                 # ours — Xcel* symbols
    solaredge.baml            # ours — SolarEdge* symbols
    cyberpower.baml           # ours — CyberPower* symbols
  xcel/
    isotopes/xcel-sync.isotopes.json
    features/{credential,idp-gigya,oidc-handoff,salesforce,usage,store}.feature
  solaredge/
    isotopes/solaredge-sync.isotopes.json
    features/{session,cognito,sites,window,series,panels,store}.feature
  cyberpower/
    isotopes/cyberpower-ups.isotopes.json
    features/{snmp,store}.feature
```

## Symbol prefixes are mandatory

Every file in `baml_src/` compiles into **one package**, so two systems cannot
both declare `enum Stage`. Each system prefixes every symbol it introduces:

```baml
enum XcelStage { ... }        function XcelClassify(...)      -> XcelFailureClass
enum SolarEdgeStage { ... }   function SolarEdgeClassify(...) -> SolarEdgeFailureClass
enum CyberPowerStage { ... }  function CyberPowerClassify(...) -> CyberPowerFailureClass
```

Only the vendored `lattice.baml` / `policy.baml` symbols are unprefixed
(`Deviations`, `Policy`, `Decide`, `PositionOf`, `Distance`). Those are shared
and must not be redefined.

## Why the secret cannot leak into the BAML

`lattice.baml` and `policy.baml` are pure functions: no model, no provider, no
network. BAML has no FFI, so a vendored lattice cannot read a keychain or Safari
localStorage even if a future edit wanted it to. The isolation is **structural**,
not a policy that can be weakened.

Credentials stay in one process — the signed `adhd` host, or Safari for
SolarEdge's refresh token — and never cross into this directory.

## Vendoring

`baml_src/lattice.baml` and `baml_src/policy.baml` are copies, not dependencies —
BAML has no package imports yet. `LATTICE_VENDORED` pins the source commit and a
sha256 per file; `scripts/verify.sh` in the source repo fails if a copy drifts.

Verified 2026-11-16: both files are byte-identical to `isotope-baml@6503786`.

Licence: **AGPL-3.0-only**, carried by the SPDX header in each file.

## The isotopes

### xcel — 6 isotopes, 21 failure classes

| Isotope | Boundary | Fails closed |
|---|---|---|
| `xcel/credential` | keychain | yes |
| `xcel/idp-gigya` | `accounts.us1.gigya.com` | yes |
| `xcel/oidc-handoff` | `apim.xcelenergy.com/v3/idp` | yes |
| `xcel/salesforce` | `my.xcelenergy.com/MyAccount` | yes |
| `xcel/usage` | `myenergy.xcelenergy.com` | no |
| `xcel/store` | local SQLite | no |

### solaredge — 7 isotopes, 25 failure classes

| Isotope | Boundary | Fails closed |
|---|---|---|
| `solaredge/session` | Safari localStorage | yes |
| `solaredge/cognito` | Cognito token endpoint | yes |
| `solaredge/sites` | `/services/sitelist` | no — `--site-id` continues |
| `solaredge/window` | local arithmetic | no |
| `solaredge/series` | `/services/dashboard` | no |
| `solaredge/panels` | `/services/layout` | no |
| `solaredge/store` | local SQLite | no |

### cyberpower — 2 isotopes, 8 failure classes

| Isotope | Boundary | Fails closed |
|---|---|---|
| `cyberpower/snmp` | UDP 161, the card's CPS-MIB group | yes — no samples on a failed poll |
| `cyberpower/store` | local SQLite | yes — refuses a newer schema |

The CyberPower unit is a CPS `OR1500LCDRT2U` with an `RMCARD205` network card;
it answers SNMP v1 read and is **not** a USB HID unit, so `nutdrv_qx` is not the
driver. The collector keys the store by **unit label**, not by address: a unit
that does not answer is a recorded `unreachable` run, a unit that answers badly
is `error`, and only an unsupported card pages. The card's Event Log and Status
Records — the only place a finished low-voltage event is timestamped — are not
named yet; they need a session isotope once the administrator login exists.

## Only one combination pages

Each class carries `retry`, `human`, and `refuses`:

```json
"idp/otp-required":   { "retry": "never", "human": true,  "refuses": ["xcel/oidc-handoff"] }
"idp/rate-limited":   { "retry": "defer", "human": false, "refuses": ["xcel/oidc-handoff"] }
"usage/empty-window": { "retry": "never", "human": false, "refuses": [] }
```

**`retry: never` plus `human: true` is the only combination that pages.** A
deferred transport failure is recorded but should not wake anyone until it
recurs past a threshold. `refuses` stops one cause producing four alarms.

`Evaluate(class)` returns the whole decision in one call:

```baml
XcelEvaluate(XcelFailureClass.IDP_OTP_REQUIRED)
SolarEdgeEvaluate(SolarEdgeFailureClass.SESSION_NOT_SIGNED_IN)
CyberPowerEvaluate(CyberPowerFailureClass.SNMP_UNREACHABLE)
# failure_class, retry, human, refuses, distance, rung, rung_name, page, allowed
```

## What is verified, and what is not

| Claim | Status |
|---|---|
| Xcel: `accounts.login` reachable, `403042` = bad credential | verified live |
| Xcel: token endpoint `400` on an invalid code | verified live |
| Xcel: OIDC/PKCE redirect chain, screen-set field names | verified live |
| Xcel: OTP codes other than `403042` | **not** verified — set as booleans |
| Xcel: REST session recognized by the OIDC OP | **open question** |
| SolarEdge: limits 8/31/90 days per granularity | verified in `api.py` |
| SolarEdge: 401/403 retry-once, 429 Retry-After, 400/404/422 `ApiError` | verified in `client.py` |
| SolarEdge: token rotation write-back hazard | verified in `auth.py` |
| SolarEdge: provider error payload shapes | **not** verified — set as booleans |
| CyberPower: `OR1500LCDRT2U` + `RMCARD205` read over SNMP v1 | verified live 2026-11-16 |
| CyberPower: input line, AVR/transfer state, battery group | verified live |
| CyberPower: a second unit configured and possibly unreachable | modelled; second unit not on the wire |
| CyberPower: Event Log / Status Records time-anchoring a past event | **not implemented** — admin login |
| BAML type-checks | verified 2026-11-16 — `baml check`, 5 files |
| BAML tests | 22 pass, 1 pre-existing xcel failure; cyberpower 6/6 |

## Running the checks

```sh
baml check --agent-skill-check off
baml test  --agent-skill-check off
```

Run from this directory on 2026-11-16: `check` finished over 5 files; `test`
returned 22 passed and 1 failed. The failure is the xcel test
`an OTP challenge pages and refuses the next boundary` (expects rung 2, gets 1),
which predates the cyberpower system and is filed separately. The six
cyberpower tests pass.

## As an installer target

`MANIFEST.json` is the grab recipe: the BAML entry point, the pin file, and the
isotope and feature roots. It names roots rather than enumerating every file, so
it cannot drift as scenarios are added. Replace it if the installer expects a
different shape — it is a convenience, not a contract.

## Adding a system

1. `mkdir -p <system>/{isotopes,features}` and add `baml_src/<system>.baml`.
2. Prefix every symbol in it with the system name.
3. Add `<system>/isotopes/<system>-sync.isotopes.json` with the same schema.
4. One feature per isotope; every scenario asserts a class name.
5. Do not invent a provider error code. Pin it from a live response and record
   the date. Only `403042` is verified today.
6. Update the two tables above.
