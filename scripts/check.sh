#!/usr/bin/env bash
# Static checks for the plasmoid package. Used locally and by CI.
set -euo pipefail
cd "$(dirname "$0")/.."

fail=0
say() { printf '%s\n' "$*"; }

say "==> metadata.json"
python3 - <<'PY'
import json, re, sys
d = json.load(open("package/metadata.json"))
k = d["KPlugin"]
errors = []
for key in ("Id", "Name", "Description", "Version", "License"):
    if not k.get(key):
        errors.append(f"KPlugin.{key} is missing")
if k.get("License") != "MIT":
    errors.append(f"License should be MIT, found {k.get('License')!r}")
if not re.fullmatch(r"\d+\.\d+\.\d+", k.get("Version", "")):
    errors.append(f"Version {k.get('Version')!r} is not MAJOR.MINOR.PATCH")
if d.get("KPackageStructure") != "Plasma/Applet":
    errors.append("KPackageStructure must be Plasma/Applet")
if errors:
    print("\n".join("  error: " + e for e in errors)); sys.exit(1)
print(f"  ok: {k['Id']} {k['Version']}")
PY

say "==> config schema (main.xml) is well-formed"
xmllint --noout package/contents/config/main.xml

say "==> every Plasmoid.configuration.* key used in QML exists in main.xml"
python3 - <<'PY'
import re, sys, pathlib
schema = pathlib.Path("package/contents/config/main.xml").read_text()
entries = set(re.findall(r'<entry name="(\w+)"', schema))
used = set()
for f in pathlib.Path("package/contents").rglob("*.qml"):
    text = f.read_text()
    used |= set(re.findall(r"Plasmoid\.configuration\.(\w+)", text))
    used |= {m for m in re.findall(r"\bcfg_(\w+)", text) if not m.endswith("Default")}
missing = sorted(used - entries)
unused = sorted(entries - used)
if missing:
    print("  error: used in QML but not in main.xml:", ", ".join(missing)); sys.exit(1)
if unused:
    print("  error: in main.xml but never used:", ", ".join(unused)); sys.exit(1)
print(f"  ok: {len(entries)} settings, all wired up")
PY

say "==> SVG assets are well-formed"
xmllint --noout assets/logo.svg docs/overview.svg

say "==> no leftover debug logging"
if grep -rn "console\.log" package/contents; then
  say "  error: console.log found in package"; fail=1
else
  say "  ok"
fi

say "==> qmllint"
if command -v qmllint >/dev/null 2>&1; then
  # Plasma's own QML modules may not be installed where this runs, so unresolved
  # imports are not treated as problems; syntax errors still fail. Newer Qt 6
  # versions of qmllint can silence those categories, older ones only check syntax.
  opts=()
  if qmllint --help-all 2>&1 | grep -q -- '--import'; then
    opts+=(--import disable --unqualified disable --unused-imports disable)
  fi
  qmllint "${opts[@]}" package/contents/ui/*.qml package/contents/config/config.qml
  say "  ok"
else
  say "  skipped: qmllint not installed"
fi

exit "$fail"
