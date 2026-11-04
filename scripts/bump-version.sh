#!/usr/bin/env bash
# Usage: scripts/bump-version.sh 0.2.0
# Updates package/metadata.json and stamps the CHANGELOG. Review the diff, commit, then tag vX.Y.Z.
set -euo pipefail
cd "$(dirname "$0")/.."

new="${1:?usage: $0 MAJOR.MINOR.PATCH}"
[[ "$new" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "not a MAJOR.MINOR.PATCH version: $new" >&2; exit 1; }

python3 - "$new" <<'PY'
import json, sys, re, datetime, pathlib
new = sys.argv[1]
p = pathlib.Path("package/metadata.json")
d = json.loads(p.read_text())
old = d["KPlugin"]["Version"]
d["KPlugin"]["Version"] = new
p.write_text(json.dumps(d, indent=4) + "\n")

c = pathlib.Path("CHANGELOG.md")
t = c.read_text()
today = datetime.date.today().isoformat()
t = t.replace("## [Unreleased]\n", f"## [Unreleased]\n\n## [{new}] - {today}\n", 1)
t = re.sub(r"\[Unreleased\]: (\S+)/compare/v\S+\.\.\.HEAD",
           rf"[Unreleased]: \1/compare/v{new}...HEAD\n[{new}]: \1/compare/v{old}...v{new}", t, count=1)
c.write_text(t)
print(f"{old} -> {new}")
PY
echo "Next: review 'git diff', commit, then: git tag v$new && git push --follow-tags"
