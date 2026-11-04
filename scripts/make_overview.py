#!/usr/bin/env python3
"""Generate docs/overview.svg, the README illustration (mock windows, not a real screenshot)."""
import pathlib

W, H = 1200, 640
out = []
a = out.append

a(f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}" role="img" '
  f'aria-label="Illustration of the overlay: a column of window thumbnails on the right edge of each of three monitors">')
a('''<defs>
<linearGradient id="bgd" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#151a24"/><stop offset="1" stop-color="#0e121a"/></linearGradient>
<style>
 .mon{fill:#0b0f16;stroke:#3a4458;stroke-width:3}
 .win{fill:#202938}
 .bar{fill:#2b3548}
 .line{fill:#4a5873}
 .lbl{font:600 15px 'Noto Sans','DejaVu Sans',sans-serif;fill:#9fb0cc}
 .cap{font:500 14px 'Noto Sans','DejaVu Sans',sans-serif;fill:#7d8ca6}
 .t{font:10px 'Noto Sans','DejaVu Sans',sans-serif;fill:#e8eef9}
 .strip{fill:#000;fill-opacity:.28}
 .thumb{fill:#ffffff;fill-opacity:.55}
 .act{fill:#3daee9;fill-opacity:.9;stroke:#bfe6fa;stroke-width:2}
</style></defs>''')
a(f'<rect width="{W}" height="{H}" rx="20" fill="url(#bgd)"/>')


def window(x, y, w, h, kind):
    a(f'<rect class="win" x="{x}" y="{y}" width="{w}" height="{h}"/>')
    a(f'<rect class="bar" x="{x}" y="{y}" width="{w}" height="22"/>')
    for i in range(6 + kind * 2):
        lw = (w - 60) * (0.35 + ((i * 37 + kind * 17) % 60) / 100)
        ly = y + 44 + i * (h - 80) / (8 + kind)
        a(f'<rect class="line" x="{x + 24}" y="{ly:.0f}" width="{lw:.0f}" height="8" rx="4" '
          f'fill-opacity="{0.55 if i % 3 else 0.9}"/>')


def strip(x, y, n, tw, th, active, labels):
    sh = n * (th + 16) + 10
    a(f'<rect class="strip" x="{x}" y="{y}" width="{tw + 12}" height="{sh}" rx="8"/>')
    for i in range(n):
        ty = y + 6 + i * (th + 16)
        a(f'<rect class="{"act" if i == active else "thumb"}" x="{x + 6}" y="{ty}" width="{tw}" height="{th}" rx="4"/>')
        a(f'<text class="t" x="{x + 10}" y="{ty + th + 11}">{labels[i]}</text>')


def monitor(x, y, w, h, name, labels, kind, active):
    n = len(labels)
    a(f'<rect class="mon" x="{x}" y="{y}" width="{w}" height="{h}" rx="8"/>')
    window(x + 6, y + 6, w - 12, h - 12, kind)
    top = int(h * 0.25)
    tw = int(w * 0.19)
    # shrink tiles (like the real widget) so the column never leaves the screen
    avail = h - top - 14
    th = min(int(tw * 9 / 16), int((avail - 10) / n) - 16)
    tw = min(tw, int(th * 16 / 9))
    strip(x + w - tw - 24, y + top, n, tw, th, active, labels)
    a(f'<text class="lbl" x="{x + w / 2}" y="{y + h + 24}" text-anchor="middle">{name}</text>')


# layout mirrors a real three-monitor desk: two across the top, one below the right
monitor(60, 50, 520, 290, "Monitor 1", ["Terminal", "Editor", "Notes"], 0, 1)
monitor(620, 50, 520, 290, "Monitor 2", ["Browser", "Chat", "Docs", "Files"], 1, 0)
monitor(840, 395, 300, 170, "Monitor 3", ["Mail", "Calendar"], 2, 1)
a('<text class="cap" x="60" y="560">Illustration only: mock windows and approximate layout, not a real screenshot.</text>')
a('<text class="cap" x="60" y="584">Each monitor gets its own translucent column listing just that screen\'s windows;</text>')
a('<text class="cap" x="60" y="604">the highlighted tile is the focused window, and clicking a tile focuses it.</text>')
a('</svg>')

pathlib.Path(__file__).resolve().parent.parent.joinpath("docs", "overview.svg").write_text("\n".join(out) + "\n")
