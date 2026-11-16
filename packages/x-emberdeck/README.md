# x-emberdeck — the 42i lattice as a portable BAML package

Ported from the `alarm-gate-spike` prototype
(`james-gibson/alarm-gate-spike`, branch `spike/42i-alarm-gate`), where this
package was built to gate a laser job dispatcher on alarm state.

This section is the **BAML artifact**, not the harness. The dispatcher, wire
proxy, G-code gate and collector remain in the prototype.

## What is here

| Path | What it is |
| --- | --- |
| `lattice/` | vendored 42i lattice and `Decide`, pinned in `LATTICE_VENDORED` |
| `lattice_paths.py` | runs the packed binary and `baml run -e` over the same fixtures and compares canonical digests |
| `surface.py` | generates a typed BAML surface and a skill from a live MCP `tools/list` |
| `evidence/` | the lattice-related artifacts from the prototype's evidence set |

## Why the lattice is vendored here *and* in `x-energy`

BAML has no package imports, so every package needs its own copy of the lattice.
`x-emberdeck/lattice/` and `x-energy/baml_src/` are therefore byte-identical by
design, not by accident — both pin `isotope-baml@6503786`:

```
6645fa80…  lattice.baml
766fca75…  policy.baml
```

Do not "de-duplicate" these into one shared copy. A shared copy would require an
import mechanism BAML does not have; the pin is what keeps the duplication
honest.

## Running it

```sh
cd packages/x-emberdeck/lattice
baml check --agent-skill-check off
baml test  --agent-skill-check off
baml pack PositionOf --agent-skill-check off    # ~34 MB, build artefact, not committed

cd ..
./lattice_paths.py --bin lattice/forty-two-i --project lattice
```

`lattice_paths.py` refuses to run without the packed binary rather than silently
falling back to one path. That refusal is the point: a fallback that is never
compared is a second implementation wearing the first one's name.

## What each artifact proves — and what it does not

Copied from the prototype's `manifest.json`, which records an independence class
per claim. This is the part most easily over-read.

| Check | Claim | Independence |
| --- | --- | --- |
| `lattice-tests` | the vendored lattice's own tests pass offline | **self-check**: asserts literals against the same BAML source |
| `lattice-paths` | packed binary and `baml run` are rotations, not variants | **packaging check**: same source, two paths; rules out a stale or mispacked binary |
| `lattice-vs-reference` | the BAML reproduces the pinned Go reference | **transcription, not independence**: the BAML was ported from that Go module. Agreement rules out drift; the reference's own tests are the correctness evidence, and they are upstream |
| `rotation-gate` | a rotated binary needs a fixture attestation | **self-referential, BAML vs BAML**: proves the binary matches the toolchain, not that the lattice is right |

So: nothing here establishes that the weights or rung boundaries are correct.
That evidence lives upstream, in the `isotope` module's own suite at the pinned
version.

## Provenance

`evidence/manifest.json` describes the prototype's **full** evidence set. Only
the lattice-related artifacts are ported here; `byte-safety`, `wire-ownership`
and the dispatcher-observed runs stay with the harness. Read the manifest as the
prototype's index, filtered by what is present in this directory.

## As an installer target

`MANIFEST.json` is the grab recipe: the lattice entry point, the pin file, the two
tools, and the evidence root. It names roots rather than enumerating every file.
Replace it if the installer expects a different shape.

## Licence

AGPL-3.0-only, carried by the SPDX header in each vendored file.
