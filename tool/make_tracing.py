"""Writes assets/content/tracing.json: how to write A-Z and 0-9.

Each glyph is a list of strokes in writing order; each stroke is a list of
[x, y] points in a unit box (x right, y down, letters span y 0.1-0.9), in
the direction the finger moves. Curves are sampled every 10 degrees; the
app resamples evenly.

Run: python tool/make_tracing.py
"""

import json
import math
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
T, M, B = 0.1, 0.5, 0.9  # top, middle, bottom


def arc(cx, cy, rx, ry, start, end, step=10):
    """Points on an ellipse from angle [start] to [end] (degrees; 0 = right,
    90 = down, so decreasing angles go anticlockwise on screen)."""
    n = max(2, int(abs(end - start) / step) + 1)
    pts = []
    for i in range(n):
        a = math.radians(start + (end - start) * i / (n - 1))
        pts.append((cx + rx * math.cos(a), cy + ry * math.sin(a)))
    return pts


def path(*parts):
    """Joins points and point lists into one stroke."""
    pts = []
    for part in parts:
        for p in (part if isinstance(part, list) else [part]):
            if not pts or math.dist(pts[-1], p) > 1e-6:
                pts.append(p)
    return pts


GLYPHS = {
    "A": [path((0.5, T), (0.15, B)), path((0.5, T), (0.85, B)),
          path((0.29, 0.62), (0.71, 0.62))],
    "B": [path((0.25, T), (0.25, B)),
          path((0.25, T), (0.5, T), arc(0.5, 0.3, 0.22, 0.2, -90, 90),
               (0.25, M)),
          path((0.25, M), (0.55, M), arc(0.55, 0.7, 0.25, 0.2, -90, 90),
               (0.25, B))],
    "C": [arc(0.55, M, 0.36, 0.4, -40, -320)],
    "D": [path((0.25, T), (0.25, B)),
          path((0.25, T), (0.42, T), arc(0.42, M, 0.36, 0.4, -90, 90),
               (0.25, B))],
    "E": [path((0.3, T), (0.3, B)), path((0.3, T), (0.75, T)),
          path((0.3, M), (0.68, M)), path((0.3, B), (0.75, B))],
    "F": [path((0.3, T), (0.3, B)), path((0.3, T), (0.75, T)),
          path((0.3, M), (0.68, M))],
    "G": [arc(0.52, M, 0.36, 0.4, -40, -360), path((0.6, M), (0.88, M))],
    "H": [path((0.2, T), (0.2, B)), path((0.8, T), (0.8, B)),
          path((0.2, M), (0.8, M))],
    "I": [path((0.5, T), (0.5, B)), path((0.3, T), (0.7, T)),
          path((0.3, B), (0.7, B))],
    "J": [path((0.65, T), (0.65, 0.65), arc(0.45, 0.65, 0.2, 0.25, 0, 180))],
    "K": [path((0.25, T), (0.25, B)), path((0.75, T), (0.25, 0.58)),
          path((0.4, 0.46), (0.78, B))],
    "L": [path((0.3, T), (0.3, B), (0.75, B))],
    "M": [path((0.15, B), (0.15, T)),
          path((0.15, T), (0.5, 0.62), (0.85, T), (0.85, B))],
    "N": [path((0.2, B), (0.2, T)), path((0.2, T), (0.8, B), (0.8, T))],
    "O": [arc(0.5, M, 0.36, 0.4, -90, -450)],
    "P": [path((0.25, T), (0.25, B)),
          path((0.25, T), (0.5, T), arc(0.5, 0.3, 0.22, 0.2, -90, 90),
               (0.25, M))],
    "Q": [arc(0.5, M, 0.36, 0.4, -90, -450), path((0.56, 0.66), (0.86, 0.95))],
    "R": [path((0.25, T), (0.25, B)),
          path((0.25, T), (0.5, T), arc(0.5, 0.3, 0.22, 0.2, -90, 90),
               (0.25, M)),
          path((0.45, M), (0.8, B))],
    "S": [path(arc(0.5, 0.3, 0.27, 0.2, -20, -270),
               arc(0.5, 0.7, 0.29, 0.2, -90, 160))],
    "T": [path((0.15, T), (0.85, T)), path((0.5, T), (0.5, B))],
    "U": [path((0.2, T), (0.2, 0.6), arc(0.5, 0.6, 0.3, 0.3, 180, 0),
               (0.8, T))],
    "V": [path((0.15, T), (0.5, B), (0.85, T))],
    "W": [path((0.08, T), (0.3, B), (0.5, 0.35), (0.7, B), (0.92, T))],
    "X": [path((0.2, T), (0.8, B)), path((0.8, T), (0.2, B))],
    "Y": [path((0.2, T), (0.5, M)), path((0.8, T), (0.5, M), (0.5, B))],
    "Z": [path((0.2, T), (0.8, T), (0.2, B), (0.8, B))],
    "0": [arc(0.5, M, 0.3, 0.4, -90, -450)],
    "1": [path((0.33, 0.27), (0.55, T), (0.55, B))],
    "2": [path(arc(0.5, 0.33, 0.27, 0.23, -170, 30), (0.2, B), (0.8, B))],
    "3": [path(arc(0.48, 0.3, 0.26, 0.2, -160, 90),
               arc(0.48, 0.7, 0.3, 0.2, -90, 160))],
    "4": [path((0.6, T), (0.15, 0.65), (0.85, 0.65)), path((0.6, T), (0.6, B))],
    "5": [path((0.31, T), (0.31, 0.445), arc(0.48, 0.65, 0.3, 0.25, -125, 150)),
          path((0.31, T), (0.75, T))],
    "6": [path(arc(0.62, 0.62, 0.42, 0.52, -70, -180), (0.2, 0.68),
               arc(0.5, 0.68, 0.3, 0.22, 180, -180))],
    "7": [path((0.2, T), (0.8, T), (0.4, B))],
    "8": [path(arc(0.5, 0.3, 0.22, 0.2, -90, -270),
               arc(0.5, 0.7, 0.27, 0.2, -90, 270),
               arc(0.5, 0.3, 0.22, 0.2, 90, -90))],
    "9": [path(arc(0.5, 0.32, 0.27, 0.22, 0, -360), (0.77, B))],
}


def main():
    out = {
        glyph: [[[round(x, 3), round(y, 3)] for x, y in stroke]
                for stroke in strokes]
        for glyph, strokes in GLYPHS.items()
    }
    for glyph, strokes in out.items():
        for stroke in strokes:
            assert len(stroke) >= 2, glyph
            for x, y in stroke:
                assert -0.01 <= x <= 1.01 and -0.01 <= y <= 1.01, (glyph, x, y)
    p = ROOT / "assets/content/tracing.json"
    p.write_text(json.dumps(out, separators=(",", ":")) + "\n", encoding="utf-8")
    print(f"wrote {p.relative_to(ROOT)} ({len(out)} glyphs)")


if __name__ == "__main__":
    main()
