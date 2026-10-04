"""Builds real animal and bird sounds from Wikimedia Commons recordings.

Each recording below was chosen by hand (see tool/find_sounds.py) and is
public domain, CC0, CC BY or CC BY-SA, so it may be used in a commercial
app with credit. For each one this tool:

1. downloads the original (cached in tool/.cache/sounds),
2. finds the loudest stretch of [seconds] (the roar, not the silence),
3. cuts it with short fades, normalises loudness and saves a mono
   44.1 kHz .m4a at the item's `sound` path,
4. writes credits to assets/audio/ATTRIBUTION.md (shown in the app's
   licences page; CC BY / BY-SA require it). Our trimmed clips of CC BY-SA
   recordings are shared under the same licence.

    python tool/make_sounds.py
"""

import json
import re
import struct
import subprocess
import tempfile
import time
import urllib.parse
import urllib.request
import wave
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CONTENT = ROOT / "assets" / "content"
CACHE = ROOT / "tool" / ".cache" / "sounds"
CREDITS = ROOT / "assets" / "audio" / "ATTRIBUTION.md"
LIST_FILE = ROOT / "tool" / "placeholder_assets.txt"
API = "https://commons.wikimedia.org/w/api.php"
UA = "KidoraplayContentTool/1.0 (educational app)"

# id -> (Commons file title, seconds to keep)
SOUNDS = {
    "cow": ("File:Single Cow Moo.ogg", 3.0),
    "dog": ("File:Barking of a dog.ogg", 2.5),
    "cat": ("File:Meow of a Siamese cat - freemaster2.wav", 1.5),
    "lion": ("File:Lion raring-sound1TamilNadu178.ogg", 3.0),
    "tiger": ("File:439280 schots angry-tiger.wav", 3.0),
    "elephant": ("File:Elephant voice - trumpeting.ogg", 1.4),
    "monkey": ("File:Brown woolly monkey alarm call.wav", 3.0),
    "horse": ("File:Wiehern.ogg", 2.3),
    "goat": ("File:Herd of goats bleating.ogg", 3.0),
    "sheep": ("File:Sheep bleating.ogg", 3.0),
    "deer": ("File:Barking deer.ogg", 3.0),
    "bear": ("File:Bear growl.ogg", 3.0),
    "rabbit": ("File:Rabbit oinks and squeaks.wav", 2.5),
    "squirrel": ("File:Jungle palm squirrel.oga", 3.0),
    "crow": ("File:House crow, Corvus splendens.ogg", 3.0),
    "parrot": ("File:Rose-ringed parakeet call recorded in August 2013 at "
               "Haripur, Sangli.wav", 3.0),
    "peacock": ("File:Pavo cristatus (call).ogg", 3.0),
    "sparrow": ("File:House Sparrows chirping.ogg", 3.0),
    "pigeon": ("File:Dove cooing.ogg", 3.0),
    "duck": ("File:Anas platyrhynchos - Mallard - XC62258.ogg", 3.0),
    "hen": ("File:Hen announcing shes lain an egg.ogg", 3.0),
    "owl": ("File:Strix aluco male.oga", 3.0),
    "eagle": ("File:Crested Serpent Eagle from Dhoni.ogg", 3.0),
    "koel": ("File:KoelMale.ogg", 3.0),
    # camel: no suitable licensed recording found yet; keeps Kido's voice.
}


def api(params):
    url = API + "?" + urllib.parse.urlencode({**params, "format": "json"})
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    for attempt in range(8):
        try:
            with urllib.request.urlopen(req, timeout=60) as r:
                return json.load(r)
        except Exception:
            time.sleep(min(2 ** attempt, 30))
    raise RuntimeError(f"Commons API failed: {params}")


def download(url, path):
    # curl copes better with flaky connections (retries and resume).
    part = path.with_suffix(path.suffix + ".part")
    subprocess.run([
        "curl", "-sSL", "--retry", "10", "--retry-all-errors",
        "--retry-delay", "3", "--max-time", "240", "-C", "-", "-A", UA,
        "-o", str(part), url,
    ], check=True)
    part.replace(path)


