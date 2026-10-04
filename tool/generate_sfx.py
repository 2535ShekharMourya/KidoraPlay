"""Synthesises placeholder sound effects and a soft background music loop.

Existing files are never overwritten, so real sounds can replace these.
Generated files are added to tool/placeholder_assets.txt.

Requires: Python 3, ffmpeg on PATH.

    python tool/generate_sfx.py
"""

import math
import random
import struct
import subprocess
import tempfile
import wave
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
LIST_FILE = ROOT / "tool" / "placeholder_assets.txt"
RATE = 44100


def tone(freq_start, freq_end, dur, vol=0.5, decay=8.0, shape="sine"):
    """A pitch sweep with an exponential decay envelope."""
    out = []
    phase = 0.0
    n = int(dur * RATE)
    for i in range(n):
        t = i / RATE
        f = freq_start + (freq_end - freq_start) * (i / n)
        phase += 2 * math.pi * f / RATE
        if shape == "triangle":
            s = 2 / math.pi * math.asin(math.sin(phase))
        else:
            s = math.sin(phase)
        attack = min(1.0, t / 0.005)
        out.append(s * vol * attack * math.exp(-decay * t))
    return out


def mix(*tracks_with_offsets):
    """Mixes (offset_seconds, samples) pairs."""
    length = max(int(o * RATE) + len(s) for o, s in tracks_with_offsets)
    out = [0.0] * length
    for offset, samples in tracks_with_offsets:
        start = int(offset * RATE)
        for i, v in enumerate(samples):
            out[start + i] += v
    return out


def noise_whoosh(dur=0.35, vol=0.35):
    rnd = random.Random(7)
    out, prev = [], 0.0
    n = int(dur * RATE)
    for i in range(n):
        x = i / n
        # Low-passed noise whose cutoff rises, with a hump envelope.
        alpha = 0.02 + 0.25 * x
        prev += alpha * (rnd.uniform(-1, 1) - prev)
        out.append(prev * vol * math.sin(math.pi * x) * 3)
    return out


def melody_loop():
    """16 s gentle pentatonic loop (C major pentatonic), triangle voice."""
    bpm = 96
    beat = 60 / bpm
    notes = [  # (semitones above C5, beats)
        (0, 1), (4, 1), (7, 1), (9, 1), (7, 2), (4, 2),
        (2, 1), (4, 1), (7, 1), (4, 1), (2, 2), (0, 2),
        (0, 1), (4, 1), (7, 1), (12, 1), (9, 2), (7, 2),
        (4, 1), (2, 1), (4, 1), (2, 1), (0, 4),
    ]
    tracks, t = [], 0.0
    for semi, beats in notes:
        f = 523.25 * 2 ** (semi / 12)
        tracks.append((t, tone(f, f, beats * beat * 0.95, 0.18, 2.5, "triangle")))
        t += beats * beat
    # Soft bass on each bar.
    bass = [0, -5, -3, -7, 0, -5, -8, 0]
    for i, semi in enumerate(bass):
        f = 130.81 * 2 ** (semi / 12)
        tracks.append((i * 4 * beat, tone(f, f, 4 * beat, 0.12, 1.2)))
    out = mix(*tracks)
    total = int(t * RATE)
    out = (out + [0.0] * total)[:total]
    # Short fades so the loop point is click-free.
    fade = int(0.02 * RATE)
    for i in range(fade):
        out[i] *= i / fade
        out[-1 - i] *= i / fade
    return out


SOUNDS = {
    "assets/audio/sfx/tap.m4a": lambda: tone(700, 950, 0.07, 0.45, 40),
    "assets/audio/sfx/pop.m4a": lambda: tone(380, 1300, 0.09, 0.55, 30),
    "assets/audio/sfx/sparkle.m4a": lambda: mix(
        (0.00, tone(1568, 1568, 0.25, 0.25, 14)),
        (0.06, tone(2093, 2093, 0.25, 0.22, 14)),
        (0.12, tone(2637, 2637, 0.30, 0.20, 12)),
    ),
    "assets/audio/sfx/cheer.m4a": lambda: mix(
        (0.00, tone(523, 523, 0.5, 0.25, 5, "triangle")),
        (0.10, tone(659, 659, 0.5, 0.25, 5, "triangle")),
        (0.20, tone(784, 784, 0.5, 0.25, 5, "triangle")),
        (0.30, tone(1047, 1047, 0.7, 0.28, 4, "triangle")),
    ),
    "assets/audio/sfx/whoosh.m4a": noise_whoosh,
    "assets/audio/sfx/oops.m4a": lambda: tone(520, 340, 0.25, 0.4, 7, "triangle"),
    "assets/audio/music/home_loop.m4a": melody_loop,
}


def write(path, samples):
    peak = max(1e-9, max(abs(s) for s in samples))
    gain = min(1.0, 0.9 / peak)
    with tempfile.TemporaryDirectory() as tmp:
        wav = Path(tmp) / "out.wav"
        with wave.open(str(wav), "wb") as w:
            w.setnchannels(1)
            w.setsampwidth(2)
            w.setframerate(RATE)
            w.writeframes(b"".join(
                struct.pack("<h", int(s * gain * 32767)) for s in samples))
        out = ROOT / path
        out.parent.mkdir(parents=True, exist_ok=True)
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", str(wav),
                        "-ac", "1", "-ar", str(RATE), "-c:a", "aac",
                        "-b:a", "96k", str(out)], check=True)


def main():
    made = []
    for path, make in SOUNDS.items():
        if not (ROOT / path).exists():
            write(path, make())
            made.append(path)
    if made:
        existing = set()
        if LIST_FILE.exists():
            existing = set(LIST_FILE.read_text(encoding="utf-8").split())
        LIST_FILE.write_text(
            "\n".join(sorted(existing | set(made))) + "\n", encoding="utf-8")
    print(f"generated {len(made)} sound files")


if __name__ == "__main__":
    main()
