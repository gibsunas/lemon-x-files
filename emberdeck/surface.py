#!/usr/bin/env python3
"""Generate a dynamic skill and a BAML type surface from a live MCP server.

The point of "dynamic": the tool list is read at generation time through the
proxy, so the skill and the types cannot drift from what the server actually
serves. A hand-written skill goes stale the day someone adds a tool.

    python3 surface.py --proxy http://127.0.0.1:8588/mcp --key key-a --out generated

Writes:
    generated/baml.toml
    generated/baml_src/surface.baml     typed tool surface (validated by `baml check`)
    generated/SKILL.md                  the skill an agent is handed
"""
import argparse
import json
import os
import re
import subprocess
import urllib.error
import urllib.request

TYPE_MAP = {
    "string": "string",
    "integer": "int",
    "number": "float",
    "boolean": "bool",
    "array": "string[]",
    "object": "map<string, string>",
}


def rpc(url, key, payload):
    data = json.dumps(payload).encode()
    req = urllib.request.Request(url, data=data, method="POST")
    req.add_header("Content-Type", "application/json")
    if key:
        req.add_header("Authorization", "Bearer " + key)
    with urllib.request.urlopen(req, timeout=15) as resp:
        return json.load(resp)


def discover(url, key):
    body = rpc(url, key, {"jsonrpc": "2.0", "id": 1, "method": "tools/list"})
    return body["result"]["tools"]


def enum_member(name):
    return re.sub(r"[^A-Z0-9]+", "_", name.upper()).strip("_")


def class_name(tool):
    return "".join(part.capitalize() for part in re.split(r"[_\-]", tool)) + "Args"


def baml_type(prop):
    kind = prop.get("type")
    if kind == "array":
        item = (prop.get("items") or {}).get("type", "string")
        return TYPE_MAP.get(item, "string") + "[]"
    return TYPE_MAP.get(kind, "string")


def clean(text):
    return re.sub(r"\s+", " ", str(text or "")).replace('"', "'")[:160]


def emit_baml(tools):
    lines = ["// Generated from a live tools/list. Do not edit by hand.", ""]
    lines.append("enum ToolName {")
    for tool in tools:
        lines.append(f"  {enum_member(tool['name'])}")
    lines.append("}")
    lines.append("")

    for tool in tools:
        schema = tool.get("inputSchema") or {}
        props = schema.get("properties") or {}
        required = set(schema.get("required") or [])
        lines.append(f"class {class_name(tool['name'])} {{")
        if not props:
            lines.append("  // no arguments")
        for name, prop in props.items():
            optional = "" if name in required else "?"
            desc = f' @description("{clean(prop.get("description"))}")' if prop.get("description") else ""
            lines.append(f"  {name} {baml_type(prop)}{optional}{desc}")
        lines.append("}")
        lines.append("")

    lines.append("class ToolCall {")
    lines.append("  tool ToolName")
    for tool in tools:
        lines.append(f"  {tool['name']} {class_name(tool['name'])}?")
    lines.append("}")
    lines.append("")

    # A pure function: it declares the surface without an LLM, so the file
    # compiles and can be checked offline. The LLM-backed planner is the same
    # shapes plus a client and prompt.
    lines.append("function DeclareToolSurface() -> ToolName[] {")
    members = ", ".join(f"ToolName.{enum_member(t['name'])}" for t in tools)
    lines.append(f"  [{members}]")
    lines.append("}")
    return "\n".join(lines) + "\n"


def emit_skill(tools, proxy):
    lines = [
        "---",
        'name: deck-operator',
        'description: "Use when operating or monitoring the laser deck through its MCP '
        'proxy: list or start a job, read live progress, or pull the workspace audit."',
        "---",
        "",
        "# Operating the deck through its proxy",
        "",
        f"Generated from the live surface at `{proxy}`. {len(tools)} tools.",
        "",
        "## Tool surface",
        "",
        "| tool | arguments | required |",
        "| --- | --- | --- |",
    ]
    for tool in tools:
        schema = tool.get("inputSchema") or {}
        props = schema.get("properties") or {}
        required = set(schema.get("required") or [])
        args = ", ".join(f"`{k}: {v.get('type', '?')}`" for k, v in props.items()) or "—"
        req = ", ".join(f"`{r}`" for r in sorted(required)) or "—"
        lines.append(f"| `{tool['name']}` | {args} | {req} |")

    lines += [
        "",
        "## Byte safety",
        "",
        "G-code is a byte protocol. Before any `emberdeck_upload_job` call:",
        "",
        "1. the program is ASCII; any byte ≥ 0x80 is a defect, not an accent;",
        "2. the only control bytes are TAB, CR and LF — the deck rejects the rest;",
        "3. line endings are LF, normalised before upload;",
        "4. the program is at most 4 MiB (the deck returns 413 above it);",
        "5. record `sha256` of the exact bytes sent, then confirm the deck stored",
        "   the same bytes — `GET /api/v1/jobs/{id}` returns the program.",
        "",
        "Run `bytecheck.py --self-test` before trusting the path, and",
        "`bytecheck.py --verify <job_id> --expect <sha256>` after an upload.",
        "",
        "## What this skill must not do",
        "",
        "- It does not start a job without `confirmed: true`; the deck rejects it.",
        "- It does not treat `monitor_incidents` as a safety record: it is an audit.",
        "- It does not assume a preview is a cut: upload stores, start cuts.",
        "",
    ]
    return "\n".join(lines)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--proxy", default="http://127.0.0.1:8588/mcp")
    ap.add_argument("--key", default=os.environ.get("MCP_KEY", ""))
    ap.add_argument("--out", default="generated")
    args = ap.parse_args()

    tools = discover(args.proxy, args.key)
    os.makedirs(os.path.join(args.out, "baml_src"), exist_ok=True)
    with open(os.path.join(args.out, "baml.toml"), "w") as fh:
        fh.write('[package]\nname = "deck-surface"\n')
    baml_path = os.path.join(args.out, "baml_src", "surface.baml")
    with open(baml_path, "w") as fh:
        fh.write(emit_baml(tools))
    with open(os.path.join(args.out, "SKILL.md"), "w") as fh:
        fh.write(emit_skill(tools, args.proxy))

    print(f"generated {len(tools)} tools -> {args.out}/")
    for tool in tools:
        print(f"  {tool['name']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
