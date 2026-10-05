"""Generates Kido's voice clips with Indian neural voices (development only).

English: en-IN-NeerjaNeural. Hindi: hi-IN-SwaraNeural. Slightly slower and
brighter than default, which suits 2-6-year-olds.

Covers every voice file referenced by assets/content/*.json: item words,
fun facts, section names, animal/bird sounds (spoken, e.g. "Moo!"), the 26
letters and Kido's lines. Clips are normalised to the same loudness, mono,
44.1 kHz .m4a with trimmed silence.

Only files that are missing or listed in tool/placeholder_assets.txt are
written, so real recordings are never overwritten. A manifest in
tool/.cache skips clips whose text and voice have not changed.

IMPORTANT: this uses Microsoft's Edge read-aloud service via the
`edge-tts` package. That is fine for development placeholders but is NOT
licensed for a published app. Before release, replace these with a voice
artist's recordings or a commercially licensed TTS (e.g. Azure AI Speech).

    pip install edge-tts
    python tool/make_voice.py
"""

import asyncio
import hashlib
import json
import re
import subprocess
import sys
import tempfile
from pathlib import Path

import edge_tts

sys.path.insert(0, str(Path(__file__).parent))
from make_items import SOUND_TEXT  # noqa: E402

ROOT = Path(__file__).resolve().parent.parent
CONTENT = ROOT / "assets" / "content"
LIST_FILE = ROOT / "tool" / "placeholder_assets.txt"
MANIFEST = ROOT / "tool" / ".cache" / "voice_manifest.json"

VOICES = {"en": "en-IN-NeerjaNeural", "hi": "hi-IN-SwaraNeural"}
# Hindi a little slower and brighter: clearer and warmer for children.
PROSODY = {"en": ("-12%", "+8Hz"), "hi": ("-18%", "+14Hz")}

# How to say a Hindi letter on its own. The TTS reads some bare letters
# oddly (or as their name in English), so give it a spoken form.
LETTER_SAY = {
    "अ": "अ!", "आ": "आ!", "इ": "इ!", "ई": "ई!", "उ": "उ!", "ऊ": "ऊ!",
    "ऋ": "रि!", "ए": "ए!", "ऐ": "ऐ!", "ओ": "ओ!", "औ": "औ!",
    "अं": "अं!", "ष": "ष!", "क्ष": "क्ष!", "त्र": "त्र!", "ज्ञ": "ग्य!",
}
RETRIES = 8
WORKERS = 4


def load(name):
    return json.loads((CONTENT / name).read_text(encoding="utf-8"))


def collect():
    """Returns {asset path: (language, text)}."""
    jobs = {}
    for section in load("sections.json"):
        jobs[section["voice_en"]] = ("en", section["title_en"])
        jobs[section["voice_hi"]] = ("hi", section["title_hi"])
        for it in load(Path(section["items"]).name):
            jobs[it["voice_en"]] = ("en", it["word_en"])
            jobs[it["voice_hi"]] = ("hi", it["word_hi"])
            if it.get("fact_en"):
                jobs[it["voice_fact_en"]] = ("en", it["fact_en"])
                jobs[it["voice_fact_hi"]] = ("hi", it["fact_hi"])
            if it.get("voice_intro_en"):
                jobs[it["voice_intro_en"]] = (
                    "en", f'{it["letter"]} for {it["word_en"]}!')
            if it.get("voice_intro_hi"):
                jobs[it["voice_intro_hi"]] = (
                    "hi", f'{it["letter"]} से {it["word_hi"]}!')
            if it.get("letter_voice"):
                jobs[it["letter_voice"]] = (
                    "hi", LETTER_SAY.get(it["letter"], it["letter"] + "!"))
            if it.get("sound"):
                jobs[it["sound"]] = ("en", SOUND_TEXT[it["id"]])

    for event in load("kido_lines.json").values():
        for lang, variants in event.items():
            for v in variants:
                files = [s for s in v["audio"] if not s.startswith("{")]
                parts = [p.strip(" ,") for p in re.split(r"\{\w+\}", v["text"])]
                parts = [p for p in parts if p.strip(" !?.")]
                for i, f in enumerate(files):
                    jobs[f] = (lang, parts[i] if i < len(parts) else v["text"])

    for c in "abcdefghijklmnopqrstuvwxyz":
        jobs[f"assets/audio/letters/{c}.m4a"] = ("en", f"{c.upper()}.")
    return jobs


def fingerprint(lang, text):
    rate, pitch = PROSODY[lang]
    raw = f"{VOICES[lang]}|{rate}|{pitch}|{text}"
    return hashlib.sha1(raw.encode("utf-8")).hexdigest()


async def synthesise(lang, text, out_mp3):
    for attempt in range(1, RETRIES + 1):
        try:
            rate, pitch = PROSODY[lang]
            await edge_tts.Communicate(
                text, VOICES[lang], rate=rate, pitch=pitch,
            ).save(str(out_mp3))
            if out_mp3.stat().st_size > 500:
                return
        except Exception as e:  # network drops are common here
            if attempt == RETRIES:
                raise
            print(f"  retry {attempt} ({type(e).__name__})", flush=True)
        await asyncio.sleep(min(2 ** attempt, 20))


def to_m4a(mp3, out):
    out.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run([
        "ffmpeg", "-y", "-loglevel", "error", "-i", str(mp3),
        "-af",
        "silenceremove=start_periods=1:start_threshold=-45dB,"
        "areverse,silenceremove=start_periods=1:start_threshold=-45dB,"
        "areverse,loudnorm=I=-16:TP=-1.5:LRA=11",
        "-ac", "1", "-ar", "44100", "-c:a", "aac", "-b:a", "64k", str(out),
    ], check=True)


async def main():
    jobs = collect()
    placeholders = set()
    if LIST_FILE.exists():
        placeholders = set(LIST_FILE.read_text(encoding="utf-8").split())
    manifest = {}
    if MANIFEST.exists():
        manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))

    todo = []
    for path, (lang, text) in sorted(jobs.items()):
        exists = (ROOT / path).exists()
        if exists and path not in placeholders:
            continue  # a real recording: never touch it
        if exists and manifest.get(path) == fingerprint(lang, text):
            continue  # already generated with this text and voice
        todo.append((path, lang, text))

    print(f"{len(todo)} clips to generate ({len(jobs)} total)", flush=True)
    done = 0
    sem = asyncio.Semaphore(WORKERS)

    def save_progress():
        MANIFEST.parent.mkdir(parents=True, exist_ok=True)
        MANIFEST.write_text(json.dumps(manifest, indent=1), "utf-8")
        LIST_FILE.write_text(
            "\n".join(sorted(placeholders)) + "\n", encoding="utf-8")

    async def one(tmp, i, path, lang, text):
        nonlocal done
        async with sem:
            mp3 = Path(tmp) / f"clip{i}.mp3"
            try:
                await synthesise(lang, text, mp3)
                await asyncio.to_thread(to_m4a, mp3, ROOT / path)
            except Exception as e:  # keep going; rerun picks it up
                print(f"  FAILED {path}: {type(e).__name__}", flush=True)
                return
            manifest[path] = fingerprint(lang, text)
            placeholders.add(path)
            done += 1
            if done % 20 == 0 or done == len(todo):
                save_progress()
                print(f"  {done}/{len(todo)}", flush=True)

    with tempfile.TemporaryDirectory(ignore_cleanup_errors=True) as tmp:
        await asyncio.gather(*[
            one(tmp, i, path, lang, text)
            for i, (path, lang, text) in enumerate(todo)
        ])

if __name__ == "__main__":
    asyncio.run(main())
