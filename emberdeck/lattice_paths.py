#!/usr/bin/env python3
"""Two BAML execution paths must rotate without changing an answer.

A packed binary is fast; `baml run -e` is slow but needs no build step. If one
is a fallback for the other, they have to be interchangeable — the same input
must produce the same position, and the same canonical digest of it. Anything
less is a second implementation wearing the first one's name.

Every turn carries a digest:
    input  -> sha256(canonical arguments)
    output -> sha256(canonical position)

    python3 lattice_paths.py --bin ../lattice/forty-two-i --project ../lattice
"""
import argparse
import hashlib
import json
import os
import re
import subprocess
import sys

FIXTURES = [
    {},
    {"called_during_degraded": 1},
    {"called_during_degraded": 2},
    {"called_during_degraded": 3},
    {"called_during_degraded": 2, "called_during_regression": 1},
]

FIELD = re.compile(r'(\w+):\s*("([^"]*)"|[-\d.]+)')


def digest(obj):
    return hashlib.sha256(
        json.dumps(obj, sort_keys=True, separators=(",", ":")).encode()).hexdigest()


def packed(binary, deviations):
    """Fast path: one process, JSON in, JSON out."""
    payload = {"d": deviations}
    out = subprocess.run([binary, "--json-args", "-"],
                         input=json.dumps(payload), capture_output=True, text=True,
                         timeout=30)
    if out.returncode != 0:
        return None, out.stderr.strip()[:120] or "packed failed"
    try:
        return json.loads(out.stdout.strip().splitlines()[-1]), None
    except (ValueError, IndexError) as exc:
        return None, f"packed output: {exc}"


def exec_path(project, deviations):
    """Slow path: the toolchain evaluates the expression in the project."""
    fields = ", ".join(f"{k}: {v}" for k, v in sorted(deviations.items()))
    expr = f"PositionOf(Deviations {{ {fields} }})" if fields else "PositionOf(Deviations {})"
    out = subprocess.run(["baml", "run", "-e", expr, "--agent-skill-check", "off"],
                         cwd=project, capture_output=True, text=True, timeout=180)
    text = (out.stdout or "").strip().splitlines()
    if not text:
        return None, (out.stderr or "").strip().splitlines()[-1:] or ["exec failed"]
    # baml prints `user.Position {distance: 40, rung: 2, name: "Harness Tools", ...}`
    parsed = {}
    for key, raw, quoted in [(m[0], m[1], m[2]) for m in FIELD.findall(text[-1])]:
        parsed[key] = quoted if quoted else raw
    if "distance" not in parsed:
        return None, f"unparsed exec output: {text[-1][:80]}"
    return {
        "distance": int(float(parsed["distance"])),
        "rung": int(float(parsed["rung"])),
        "name": parsed.get("name", ""),
    }, None


def canonical(position):
    return {"distance": position["distance"], "rung": position["rung"],
            "name": position["name"]}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--bin", default=os.path.join("..", "lattice", "forty-two-i"))
    ap.add_argument("--project", default=os.path.join("..", "lattice"))
    ap.add_argument("--json", action="store_true",
                    help="emit a machine-readable attestation instead of a table")
    args = ap.parse_args()

    if not os.path.exists(args.bin):
        sys.exit(f"missing packed binary {args.bin}: run `baml pack PositionOf` in "
                 f"{args.project}")

    rows = []
    print(f"{'deviations':44} {'in sha':8} {'packed':8} {'exec':8}  verdict")
    failures = 0
    for fixture in FIXTURES:
        a, err_a = packed(args.bin, fixture)
        b, err_b = exec_path(args.project, fixture)
        if a is None or b is None:
            failures += 1
            print(f"{json.dumps(fixture)[:44]:44} {digest(fixture)[:8]:8} "
                  f"{'ERR' if a is None else 'ok':8} {'ERR' if b is None else 'ok':8}"
                  f"  FAIL  {err_a or err_b}")
            continue
        ca, cb = canonical(a), canonical(b)
        same = ca == cb
        failures += 0 if same else 1
        rows.append({"fixture": fixture, "input_sha256": digest(fixture),
                     "packed_sha256": digest(ca), "exec_sha256": digest(cb),
                     "agree": same})
        print(f"{json.dumps(fixture)[:44]:44} {digest(fixture)[:8]:8} "
              f"{digest(ca)[:8]:8} {digest(cb)[:8]:8}  "
              f"{'AGREE' if same else 'DIFFER'}")
        if not same:
            print(f"    packed={ca} exec={cb}")

    total = len(FIXTURES)
    print(f"\n{total - failures}/{total} fixtures agree across both paths")
    if args.json:
        print(json.dumps({
            "ok": failures == 0,
            "checked_at": __import__("time").strftime("%Y-%m-%dT%H:%M:%SZ"),
            "packed_bin_sha256": (hashlib.sha256(open(args.bin, "rb").read()).hexdigest()
                                  if os.path.exists(args.bin) else None),
            "fixtures": rows,
            "attestation_sha256": digest(rows),
        }))
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
