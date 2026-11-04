#!/usr/bin/env bash
# Install (or upgrade) the widget for the current user from this checkout.
set -euo pipefail
cd "$(dirname "$0")/.."

if kpackagetool6 --type Plasma/Applet --show "$(python3 -c 'import json;print(json.load(open("package/metadata.json"))["KPlugin"]["Id"])')" >/dev/null 2>&1; then
  kpackagetool6 --type Plasma/Applet --upgrade package
else
  kpackagetool6 --type Plasma/Applet --install package
fi
echo
echo "Installed. Add 'Window Overlay' from the panel's 'Add or Manage Widgets', or test with:"
echo "  plasmawindowed build.abort.windowoverlay"
echo "If upgrading, restart Plasma to load the new version:"
echo "  systemctl --user restart plasma-plasmashell"
