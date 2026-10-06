"""Writes xylophone notes for the music toy: assets/audio/music/notes/*.m4a.

A pentatonic scale (C D E G A, then high C D): any order of taps sounds
nice, so a toddler can't play a "wrong" note. Each note is synthesised
(a bright fundamental plus fading overtones, like a wooden bar), so no
recordings or licences are needed.

    python tool/make_notes.py
"""

import math
import struct
import subprocess
import tempfile
import wave
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets" / "audio" / "music" / "notes"
RATE = 44100
LENGTH = 1.2  # seconds

# C5 D5 E5 G5 A5 C6 D6 (Hz).
NOTES = {
    "note_0": 523.25, "note_1": 587.33, "note_2": 659.25,
    "note_3": 783.99, "note_4": 880.00, "note_5": 1046.50,
    "note_6": 1174.66,
}


def bar(freq):
    """A struck wooden bar: quick attack, fast decay, soft overtones."""
    samples = []
    for i in range(int(RATE * LENGTH)):
        t = i / RATE
        attack = min(1.0, t / 0.004)
        v = (math.sin(2 * math.pi * freq * t) * math.exp(-t * 4.5)
             + 0.35 * math.sin(2 * math.pi * freq * 3.9 * t) * math.exp(-t * 14)
             + 0.15 * math.sin(2 * math.pi * freq * 9.2 * t) * math.exp(-t * 30))
        samples.append(attack * v * 0.6)
    return samples


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory() as tmp:
        for name, freq in NOTES.items():
            wav = Path(tmp) / f"{name}.wav"
            with wave.open(str(wav), "wb") as w:
                w.setnchannels(1)
                w.setsampwidth(2)
                w.setframerate(RATE)
                w.writeframes(b"".join(
                    struct.pack("<h", int(max(-1, min(1, s)) * 32000))
                    for s in bar(freq)))
            out = OUT / f"{name}.m4a"
            subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", str(wav),
                            "-c:a", "aac", "-b:a", "96k", str(out)], check=True)
            print("wrote", out.relative_to(ROOT))


if __name__ == "__main__":
    main()
