#!/usr/bin/env bash
# Build dist/<id>-<version>.plasmoid (a zip of the package directory).
set -euo pipefail
cd "$(dirname "$0")/.."

id=$(python3 -c 'import json;print(json.load(open("package/metadata.json"))["KPlugin"]["Id"])')
version=$(python3 -c 'import json;print(json.load(open("package/metadata.json"))["KPlugin"]["Version"])')
out="dist/${id}-${version}.plasmoid"

mkdir -p dist
rm -f "$out"
(cd package && zip -qr -X "../$out" metadata.json contents)
(cd dist && sha256sum "$(basename "$out")" > "$(basename "$out").sha256")
echo "built $out"
