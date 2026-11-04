# Contributing

Thanks for helping out. This is a small project, so the process is light.

## Getting set up

You need KDE Plasma 6 and `kpackagetool6`. Then:

```sh
git clone https://github.com/bootswithdefer/plasma-window-overlay.git
cd plasma-window-overlay
./scripts/install.sh
QT_FORCE_STDERR_LOGGING=1 plasmawindowed org.defer.windowoverlay
```

`plasmawindowed` runs the widget in a test window, and any QML errors print to the terminal.
After editing `package/`, run `./scripts/install.sh` again, and restart Plasma if you are
running the widget from a panel.

## Before opening a pull request

- Run `./scripts/check.sh`. CI runs the same checks.
- Say which Plasma version and session type (Wayland or X11) you tested on.
- Add a line under **Unreleased** in `CHANGELOG.md` for anything users will notice.
- If you add a setting, declare it in `package/contents/config/main.xml`, add it to
  `configGeneral.qml`, and use it in `main.qml`. `check.sh` catches settings that are only
  half wired up.
- Do not commit screenshots that show private content.

## Reporting bugs

Use the bug report template, and include your Plasma version, session type and monitor layout.
Output from `QT_FORCE_STDERR_LOGGING=1 plasmawindowed org.defer.windowoverlay` helps a lot.

## Releasing (maintainer)

See the "CI and releases" section of the [README](README.md#ci-and-releases).
