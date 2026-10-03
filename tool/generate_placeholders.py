"""Creates placeholder assets for every file referenced by assets/content/*.json
that does not exist yet. Existing files are never overwritten, so real art
and recordings can replace placeholders one by one.

- Images: pastel card with the numeral / letter / word (.webp, 512x512).
- English voice: Windows built-in TTS (System.Speech), converted to .m4a.
- Hindi voice: short silence (no Hindi TTS voice installed).
- Animal/bird sounds: short soft tone.

Every generated file is listed in tool/placeholder_assets.txt so the team
knows what still needs real content.

Requires: Python 3 + Pillow, ffmpeg on PATH, Windows (for English TTS).

    python tool/generate_placeholders.py
"""

import json
import re
import shutil
import subprocess
import tempfile
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
CONTENT = ROOT / "assets" / "content"
FONT = ROOT / "assets" / "fonts" / "Baloo2-Variable.ttf"
LIST_FILE = ROOT / "tool" / "placeholder_assets.txt"

SECTION_COLOURS = {
    "numbers": ((221, 241, 255), (46, 155, 255)),
    "abc": ((255, 244, 199), (255, 184, 0)),
    "animals": ((221, 245, 220), (61, 178, 75)),
    "birds": ((255, 230, 211), (255, 122, 47)),
    "sections": ((255, 248, 236), (59, 53, 97)),
}
INK = (46, 42, 71)

images = {}  # path -> (section, lines, dots)
speech_en = {}  # path -> text
silent = set()
tones = set()


def load(name):
    return json.loads((CONTENT / name).read_text(encoding="utf-8"))


def collect():
    for section in load("sections.json"):
        images[section["image"]] = ("sections", [section["title_en"]], 0)
        speech_en[section["voice_en"]] = section["title_en"]
        silent.add(section["voice_hi"])
        for it in load(Path(section["items"]).name):
            sec = it["section"]
            if sec == "numbers":
                lines, dots = [str(it["number"])], it["number"]
            elif sec == "abc":
                lines, dots = [f'{it["letter"]} {it["letter"].lower()}',
                               it["word_en"]], 0
            else:
                lines, dots = [it["word_en"]], 0
            images[it["image"]] = (sec, lines, dots)
            speech_en[it["voice_en"]] = it["word_en"]
            silent.add(it["voice_hi"])
            if it.get("sound"):
                tones.add(it["sound"])

    for event in load("kido_lines.json").values():
        for lang, variants in event.items():
            for v in variants:
                files = [s for s in v["audio"] if not s.startswith("{")]
                # Split the text at placeholders to get each segment's words.
                parts = [p.strip(" !") for p in re.split(r"\{\w+\}", v["text"])]
                parts = [p for p in parts if p]
                for i, f in enumerate(files):
                    if lang == "en":
                        speech_en[f] = parts[i] if i < len(parts) else v["text"]
                    else:
                        silent.add(f)

    for c in "abcdefghijklmnopqrstuvwxyz":
        speech_en[f"assets/audio/letters/{c}.m4a"] = c.upper()


def missing(path):
    return not (ROOT / path).exists()


def make_image(path, section, lines, dots):
    bg, accent = SECTION_COLOURS[section]
    size = 512
    img = Image.new("RGB", (size, size), bg)
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([16, 16, size - 16, size - 16], radius=56,
                        fill=(255, 255, 255), outline=accent, width=12)
    big = ImageFont.truetype(str(FONT), 170 if len(lines[0]) <= 3 else 96)
    small = ImageFont.truetype(str(FONT), 64)
    y = 120 if dots or len(lines) > 1 else 180
    for i, line in enumerate(lines):
        font = big if i == 0 else small
        w = d.textlength(line, font=font)
        d.text(((size - w) / 2, y), line, font=font, fill=INK)
        y += 190 if i == 0 else 80
    if dots:
        per_row = 5
        r = 18
        rows = (dots + per_row - 1) // per_row
        top = 360 if rows == 1 else 330
        for k in range(dots):
            row, col = divmod(k, per_row)
            count = min(per_row, dots - row * per_row)
            x0 = size / 2 - (count * 56) / 2 + col * 56 + 10
            y0 = top + row * 56
            d.ellipse([x0, y0, x0 + 2 * r, y0 + 2 * r], fill=accent)
    out = ROOT / path
    out.parent.mkdir(parents=True, exist_ok=True)
    img.save(out, "WEBP", quality=80)


def ffmpeg(args, out):
    out.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", *args,
                    "-ac", "1", "-ar", "44100", "-c:a", "aac", "-b:a", "64k",
                    str(out)], check=True)


def make_speech(jobs):
    """Synthesises all English lines in one PowerShell call."""
    if not jobs:
        return
    tmp = Path(tempfile.mkdtemp())
    script = ["Add-Type -AssemblyName System.Speech",
              "$s = New-Object System.Speech.Synthesis.SpeechSynthesizer",
              "$s.SelectVoice('Microsoft Zira Desktop')",
              "$s.Rate = -1"]
    wavs = []
    for i, (path, text) in enumerate(jobs):
        wav = tmp / f"{i}.wav"
        wavs.append((path, wav))
        safe = text.replace("'", "''")
        script += [f"$s.SetOutputToWaveFile('{wav}')", f"$s.Speak('{safe}')"]
    script.append("$s.Dispose()")
    ps1 = tmp / "speak.ps1"
    ps1.write_text("\n".join(script), encoding="utf-8-sig")
    subprocess.run(["powershell", "-NoProfile", "-ExecutionPolicy", "Bypass",
                    "-File", str(ps1)], check=True)
    for path, wav in wavs:
        # Trim leading/trailing silence as the content spec requires.
        ffmpeg(["-i", str(wav), "-af",
                "silenceremove=start_periods=1:start_threshold=-50dB,"
                "areverse,silenceremove=start_periods=1:start_threshold=-50dB,"
                "areverse"], ROOT / path)
    shutil.rmtree(tmp)


def main():
    collect()
    made = []

    for path, (section, lines, dots) in images.items():
        if missing(path):
            make_image(path, section, lines, dots)
            made.append(path)

    jobs = [(p, t) for p, t in speech_en.items() if missing(p)]
    make_speech(jobs)
    made += [p for p, _ in jobs]

    for path in sorted(silent):
        if missing(path):
            ffmpeg(["-f", "lavfi", "-i", "anullsrc=r=44100:cl=mono",
                    "-t", "0.3"], ROOT / path)
            made.append(path)

    for path in sorted(tones):
        if missing(path):
            ffmpeg(["-f", "lavfi", "-i", "sine=frequency=660:duration=0.4",
                    "-af", "afade=t=out:st=0.25:d=0.15,volume=0.4"],
                   ROOT / path)
            made.append(path)

    if made:
        existing = set()
        if LIST_FILE.exists():
            existing = set(LIST_FILE.read_text(encoding="utf-8").split())
        LIST_FILE.write_text(
            "\n".join(sorted(existing | set(made))) + "\n", encoding="utf-8")
    print(f"generated {len(made)} placeholder files")


if __name__ == "__main__":
    main()