def info(title):
    data = api({"action": "query", "titles": title, "prop": "imageinfo",
                "iiprop": "url|extmetadata"})
    page = next(iter(data["query"]["pages"].values()))
    ii = page["imageinfo"][0]
    meta = ii["extmetadata"]

    def text(key):
        raw = meta.get(key, {}).get("value", "")
        return re.sub(r"\s+", " ", re.sub("<[^>]+>", "", raw)).strip()

    return {
        "url": ii["url"],
        "page": ii["descriptionurl"],
        "licence": text("LicenseShortName"),
        "licence_url": meta.get("LicenseUrl", {}).get("value", ""),
        "artist": text("Artist") or "Unknown",
    }


def loudest_start(wav_path, seconds):
    """Start time (s) of the loudest [seconds]-long window."""
    with wave.open(str(wav_path)) as w:
        rate = w.getframerate()
        frames = w.readframes(w.getnframes())
    samples = struct.unpack(f"<{len(frames) // 2}h", frames)
    hop = rate // 20  # 50 ms blocks
    energy = [sum(s * s for s in samples[i:i + hop])
              for i in range(0, len(samples), hop)]
    win = max(1, int(seconds * 20))
    if len(energy) <= win:
        return 0.0
    best, best_i, current = -1, 0, sum(energy[:win])
    for i in range(len(energy) - win):
        if current > best:
            best, best_i = current, i
        current += energy[i + win] - energy[i]
    return best_i / 20


def build(item_id, sound_path, title, seconds):
    CACHE.mkdir(parents=True, exist_ok=True)
    meta = info(title)
    src = CACHE / re.sub(r"[^\w.-]", "_", title[5:])
    if not src.exists():
        download(meta["url"], src)
    with tempfile.TemporaryDirectory() as tmp:
        probe = Path(tmp) / "probe.wav"
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", str(src),
                        "-ac", "1", "-ar", "8000", str(probe)], check=True)
        start = loudest_start(probe, seconds)
    fade = min(0.15, seconds / 6)
    out = ROOT / sound_path
    out.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run([
        "ffmpeg", "-y", "-loglevel", "error", "-ss", f"{start:.2f}",
        "-t", f"{seconds:.2f}", "-i", str(src), "-af",
        f"afade=t=in:d={fade},afade=t=out:st={seconds - fade:.2f}:d={fade},"
        "loudnorm=I=-16:TP=-1.5:LRA=11",
        "-ac", "1", "-ar", "44100", "-c:a", "aac", "-b:a", "96k", str(out),
    ], check=True)
    print(f"{item_id:9} {meta['licence']:14} from {start:5.1f}s  {title[5:60]}")
    return {**meta, "id": item_id, "title": title[5:]}


def main():
    sounds = {}
    for name in ("items_animals.json", "items_birds.json"):
        for it in json.loads((CONTENT / name).read_text(encoding="utf-8")):
            sounds[it["id"]] = it["sound"]

    credits = [build(i, sounds[i], *SOUNDS[i]) for i in SOUNDS]

    lines = [
        "# Animal and bird sound credits",
        "",
        "Real recordings from Wikimedia Commons, trimmed and volume-",
        "normalised for Kidoraplay. Trimmed clips of CC BY-SA recordings are",
        "shared under the same licence.",
        "",
    ]
    for c in credits:
        lines.append(
            f"- **{c['id']}**: \"{c['title']}\" by {c['artist']}, "
            f"{c['licence']} ({c['licence_url'] or 'public domain'}), "
            f"{c['page']}")
    CREDITS.write_text("\n".join(lines) + "\n", encoding="utf-8")

    # Real recordings are no longer placeholders.
    if LIST_FILE.exists():
        done = {sounds[i] for i in SOUNDS}
        keep = [p for p in LIST_FILE.read_text("utf-8").split()
                if p not in done]
        LIST_FILE.write_text("\n".join(keep) + "\n", encoding="utf-8")
    print(f"wrote {len(credits)} sounds and {CREDITS.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
